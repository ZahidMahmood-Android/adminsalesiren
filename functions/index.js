const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const crypto = require('crypto');
const {
  getFirestore,
  FieldPath,
  FieldValue,
  Timestamp,
} = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { getStorage } = require('firebase-admin/storage');
const { onDocumentWritten, onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { setGlobalOptions } = require('firebase-functions/v2');
const { logger } = require('firebase-functions');

const {
  registerOfferDiscoveryFunctions,
} = require('./offer_discovery');

const PROJECT_ID =
  process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || 'salesiren-5539c';

// Gen 2 defaults to the Compute Engine SA, which cannot call FCM
// (cloudmessaging.messages.create). Use the App Engine / Firebase Admin SA.
const PUSH_RUNTIME_SERVICE_ACCOUNT =
  process.env.FIREBASE_FUNCTIONS_SERVICE_ACCOUNT ||
  `${PROJECT_ID}@appspot.gserviceaccount.com`;

setGlobalOptions({
  region: 'us-central1',
  serviceAccount: PUSH_RUNTIME_SERVICE_ACCOUNT,
});

/** CORS for admin-panel Flutter web (localhost + production hosts). */
const ADMIN_WEB_CALLABLE_CORS = [
  /^https?:\/\/localhost(?::\d+)?$/,
  /^https?:\/\/127\.0\.0\.1(?::\d+)?$/,
  /^https:\/\/salesiren\.bytecinch\.com$/,
  /^https:\/\/salesiren-5539c\.web\.app$/,
  /^https:\/\/salesiren-5539c\.firebaseapp\.com$/,
];

function adminCallableOptions() {
  return {
    region: 'us-central1',
    invoker: 'public',
    cors: ADMIN_WEB_CALLABLE_CORS,
  };
}

initializeApp();

const PRIVILEGED_ROLES = new Set([
  'owner',
  'admin',
  'brand_admin',
  'manager',
]);

const PUSH_DISPATCH_ROLES = new Set(['owner', 'admin', 'brand_admin', 'manager']);

/**
 * @param {import('firebase-admin/firestore').DocumentData | undefined} offer
 * @returns {string[]}
 */
function offerCategoryIds(offer) {
  if (!offer) {
    return [];
  }
  const ids = Array.isArray(offer.categoryIds)
    ? offer.categoryIds.filter((id) => typeof id === 'string' && id.trim())
    : [];
  if (ids.length > 0) {
    return [...new Set(ids)];
  }
  const single = offer.categoryId;
  return typeof single === 'string' && single.trim() ? [single.trim()] : [];
}

/**
 * @param {import('firebase-admin/firestore').DocumentData} offer
 * @param {string} lineId
 */
function findOfferLine(offer, lineId) {
  if (!lineId || !Array.isArray(offer.offerLines)) {
    return null;
  }
  return offer.offerLines.find((line) => line && line.id === lineId) || null;
}

/**
 * @param {import('firebase-admin/firestore').DocumentData} offer
 * @param {string} lineId
 */
function offerForLinePush(offer, lineId) {
  const line = findOfferLine(offer, lineId);
  if (!line) {
    return offer;
  }
  const categoryId =
    typeof line.categoryId === 'string' ? line.categoryId.trim() : '';
  return {
    ...offer,
    categoryId: categoryId || offer.categoryId,
    categoryName: line.categoryName || offer.categoryName,
    categoryIds: categoryId ? [categoryId] : offerCategoryIds(offer),
    discountText: line.discountText || offer.discountText,
    imageUrl: line.imageUrl || offer.imageUrl,
    imageUrls: Array.isArray(line.imageUrls) && line.imageUrls.length > 0
      ? line.imageUrls
      : offer.imageUrls,
  };
}

/**
 * @param {import('firebase-admin/firestore').DocumentData} offer
 */
function primaryOfferImageUrl(offer) {
  if (Array.isArray(offer.imageUrls)) {
    const image = offer.imageUrls.find((url) => typeof url === 'string' && url.trim());
    if (image) {
      return image.trim();
    }
  }
  return typeof offer.imageUrl === 'string' ? offer.imageUrl.trim() : '';
}

function requestImageUrl(request, offer, offerLineId = '') {
  const dataImage =
    request &&
    request.data &&
    typeof request.data.imageUrl === 'string'
      ? request.data.imageUrl.trim()
      : '';
  if (dataImage) {
    return dataImage;
  }
  const lineId =
    typeof offerLineId === 'string' && offerLineId.trim()
      ? offerLineId.trim()
      : request && typeof request.offerLineId === 'string'
        ? request.offerLineId.trim()
        : '';
  return primaryOfferImageUrl(offerForLinePush(offer, lineId));
}

function offerImagePaths(offerId, offer) {
  const paths = new Set();
  paths.add(`offers/${offerId}/`);
  const addUrl = (value) => {
    if (typeof value !== 'string' || !value.trim()) {
      return;
    }
    try {
      const url = new URL(value);
      const marker = '/o/';
      const markerIndex = url.pathname.indexOf(marker);
      if (markerIndex < 0) {
        return;
      }
      const encodedPath = url.pathname.slice(markerIndex + marker.length);
      const path = decodeURIComponent(encodedPath);
      if (path.startsWith(`offers/${offerId}/`)) {
        paths.add(path);
      }
    } catch (_) {
      // Ignore non-Firebase URLs.
    }
  };

  addUrl(offer.imageUrl);
  if (Array.isArray(offer.imageUrls)) {
    offer.imageUrls.forEach(addUrl);
  }
  if (Array.isArray(offer.offerLines)) {
    for (const line of offer.offerLines) {
      if (!line) {
        continue;
      }
      addUrl(line.imageUrl);
      if (Array.isArray(line.imageUrls)) {
        line.imageUrls.forEach(addUrl);
      }
    }
  }
  return [...paths];
}

/**
 * @param {import('firebase-admin/firestore').DocumentData | undefined} user
 * @returns {string[]}
 */
function userCategoryIds(user) {
  if (!user) {
    return [];
  }
  if (Array.isArray(user.selectedCategories)) {
    return [
      ...new Set(
        user.selectedCategories.filter(
          (id) => typeof id === 'string' && id.trim(),
        ),
      ),
    ];
  }
  return [];
}

/**
 * @param {import('firebase-admin/firestore').DocumentData | undefined} user
 * @returns {string[]}
 */
function readFcmTokens(user) {
  if (!user) {
    return [];
  }
  const tokens = [];
  if (Array.isArray(user.fcmTokens)) {
    for (const token of user.fcmTokens) {
      if (typeof token === 'string' && token.trim()) {
        tokens.push(token.trim());
      }
    }
  }
  if (typeof user.fcmToken === 'string' && user.fcmToken.trim()) {
    tokens.push(user.fcmToken.trim());
  }
  return [...new Set(tokens)];
}

/**
 * @param {import('firebase-admin/firestore').DocumentData | undefined} user
 * @returns {string[]}
 */
function resolveUserRoles(user) {
  if (!user) {
    return [];
  }
  if (Array.isArray(user.roles) && user.roles.length > 0) {
    return user.roles.filter((role) => typeof role === 'string' && role.trim());
  }
  if (typeof user.role === 'string' && user.role.trim()) {
    return [user.role.trim()];
  }
  return [];
}

/**
 * @param {import('firebase-admin/firestore').DocumentData | undefined} user
 */
function canDispatchOfferPush(user) {
  const roles = resolveUserRoles(user);
  return roles.some((role) => PUSH_DISPATCH_ROLES.has(role));
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} uid
 */
async function canCallerDispatchOfferPush(db, uid) {
  const userDoc = await db.collection('users').doc(uid).get();
  if (userDoc.exists && canDispatchOfferPush(userDoc.data())) {
    return true;
  }

  const adminDoc = await db.collection('admins').doc(uid).get();
  return adminDoc.exists && canDispatchOfferPush(adminDoc.data());
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} uid
 */
async function isCallerOwner(db, uid) {
  const userDoc = await db.collection('users').doc(uid).get();
  if (userDoc.exists) {
    const roles = resolveUserRoles(userDoc.data());
    if (roles.includes('owner')) {
      return true;
    }
  }

  const adminDoc = await db.collection('admins').doc(uid).get();
  return adminDoc.exists && adminDoc.data()?.role === 'owner';
}

/**
 * @param {string} email
 */
function normalizeRegistrationEmail(email) {
  return String(email || '').trim().toLowerCase();
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} email
 */
async function registrationEmailProfileExists(db, email) {
  const snapshot = await db
    .collection('users')
    .where('email', '==', email)
    .limit(1)
    .get();
  return !snapshot.empty;
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} uid
 */
async function assertCallerOwner(db, uid) {
  if (!(await isCallerOwner(db, uid))) {
    throw new HttpsError(
      'permission-denied',
      'Only owners can manage registration email verification.',
    );
  }
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} email
 * @returns {Promise<{uid: string, email: string, customToken?: string, alreadyVerified?: boolean}>}
 */
async function startRegistrationEmailVerificationCore(db, email) {
  const normalized = normalizeRegistrationEmail(email);
  if (!normalized || !normalized.includes('@')) {
    throw new HttpsError('invalid-argument', 'Enter a valid email address.');
  }

  if (await registrationEmailProfileExists(db, normalized)) {
    throw new HttpsError(
      'already-exists',
      'A user profile with this email already exists.',
    );
  }

  const auth = getAuth();
  let uid;

  try {
    const existing = await auth.getUserByEmail(normalized);
    if (existing.emailVerified) {
      return {
        uid: existing.uid,
        email: normalized,
        alreadyVerified: true,
      };
    }
    uid = existing.uid;
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    if (error.code !== 'auth/user-not-found') {
      throw error;
    }

    const password = crypto.randomBytes(24).toString('base64url');
    const created = await auth.createUser({
      email: normalized,
      password,
      emailVerified: false,
    });
    uid = created.uid;
  }

  const customToken = await auth.createCustomToken(uid);
  return { uid, customToken, email: normalized };
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} email
 */
async function checkRegistrationEmailStatusCore(db, email) {
  const normalized = normalizeRegistrationEmail(email);
  if (!normalized || !normalized.includes('@')) {
    throw new HttpsError('invalid-argument', 'Enter a valid email address.');
  }

  const hasProfile = await registrationEmailProfileExists(db, normalized);
  const auth = getAuth();

  try {
    const user = await auth.getUserByEmail(normalized);
    return {
      uid: user.uid,
      verified: user.emailVerified === true,
      hasProfile,
      canRegister: user.emailVerified === true && !hasProfile,
    };
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      return {
        uid: null,
        verified: false,
        hasProfile,
        canRegister: false,
      };
    }
    throw error;
  }
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} email
 */
async function cancelRegistrationEmailVerificationCore(db, email) {
  const normalized = normalizeRegistrationEmail(email);
  if (!normalized || !normalized.includes('@')) {
    throw new HttpsError('invalid-argument', 'Enter a valid email address.');
  }

  if (await registrationEmailProfileExists(db, normalized)) {
    return { cancelled: false, reason: 'profile_exists' };
  }

  const auth = getAuth();
  try {
    const user = await auth.getUserByEmail(normalized);
    if (user.emailVerified) {
      return { cancelled: false, reason: 'already_verified' };
    }
    await auth.deleteUser(user.uid);
    return { cancelled: true, uid: user.uid, email: normalized };
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      return { cancelled: true, reason: 'not_found' };
    }
    throw error;
  }
}

/**
 * @param {unknown} error
 */
function registrationJobErrorFields(error) {
  if (error instanceof HttpsError) {
    return { errorCode: error.code, errorMessage: error.message };
  }
  if (error && typeof error === 'object' && 'code' in error) {
    return {
      errorCode: String(error.code),
      errorMessage: String(error.message || 'Unknown error'),
    };
  }
  return {
    errorCode: 'internal',
    errorMessage: error instanceof Error ? error.message : 'Unknown error',
  };
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} jobId
 */
async function claimOfferPushJob(db, jobId) {
  const ref = db.collection('offer_push_jobs').doc(jobId);
  return db.runTransaction(async (transaction) => {
    const snap = await transaction.get(ref);
    if (!snap.exists) {
      return { claimed: false, reason: 'missing' };
    }
    const data = snap.data() || {};
    if (data.dispatchCompletedAt) {
      return { claimed: false, reason: 'already_dispatched' };
    }
    if (data.dispatchInProgress === true) {
      return { claimed: false, reason: 'in_progress' };
    }
    transaction.update(ref, {
      dispatchInProgress: true,
      dispatchStartedAt: FieldValue.serverTimestamp(),
    });
    return { claimed: true };
  });
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} jobId
 * @param {object} result
 */
async function completeOfferPushJob(db, jobId, result) {
  const update = {
    dispatchInProgress: false,
    dispatchCompletedAt: FieldValue.serverTimestamp(),
    sentCount: result.successCount,
    recipientCount: result.recipientCount,
    matchedUserCount:
      typeof result.matchedUserCount === 'number' ? result.matchedUserCount : 0,
    tokenCount: result.tokenCount,
    invalidTokenCount: result.invalidTokenCount,
    updatedAt: FieldValue.serverTimestamp(),
  };
  if (typeof result.dispatchReason === 'string' && result.dispatchReason.trim()) {
    update.dispatchReason = result.dispatchReason.trim();
  } else {
    update.dispatchReason = FieldValue.delete();
  }
  if (result.lastFcmError) {
    update.lastError = result.lastFcmError;
    update.lastFcmError = result.lastFcmError;
  } else if (result.lastError) {
    update.lastError = result.lastError;
    update.lastFcmError = FieldValue.delete();
  } else {
    update.lastError = FieldValue.delete();
    update.lastFcmError = FieldValue.delete();
  }
  await db.collection('offer_push_jobs').doc(jobId).update(update);
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} jobId
 * @param {string} errorMessage
 */
async function failOfferPushJob(db, jobId, errorMessage) {
  await db.collection('offer_push_jobs').doc(jobId).update({
    dispatchInProgress: false,
    dispatchCompletedAt: FieldValue.serverTimestamp(),
    lastError: errorMessage,
    updatedAt: FieldValue.serverTimestamp(),
  });
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} offerId
 * @param {import('firebase-admin/firestore').DocumentData} offer
 * @param {object} options
 */
async function runOfferPushDispatch(db, offerId, offer, options = {}) {
  const jobId = typeof options.jobId === 'string' ? options.jobId.trim() : '';
  if (jobId) {
    const claim = await claimOfferPushJob(db, jobId);
    if (!claim.claimed) {
      logger.info('Offer push dispatch skipped', { jobId, offerId, reason: claim.reason });
      return {
        skipped: true,
        reason: claim.reason,
        successCount: 0,
        recipientCount: 0,
        tokenCount: 0,
        invalidTokenCount: 0,
        requestId: options.requestId || null,
      };
    }
  }

  try {
    const result = await dispatchOfferPush(db, offerId, offer, options);
    if (jobId) {
      await completeOfferPushJob(db, jobId, result);
    }
    return result;
  } catch (error) {
    if (jobId) {
      await failOfferPushJob(
        db,
        jobId,
        error instanceof Error ? error.message : String(error),
      );
    }
    throw error;
  }
}

/**
 * @param {import('firebase-admin/firestore').DocumentData | undefined} user
 */
function isMobileRecipient(user) {
  if (!user) {
    return false;
  }
  if (user.notificationEnabled === false) {
    return false;
  }
  if (user.isActive === false) {
    return false;
  }
  const roles = resolveUserRoles(user);
  for (const role of roles) {
    if (PRIVILEGED_ROLES.has(role)) {
      return false;
    }
  }
  if (roles.length === 0) {
    return true;
  }
  return true;
}

/**
 * @param {string[]} userCategories
 * @param {string[]} offerCategories
 */
function categoriesMatch(userCategories, offerCategories) {
  if (offerCategories.length === 0) {
    return true;
  }
  const userSet = new Set(userCategories);
  return offerCategories.some((id) => userSet.has(id));
}

/**
 * @param {import('firebase-admin/firestore').DocumentData | undefined} user
 * @param {string} brandId
 * @param {string} brandName
 * @param {Set<string>} savedBrandUserIds
 */
function brandMatches(user, brandId, brandName, savedBrandUserIds) {
  if (!brandId && !brandName) {
    return true;
  }
  const uid = user?.id;
  if (uid && savedBrandUserIds.has(uid)) {
    return true;
  }
  return false;
}

/**
 * @param {unknown} value
 * @returns {string[]}
 */
function readStringList(value) {
  if (!Array.isArray(value)) {
    return [];
  }
  return value
    .filter((item) => typeof item === 'string' && item.trim())
    .map((item) => item.trim());
}

/**
 * User is notified when selected categories or followed-brand category preferences match.
 */
async function userBrandPreferredCategoryIds(db, userId, brandId) {
  if (!brandId) {
    return [];
  }
  try {
    const directDoc = await db
      .collection('users')
      .doc(userId)
      .collection('saved_brands')
      .doc(brandId)
      .get();
    if (directDoc.exists) {
      return readStringList(directDoc.data()?.preferredCategoryIds);
    }

    const byField = await db
      .collection('users')
      .doc(userId)
      .collection('saved_brands')
      .where('brandId', '==', brandId)
      .limit(1)
      .get();
    if (!byField.empty) {
      return readStringList(byField.docs[0].data()?.preferredCategoryIds);
    }
  } catch (error) {
    logger.warn('saved_brands preference read failed', { userId, brandId, error });
  }
  return [];
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} brandId
 */
async function brandCatalogCategoryIds(db, brandId) {
  if (!brandId) {
    return [];
  }
  try {
    const snapshot = await db.collection('brands').doc(brandId).get();
    if (!snapshot.exists) {
      return [];
    }
    return readStringList(snapshot.data()?.categoryIds);
  } catch (error) {
    logger.warn('brand catalog category read failed', { brandId, error });
    return [];
  }
}

/**
 * @param {string[]} offerCategories
 * @param {string[]} preferredCategories
 */
function offerMatchesBrandCategoryPreferences(offerCategories, preferredCategories) {
  if (!preferredCategories || preferredCategories.length === 0) {
    return true;
  }
  if (!offerCategories || offerCategories.length === 0) {
    return true;
  }
  return categoriesMatch(preferredCategories, offerCategories);
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} userId
 * @param {string[]} userCategories
 * @param {string[]} offerCategories
 * @param {string} brandId
 * @param {Set<string>} savedBrandUserIds
 */
async function userWantsOffer(
  db,
  userId,
  userCategories,
  offerCategories,
  brandId,
  savedBrandUserIds,
) {
  if (categoriesMatch(userCategories, offerCategories)) {
    return true;
  }
  if (!savedBrandUserIds.has(userId)) {
    return false;
  }

  let preferred = await userBrandPreferredCategoryIds(db, userId, brandId);
  if (preferred.length === 0) {
    preferred = await brandCatalogCategoryIds(db, brandId);
  }
  return offerMatchesBrandCategoryPreferences(offerCategories, preferred);
}

/**
 * @param {string[]} values
 * @param {number} size
 */
function chunk(values, size) {
  const parts = [];
  for (let i = 0; i < values.length; i += size) {
    parts.push(values.slice(i, i + size));
  }
  return parts;
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} userId
 * @param {import('firebase-admin/firestore').DocumentData | undefined} user
 */
async function userCategoryIdsForUser(db, userId, user) {
  const fromDoc = userCategoryIds(user);
  try {
    const sub = await db
      .collection('users')
      .doc(userId)
      .collection('selected_categories')
      .get();
    const fromSub = sub.docs
      .map((doc) => {
        const data = doc.data() || {};
        const id = data.categoryId;
        return typeof id === 'string' && id.trim() ? id.trim() : doc.id;
      })
      .filter((id) => id);
    return [...new Set([...fromDoc, ...fromSub])];
  } catch (error) {
    logger.warn('selected_categories read failed', { userId, error });
    return fromDoc;
  }
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} offerId
 * @param {import('firebase-admin/firestore').DocumentData} offer
 */
async function collectCandidateUserIds(db, offer) {
  const ids = new Set();
  const brandId = typeof offer.brandId === 'string' ? offer.brandId.trim() : '';
  const brandName =
    typeof offer.brandName === 'string' ? offer.brandName.trim() : '';
  const categoryIds = offerCategoryIds(offer);

  for (const categoryChunk of chunk(categoryIds, 10)) {
    if (categoryChunk.length === 0) {
      continue;
    }
    try {
      const bySelectedSub = await db
        .collectionGroup('selected_categories')
        .where('categoryId', 'in', categoryChunk)
        .get();
      for (const doc of bySelectedSub.docs) {
        const userRef = doc.ref.parent.parent;
        if (userRef) {
          ids.add(userRef.id);
        }
      }
    } catch (error) {
      logger.warn('selected_categories collection group query failed', error);
    }
  }

  const savedBrandUserIds = new Set();
  if (brandId) {
    try {
      const savedByBrandId = await db
        .collectionGroup('saved_brands')
        .where('brandId', '==', brandId)
        .get();
      for (const doc of savedByBrandId.docs) {
        const userRef = doc.ref.parent.parent;
        if (userRef) {
          ids.add(userRef.id);
          savedBrandUserIds.add(userRef.id);
        }
      }
    } catch (error) {
      logger.warn('saved_brands brandId collection group query failed', error);
    }
  }
  if (brandName) {
    try {
      const savedBrands = await db
        .collectionGroup('saved_brands')
        .where('brandName', '==', brandName)
        .get();
      for (const doc of savedBrands.docs) {
        const userRef = doc.ref.parent.parent;
        if (userRef) {
          ids.add(userRef.id);
          savedBrandUserIds.add(userRef.id);
        }
      }
    } catch (error) {
      logger.warn('saved_brands collection group query failed', error);
    }
  }

  return { ids, savedBrandUserIds, brandId, brandName, categoryIds };
}

/**
 * @param {FirebaseFirestore.Firestore} db
 */
async function fallbackMobileUserIds(db) {
  const ids = new Set();
  try {
    const snapshot = await db
      .collection('users')
      .where('role', '==', 'mobile_user')
      .limit(300)
      .get();
    for (const doc of snapshot.docs) {
      ids.add(doc.id);
    }
  } catch (error) {
    logger.warn('fallback mobile_user query failed', error);
  }
  return ids;
}

/**
 * @param {FirebaseFirestore.Firestore} db
 */
async function resolveAllMobileRecipients(db) {
  const recipients = [];
  const seenUserIds = new Set();

  const addFromSnapshot = (snapshot) => {
    for (const doc of snapshot.docs) {
      if (seenUserIds.has(doc.id)) {
        continue;
      }
      seenUserIds.add(doc.id);
      const data = doc.data() || {};
      data.id = doc.id;
      if (!isMobileRecipient(data)) {
        continue;
      }
      const tokens = readFcmTokens(data);
      if (tokens.length === 0) {
        continue;
      }
      recipients.push({ userId: doc.id, tokens, data });
    }
  };

  let lastDoc = null;
  while (true) {
    let query = db
      .collection('users')
      .where('role', '==', 'mobile_user')
      .limit(500);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }
    const snapshot = await query.get();
    addFromSnapshot(snapshot);
    if (snapshot.empty || snapshot.size < 500) {
      break;
    }
    lastDoc = snapshot.docs[snapshot.size - 1];
  }

  try {
    const byRoles = await db
      .collection('users')
      .where('roles', 'array-contains', 'mobile_user')
      .limit(500)
      .get();
    addFromSnapshot(byRoles);
  } catch (error) {
    logger.warn('roles mobile_user query failed', error);
  }

  await addTokenBearingMobileRecipients(db, recipients, seenUserIds);

  return recipients;
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {Array<{ userId: string, tokens: string[], data: import('firebase-admin/firestore').DocumentData }>} recipients
 * @param {Set<string>} seenUserIds
 */
async function addTokenBearingMobileRecipients(db, recipients, seenUserIds) {
  let lastDoc = null;
  while (true) {
    let query = db
      .collection('users')
      .orderBy(FieldPath.documentId())
      .limit(500);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }
    const snapshot = await query.get();
    for (const doc of snapshot.docs) {
      if (seenUserIds.has(doc.id)) {
        continue;
      }
      const data = doc.data() || {};
      data.id = doc.id;
      if (!isMobileRecipient(data)) {
        continue;
      }
      const tokens = readFcmTokens(data);
      if (tokens.length === 0) {
        continue;
      }
      seenUserIds.add(doc.id);
      recipients.push({ userId: doc.id, tokens, data });
    }
    if (snapshot.empty || snapshot.size < 500) {
      break;
    }
    lastDoc = snapshot.docs[snapshot.size - 1];
  }
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} offerId
 * @param {import('firebase-admin/firestore').DocumentData} offer
 */
async function resolveRecipients(db, offerId, offer) {
  const { ids, savedBrandUserIds, brandId, brandName, categoryIds } =
    await collectCandidateUserIds(db, offer);

  const recipients = [];
  let matchedUserCount = 0;
  let usersWithoutTokensCount = 0;
  for (const userId of ids) {
    const snapshot = await db.collection('users').doc(userId).get();
    if (!snapshot.exists) {
      continue;
    }
    const data = snapshot.data() || {};
    data.id = userId;
    if (!isMobileRecipient(data)) {
      continue;
    }
    const userCategories = await userCategoryIdsForUser(db, userId, data);
    if (
      !(await userWantsOffer(
        db,
        userId,
        userCategories,
        categoryIds,
        brandId,
        savedBrandUserIds,
      ))
    ) {
      continue;
    }
    matchedUserCount++;
    const tokens = readFcmTokens(data);
    if (tokens.length === 0) {
      usersWithoutTokensCount++;
      continue;
    }
    recipients.push({ userId, tokens, data });
  }

  return {
    recipients,
    matchedUserCount,
    usersWithoutTokensCount,
    categoryIds,
    brandId,
    brandName,
  };
}

/**
 * @param {object} params
 * @param {string[]} params.categoryIds
 * @param {string} params.brandId
 * @param {string} params.brandName
 */
function buildNoMatchingAudienceMessage({ categoryIds, brandId, brandName }) {
  const hasCategories = Array.isArray(categoryIds) && categoryIds.length > 0;
  const brandLabel =
    typeof brandName === 'string' && brandName.trim()
      ? brandName.trim()
      : typeof brandId === 'string' && brandId.trim()
        ? brandId.trim()
        : '';

  if (hasCategories && brandLabel) {
    return (
      'No notification was sent because no mobile users follow ' +
      `${brandLabel} or have selected the offer categories. ` +
      'Users must choose matching categories or save the brand in the app first.'
    );
  }
  if (hasCategories) {
    return (
      'No notification was sent because no mobile users have selected the offer categories. ' +
      'Users must pick matching categories in the app before they can receive this alert.'
    );
  }
  if (brandLabel) {
    return (
      `No notification was sent because no mobile users follow ${brandLabel}. ` +
      'Users must save the brand in the app before they can receive this alert.'
    );
  }
  return 'No notification was sent because no mobile users match this offer.';
}

function buildNoFcmTokensMessage(matchedUserCount) {
  if (matchedUserCount === 1) {
    return (
      'One mobile user matches this category or brand, but they do not have a ' +
      'notification token yet. Ask them to sign in on the mobile app, turn ' +
      'notifications on, and open the app once before you resend.'
    );
  }
  if (matchedUserCount > 1) {
    return (
      `${matchedUserCount} mobile users match this category or brand, but none have a ` +
      'notification token yet. Ask them to sign in on the mobile app, turn ' +
      'notifications on, and open the app once before you resend.'
    );
  }
  return (
    'No mobile users have a notification token yet. Ask users to sign in on ' +
    'the mobile app, turn notifications on, and open the app once before you resend.'
  );
}

/**
 * @param {object} resolution
 * @param {number} resolution.matchedUserCount
 * @param {string[]} resolution.categoryIds
 * @param {string} resolution.brandId
 * @param {string} resolution.brandName
 */
function resolveEmptyPushOutcome(resolution) {
  const matchedUserCount =
    typeof resolution.matchedUserCount === 'number'
      ? resolution.matchedUserCount
      : 0;
  if (matchedUserCount === 0) {
    return {
      dispatchReason: 'no_matching_audience',
      lastError: buildNoMatchingAudienceMessage(resolution),
      matchedUserCount: 0,
    };
  }
  return {
    dispatchReason: 'no_fcm_tokens',
    lastError: buildNoFcmTokensMessage(matchedUserCount),
    matchedUserCount,
  };
}

/**
 * @param {import('firebase-admin/firestore').DocumentData} request
 */
function requestAlertType(request) {
  const data = request.data || {};
  const fromData =
    typeof data.type === 'string' && data.type.trim()
      ? data.type.trim()
      : typeof data.alertType === 'string' && data.alertType.trim()
        ? data.alertType.trim()
        : '';
  if (fromData) {
    return fromData;
  }
  return typeof request.type === 'string' && request.type.trim()
    ? request.type.trim()
    : 'new_offer';
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} offerId
 * @param {import('firebase-admin/firestore').DocumentData} offer
 */
async function resolveNotificationContent(
  db,
  offerId,
  offer,
  requestId = null,
  offerLineId = '',
) {
  const lineId =
    typeof offerLineId === 'string' && offerLineId.trim() ? offerLineId.trim() : '';

  if (requestId) {
    const requestDoc = await db
      .collection('notification_requests')
      .doc(requestId)
      .get();
    if (requestDoc.exists) {
      const request = requestDoc.data() || {};
      const resolvedLineId =
        lineId ||
        (typeof request.offerLineId === 'string' ? request.offerLineId.trim() : '');
      return {
        title:
          typeof request.title === 'string' && request.title.trim()
            ? request.title.trim()
            : 'New offer available',
        body:
          typeof request.body === 'string' && request.body.trim()
            ? request.body.trim()
            : defaultBody(offer),
        requestId: requestDoc.id,
        includeImage: request.includeImage !== false,
        imageUrl: request.includeImage === false
          ? ''
          : requestImageUrl(request, offer, resolvedLineId),
        type: requestAlertType(request),
      };
    }
  }

  const requests = await db
    .collection('notification_requests')
    .where('offerId', '==', offerId)
    .get();

  if (!requests.empty) {
    const sorted = [...requests.docs].sort((a, b) => {
      const aTime = a.data().createdAt?.toMillis?.() || 0;
      const bTime = b.data().createdAt?.toMillis?.() || 0;
      return bTime - aTime;
    });
    const doc = sorted[0];
    const request = doc.data();
    const resolvedLineId =
      lineId ||
      (typeof request.offerLineId === 'string' ? request.offerLineId.trim() : '');
    return {
      title:
        typeof request.title === 'string' && request.title.trim()
          ? request.title.trim()
          : 'New offer available',
      body:
        typeof request.body === 'string' && request.body.trim()
          ? request.body.trim()
          : defaultBody(offer),
      requestId: doc.id,
      includeImage: request.includeImage !== false,
      imageUrl: request.includeImage === false
        ? ''
        : requestImageUrl(request, offer, resolvedLineId),
      type: requestAlertType(request),
    };
  }

  return {
    title: 'New offer available',
    body: defaultBody(offer),
    requestId: null,
    includeImage: true,
    imageUrl: primaryOfferImageUrl(offerForLinePush(offer, lineId)),
    type: 'new_offer',
  };
}

/**
 * @param {import('firebase-admin/firestore').DocumentData} offer
 */
function defaultBody(offer) {
  const brandName =
    typeof offer.brandName === 'string' ? offer.brandName.trim() : 'Brand';
  const discount =
    typeof offer.discountText === 'string' ? offer.discountText.trim() : '';
  return discount ? `${brandName}: ${discount}` : `${brandName} posted a new offer`;
}

/**
 * @param {string} code
 */
function shouldRemoveFcmToken(code) {
  return (
    code === 'messaging/invalid-registration-token' ||
    code === 'messaging/registration-token-not-registered' ||
    code === 'messaging/sender-id-mismatch'
  );
}

/**
 * @param {string} token
 */
function maskFcmToken(token) {
  if (typeof token !== 'string') {
    return '';
  }
  const trimmed = token.trim();
  if (trimmed.length <= 16) {
    return trimmed;
  }
  return `${trimmed.slice(0, 8)}…${trimmed.slice(-6)}`;
}

/**
 * @param {Array<{ userId: string, tokens: string[], data: import('firebase-admin/firestore').DocumentData }>} recipients
 */
function logPushRecipients(recipients) {
  logger.info(`Push recipient preview: ${recipients.length} user(s) with FCM tokens`);
  for (const recipient of recipients) {
    const data = recipient.data || {};
    logger.info('Push recipient', {
      userId: recipient.userId,
      email: data.email || '',
      displayName: data.displayName || data.fullName || '',
      notificationEnabled: data.notificationEnabled !== false,
      tokenCount: recipient.tokens.length,
      tokens: recipient.tokens.map(maskFcmToken),
    });
  }
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string[]} invalidTokens
 */
async function removeInvalidTokens(db, recipients, invalidTokens) {
  if (invalidTokens.length === 0) {
    return;
  }
  const invalidSet = new Set(invalidTokens);
  for (const recipient of recipients) {
    const toRemove = recipient.tokens.filter((token) => invalidSet.has(token));
    if (toRemove.length === 0) {
      continue;
    }
    await db.collection('users').doc(recipient.userId).update({
      fcmTokens: FieldValue.arrayRemove(...toRemove),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
}

async function deleteQueryBatch(db, query) {
  const snapshot = await query.get();
  if (snapshot.empty) {
    return 0;
  }
  const batch = db.batch();
  for (const doc of snapshot.docs) {
    batch.delete(doc.ref);
  }
  await batch.commit();
  return snapshot.docs.length;
}

async function deleteOfferImages(offerId, offer) {
  const bucket = getStorage().bucket();
  for (const path of offerImagePaths(offerId, offer)) {
    if (path.endsWith('/')) {
      await bucket.deleteFiles({ prefix: path, force: true });
    } else {
      await bucket.file(path).delete({ ignoreNotFound: true });
    }
  }
}

async function deleteUserAlertsForOffer(db, offerId) {
  if (!offerId) {
    return 0;
  }

  let total = 0;
  for (;;) {
    const snapshot = await db
      .collectionGroup('alerts')
      .where('offerId', '==', offerId)
      .limit(500)
      .get();
    if (snapshot.empty) {
      break;
    }

    const batch = db.batch();
    for (const doc of snapshot.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    total += snapshot.docs.length;

    if (snapshot.docs.length < 500) {
      break;
    }
  }

  return total;
}

async function cleanupOfferNotificationArtifacts(db, offerId) {
  const notificationCount = await deleteQueryBatch(
    db,
    db.collection('notification_requests').where('offerId', '==', offerId),
  );
  const pushJobCount = await deleteQueryBatch(
    db,
    db.collection('offer_push_jobs').where('offerId', '==', offerId),
  );
  const alertCount = await deleteUserAlertsForOffer(db, offerId);
  return { notificationCount, pushJobCount, alertCount };
}

async function deleteExpiredOffer(db, offerDoc) {
  const offerId = offerDoc.id;
  const offer = offerDoc.data() || {};
  await deleteOfferImages(offerId, offer);
  const { notificationCount, pushJobCount, alertCount } =
    await cleanupOfferNotificationArtifacts(db, offerId);
  await offerDoc.ref.delete();
  logger.info('Expired offer cleanup deleted offer', {
    offerId,
    notificationCount,
    pushJobCount,
    alertCount,
  });
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string | null} requestId
 * @param {number} sentCount
 * @param {number} recipientCount
 */
async function markNotificationSent(
  db,
  offerId,
  requestId,
  sentCount,
  recipientCount,
) {
  const payload = {
    status: 'sent',
    sentAt: Timestamp.now(),
    sentCount,
    recipientCount,
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (requestId) {
    await db.collection('notification_requests').doc(requestId).update(payload);
    return;
  }

  const requests = await db
    .collection('notification_requests')
    .where('offerId', '==', offerId)
    .get();
  for (const doc of requests.docs) {
    const status = doc.data().status;
    if (status === 'pending' || status === 'approved') {
      await doc.ref.update(payload);
    }
  }
}

/**
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} offerId
 * @param {import('firebase-admin/firestore').DocumentData} offer
 */
async function persistUserAlertsForRecipients(
  db,
  recipients,
  {
    offerId,
    alertType,
    title,
    body,
    brandId,
    brandName,
    categoryIds = [],
  },
) {
  if (!offerId || !Array.isArray(recipients) || recipients.length === 0) {
    return;
  }

  const safeType =
    typeof alertType === 'string' && alertType.trim()
      ? alertType.trim()
      : 'new_offer';
  const alertId = `offer_${offerId}`
    .replace(/\//g, '_')
    .replace(/\n/g, '_')
    .trim()
    .slice(0, 1500);
  const now = Timestamp.now();
  const expiresAt = Timestamp.fromDate(
    new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
  );

  for (const recipientChunk of chunk(recipients, 400)) {
    const batch = db.batch();
    for (const recipient of recipientChunk) {
      const userId =
        typeof recipient.userId === 'string' ? recipient.userId.trim() : '';
      if (!userId) {
        continue;
      }
      const ref = db
        .collection('users')
        .doc(userId)
        .collection('alerts')
        .doc(alertId);
      batch.set(
        ref,
        {
          id: alertId,
          type: safeType,
          alertType: safeType,
          title: typeof title === 'string' ? title : '',
          body: typeof body === 'string' ? body : '',
          offerId,
          brandId: typeof brandId === 'string' ? brandId : '',
          brandName: typeof brandName === 'string' ? brandName : '',
          categoryIds: Array.isArray(categoryIds)
            ? categoryIds.filter((id) => typeof id === 'string' && id.trim())
            : [],
          read: false,
          createdAt: now,
          expiresAt,
        },
        { merge: true },
      );
    }
    await batch.commit();
  }
}

async function dispatchOfferPush(db, offerId, offer, options = {}) {
  const lineId =
    typeof options.offerLineId === 'string' ? options.offerLineId.trim() : '';
  const requestId =
    typeof options.requestId === 'string' ? options.requestId.trim() : null;
  const broadcastAll = options.broadcastAll === true;
  const pushOffer = offerForLinePush(offer, lineId);

  logger.info('dispatchOfferPush started', {
    offerId,
    offerLineId: lineId,
    requestId,
    broadcastAll,
    isPublished: offer.isPublished === true,
  });

  const recipientResolution = broadcastAll
    ? {
        recipients: await resolveAllMobileRecipients(db),
        matchedUserCount: 0,
        usersWithoutTokensCount: 0,
        categoryIds: offerCategoryIds(pushOffer),
        brandId: typeof pushOffer.brandId === 'string' ? pushOffer.brandId.trim() : '',
        brandName:
          typeof pushOffer.brandName === 'string' ? pushOffer.brandName.trim() : '',
      }
    : await resolveRecipients(db, offerId, pushOffer);
  const recipients = recipientResolution.recipients;
  logPushRecipients(recipients);
  const allTokens = [
    ...new Set(recipients.flatMap((recipient) => recipient.tokens)),
  ];

  const content = await resolveNotificationContent(
    db,
    offerId,
    offer,
    requestId,
    lineId,
  );
  const resolvedRequestId = requestId || content.requestId;

  if (allTokens.length === 0) {
    const emptyOutcome = broadcastAll
      ? {
          dispatchReason: 'no_fcm_tokens',
          lastError: buildNoFcmTokensMessage(0),
          matchedUserCount: 0,
        }
      : resolveEmptyPushOutcome(recipientResolution);
    logger.warn('No push recipients for published offer', {
      offerId,
      offerLineId: lineId,
      requestId: resolvedRequestId,
      broadcastAll,
      dispatchReason: emptyOutcome.dispatchReason,
      matchedUserCount: emptyOutcome.matchedUserCount,
    });
    await markNotificationSent(db, offerId, resolvedRequestId, 0, 0);
    return {
      skipped: false,
      successCount: 0,
      recipientCount: 0,
      matchedUserCount: emptyOutcome.matchedUserCount,
      tokenCount: 0,
      invalidTokenCount: 0,
      dispatchReason: emptyOutcome.dispatchReason,
      lastError: emptyOutcome.lastError,
      requestId: resolvedRequestId,
    };
  }

  const categoryIds = offerCategoryIds(pushOffer);
  const messaging = getMessaging();
  const invalidTokens = [];
  let successCount = 0;
  let lastFcmError = null;
  const imageUrl =
    content.includeImage !== false &&
    typeof content.imageUrl === 'string' &&
    content.imageUrl.trim()
      ? content.imageUrl.trim()
      : '';

  const useDataOnlyPayload = Boolean(imageUrl);

  logger.info('Sending FCM multicast', {
    offerId,
    requestId: resolvedRequestId,
    title: content.title,
    body: content.body,
    imageUrl: imageUrl || null,
    useDataOnlyPayload,
    tokenCount: allTokens.length,
    userCount: recipients.length,
  });

  const alertType =
    typeof content.type === 'string' && content.type.trim()
      ? content.type.trim()
      : 'new_offer';

  for (const tokenChunk of chunk(allTokens, 500)) {
    const response = await messaging.sendEachForMulticast({
      tokens: tokenChunk,
      ...(useDataOnlyPayload
        ? {}
        : {
            notification: {
              title: content.title,
              body: content.body,
            },
          }),
      data: {
        alertType,
        alert_type: alertType,
        sale_alert_type: alertType,
        type: alertType,
        offerId,
        title: content.title,
        body: content.body,
        imageUrl,
        includeImage: imageUrl ? 'true' : 'false',
        brandId: offer.brandId || '',
        categoryId: pushOffer.categoryId || '',
        categoryIds: categoryIds.join(','),
        offerLineId: lineId,
      },
      android: {
        priority: 'high',
        ...(useDataOnlyPayload
          ? {}
          : {
              notification: {
                channelId: 'sale_alerts',
                priority: 'high',
              },
            }),
      },
      apns: {
        headers: {
          'apns-priority': '10',
          ...(imageUrl ? { 'apns-push-type': 'alert' } : {}),
        },
        payload: {
          aps: {
            alert: {
              title: content.title,
              body: content.body,
            },
            sound: 'default',
            ...(imageUrl ? { 'mutable-content': 1 } : {}),
          },
        },
        ...(imageUrl ? { fcmOptions: { imageUrl } } : {}),
      },
    });
    successCount += response.successCount;
    response.responses.forEach((item, index) => {
      if (item.success) {
        return;
      }
      const code = item.error?.code || 'messaging/unknown';
      const message = item.error?.message || '';
      if (!lastFcmError) {
        lastFcmError = `${code}: ${message}`;
      }
      logger.warn('FCM send failed', {
        offerId,
        token: maskFcmToken(tokenChunk[index]),
        errorCode: code,
        errorMessage: message,
      });
      if (shouldRemoveFcmToken(code)) {
        logger.warn('FCM token send failed (token kept in Firestore)', {
          offerId,
          token: maskFcmToken(tokenChunk[index]),
          errorCode: code,
          errorMessage: message,
        });
      }
    });
  }

  if (successCount > 0) {
    await persistUserAlertsForRecipients(db, recipients, {
      offerId,
      alertType,
      title: content.title,
      body: content.body,
      brandId: offer.brandId || '',
      brandName: offer.brandName || '',
      categoryIds,
    });
    await db.collection('offers').doc(offerId).set(
      {
        alertType,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  // Tokens are only removed on explicit mobile sign out — never pruned here.
  await markNotificationSent(
    db,
    offerId,
    resolvedRequestId,
    successCount,
    recipients.length,
  );

  logger.info('dispatchOfferPush finished', {
    offerId,
    requestId: resolvedRequestId,
    successCount,
    tokenCount: allTokens.length,
    userCount: recipients.length,
    invalidTokenCount: invalidTokens.length,
    lastFcmError: lastFcmError || '',
  });

  return {
    skipped: false,
    successCount,
    recipientCount: recipients.length,
    matchedUserCount: broadcastAll
      ? recipients.length
      : recipientResolution.matchedUserCount,
    tokenCount: allTokens.length,
    invalidTokenCount: invalidTokens.length,
    requestId: resolvedRequestId,
    lastFcmError,
  };
}

exports.dispatchOfferPushOnPublish = onDocumentWritten(
  'offers/{offerId}',
  async () => {
    // Push dispatch is handled by offer_push_jobs (dispatchOfferPushOnJob).
  },
);

exports.onOfferExpiredNotificationCleanup = onDocumentWritten(
  'offers/{offerId}',
  async (event) => {
    const after = event.data?.after?.data();
    if (!after) {
      return;
    }

    const before = event.data?.before?.data();
    const offerId = event.params.offerId;
    const wasExpired = before?.status === 'expired';
    const isExpired = after.status === 'expired';
    if (!isExpired || wasExpired) {
      return;
    }

    const db = getFirestore();
    const { notificationCount, pushJobCount, alertCount } =
      await cleanupOfferNotificationArtifacts(db, offerId);
    logger.info('Removed notification artifacts for expired offer', {
      offerId,
      notificationCount,
      pushJobCount,
      alertCount,
    });
  },
);

exports.cleanupExpiredOffers = onSchedule(
  {
    schedule: 'every day 03:30',
    timeZone: 'Asia/Karachi',
  },
  async () => {
    const db = getFirestore();
    const cutoff = Timestamp.fromDate(
      new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
    );
    const docs = new Map();
    const expiredStatus = await db
      .collection('offers')
      .where('status', '==', 'expired')
      .limit(200)
      .get();
    for (const doc of expiredStatus.docs) {
      const updatedAt = doc.data().updatedAt;
      if (!updatedAt || updatedAt.toMillis?.() <= cutoff.toMillis()) {
        docs.set(doc.id, doc);
      }
    }

    const expiredByDate = await db
      .collection('offers')
      .where('endDate', '<=', cutoff)
      .limit(200)
      .get();
    for (const doc of expiredByDate.docs) {
      docs.set(doc.id, doc);
    }

    logger.info('Expired offer cleanup started', {
      cutoff: cutoff.toDate().toISOString(),
      offerCount: docs.size,
    });
    for (const doc of docs.values()) {
      await deleteExpiredOffer(db, doc);
    }
    logger.info('Expired offer cleanup finished', { offerCount: docs.size });
  },
);

exports.dispatchOfferPushOnJob = onDocumentWritten(
  'offer_push_jobs/{jobId}',
  async (event) => {
    const after = event.data?.after?.data();
    if (!after) {
      return;
    }

    const jobId = event.params.jobId;
    const offerId =
      typeof after.offerId === 'string' && after.offerId.trim()
        ? after.offerId.trim()
        : jobId;
    const offerLineId =
      typeof after.offerLineId === 'string' ? after.offerLineId.trim() : '';
    const requestId =
      typeof after.requestId === 'string' ? after.requestId.trim() : null;

    logger.info('offer_push_jobs trigger', {
      jobId,
      offerId,
      offerLineId,
      requestId,
      requestedByUserId: after.requestedByUserId || '',
    });

    const db = getFirestore();
    const offerSnap = await db.collection('offers').doc(offerId).get();
    if (!offerSnap.exists) {
      logger.warn('Offer push job skipped; offer missing', { jobId, offerId });
      await failOfferPushJob(db, jobId, `Offer ${offerId} not found.`);
      return;
    }

    const offer = offerSnap.data() || {};
    if (offer.isPublished !== true) {
      logger.warn('Offer push job skipped; offer not published', {
        jobId,
        offerId,
        status: offer.status || '',
        isPublished: offer.isPublished === true,
      });
      await failOfferPushJob(
        db,
        jobId,
        `Offer ${offerId} is not published. status=${offer.status || ''}`,
      );
      return;
    }

    try {
      const result = await runOfferPushDispatch(db, offerId, offer, {
        offerLineId,
        requestId,
        broadcastAll: false,
        jobId,
      });
      logger.info('offer_push_jobs dispatch result', {
        jobId,
        offerId,
        ...result,
      });
    } catch (error) {
      logger.error('Failed to dispatch offer push job', {
        jobId,
        offerId,
        error,
      });
      throw error;
    }
  },
);

exports.sendOfferPush = onCall(
  adminCallableOptions(),
  async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }

  const data = request.data || {};
  const offerId = typeof data.offerId === 'string' ? data.offerId.trim() : '';
  const offerLineId =
    typeof data.offerLineId === 'string' ? data.offerLineId.trim() : '';
  const requestId = typeof data.requestId === 'string' ? data.requestId.trim() : '';
  const jobId = typeof data.jobId === 'string' ? data.jobId.trim() : '';

  if (!offerId) {
    throw new HttpsError('invalid-argument', 'offerId is required.');
  }

  const db = getFirestore();
  if (!(await canCallerDispatchOfferPush(db, request.auth.uid))) {
    throw new HttpsError('permission-denied', 'Not allowed to send offer push.');
  }

  const offerSnap = await db.collection('offers').doc(offerId).get();
  if (!offerSnap.exists) {
    throw new HttpsError('not-found', `Offer ${offerId} not found.`);
  }

  const offer = offerSnap.data() || {};
  if (offer.isPublished !== true) {
    throw new HttpsError('failed-precondition', 'Offer is not published.');
  }

  logger.info('sendOfferPush callable', {
    offerId,
    offerLineId,
    requestId,
    jobId,
    callerUid: request.auth.uid,
  });

  const result = await runOfferPushDispatch(db, offerId, offer, {
    offerLineId,
    requestId: requestId || null,
    broadcastAll: false,
    jobId: jobId || null,
  });

  return {
    skipped: result.skipped === true,
    reason: result.lastFcmError || result.reason || null,
    requestId: result.requestId || null,
    successCount: String(result.successCount || 0),
    recipientCount: String(result.recipientCount || 0),
    tokenCount: String(result.tokenCount || 0),
    invalidTokenCount: String(result.invalidTokenCount || 0),
  };
});

exports.adminStartRegistrationEmailVerification = onCall(
  adminCallableOptions(),
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Sign in required.');
    }

    const db = getFirestore();
    await assertCallerOwner(db, request.auth.uid);

    const result = await startRegistrationEmailVerificationCore(
      db,
      request.data?.email,
    );
    logger.info('adminStartRegistrationEmailVerification', {
      email: result.email,
      uid: result.uid,
      callerUid: request.auth.uid,
    });

    return { uid: result.uid, customToken: result.customToken ?? '', alreadyVerified: result.alreadyVerified === true };
  },
);

exports.adminCheckRegistrationEmailStatus = onCall(
  adminCallableOptions(),
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Sign in required.');
    }

    const db = getFirestore();
    await assertCallerOwner(db, request.auth.uid);

    return checkRegistrationEmailStatusCore(db, request.data?.email);
  },
);

exports.adminCancelRegistrationEmailVerification = onCall(
  adminCallableOptions(),
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Sign in required.');
    }

    const db = getFirestore();
    await assertCallerOwner(db, request.auth.uid);

    const result = await cancelRegistrationEmailVerificationCore(
      db,
      request.data?.email,
    );
    if (result.cancelled && result.uid) {
      logger.info('adminCancelRegistrationEmailVerification', {
        email: result.email,
        uid: result.uid,
        callerUid: request.auth.uid,
      });
    }
    return {
      cancelled: result.cancelled,
      reason: result.reason,
    };
  },
);

exports.dispatchRegistrationEmailVerificationJob = onDocumentCreated(
  'registration_email_verification_jobs/{jobId}',
  async (event) => {
    const snap = event.data;
    if (!snap) {
      return;
    }

    const data = snap.data() || {};
    if (data.status !== 'pending') {
      return;
    }

    const db = getFirestore();
    const requestedByUid = String(data.requestedByUid || '').trim();
    const action = String(data.action || '').trim();

    try {
      if (!requestedByUid) {
        throw new HttpsError('invalid-argument', 'requestedByUid is required.');
      }
      await assertCallerOwner(db, requestedByUid);

      if (action === 'start') {
        const result = await startRegistrationEmailVerificationCore(db, data.email);
        await snap.ref.update({
          status: 'ready',
          uid: result.uid,
          customToken: result.customToken || '',
          alreadyVerified: result.alreadyVerified === true,
          completedAt: FieldValue.serverTimestamp(),
        });
        logger.info('registration_email_verification_jobs start', {
          jobId: snap.id,
          email: result.email,
          uid: result.uid,
          requestedByUid,
        });
        return;
      }

      if (action === 'check_status') {
        const result = await checkRegistrationEmailStatusCore(db, data.email);
        await snap.ref.update({
          status: 'ready',
          uid: result.uid || '',
          verified: result.verified === true,
          hasProfile: result.hasProfile === true,
          canRegister: result.canRegister === true,
          completedAt: FieldValue.serverTimestamp(),
        });
        return;
      }

      if (action === 'cancel') {
        const result = await cancelRegistrationEmailVerificationCore(
          db,
          data.email,
        );
        await snap.ref.update({
          status: 'ready',
          cancelled: result.cancelled === true,
          cancelReason: result.reason || '',
          completedAt: FieldValue.serverTimestamp(),
        });
        if (result.cancelled && result.uid) {
          logger.info('registration_email_verification_jobs cancel', {
            jobId: snap.id,
            email: result.email,
            uid: result.uid,
            requestedByUid,
          });
        }
        return;
      }

      throw new HttpsError('invalid-argument', `Unknown action: ${action}`);
    } catch (error) {
      const { errorCode, errorMessage } = registrationJobErrorFields(error);
      await snap.ref.update({
        status: 'failed',
        errorCode,
        errorMessage,
        completedAt: FieldValue.serverTimestamp(),
      });
      logger.error('registration_email_verification_jobs failed', {
        jobId: snap.id,
        action,
        requestedByUid,
        errorCode,
        errorMessage,
      });
    }
  },
);

const db = getFirestore();
Object.assign(
  exports,
  registerOfferDiscoveryFunctions(db, adminCallableOptions),
);
