const { logger } = require('firebase-functions');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { Timestamp, FieldValue } = require('firebase-admin/firestore');

const DISCOVERED_OFFERS = 'discovered_offers';
const BRANDS = 'brands';
const APP_SETTINGS = 'app_settings';
const DISCOVERY_SETTINGS_DOC = 'offer_discovery';
const DISCOVERY_USER_AGENT = 'SaleSiren-OfferDiscovery/1.0';
const DUPLICATE_WINDOW_MS = 7 * 24 * 60 * 60 * 1000;

/**
 * @param {string} value
 */
function normalizeTitle(value) {
  return String(value || '')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, ' ');
}

/**
 * @param {import('firebase-admin/firestore').Firestore} db
 * @param {string} uid
 */
async function resolveCallerRoles(db, uid) {
  const userDoc = await db.collection('users').doc(uid).get();
  if (userDoc.exists) {
    const data = userDoc.data() || {};
    if (Array.isArray(data.roles) && data.roles.length > 0) {
      return data.roles.filter((role) => typeof role === 'string');
    }
    if (typeof data.role === 'string' && data.role.trim()) {
      return [data.role.trim()];
    }
  }

  const adminDoc = await db.collection('admins').doc(uid).get();
  if (adminDoc.exists && adminDoc.data()?.role) {
    return [String(adminDoc.data().role)];
  }
  return [];
}

/**
 * @param {string[]} roles
 */
function canRunOfferDiscovery(roles) {
  return roles.some((role) =>
    ['owner', 'admin', 'manager', 'brand_admin'].includes(role),
  );
}

/**
 * @param {import('firebase-admin/firestore').Firestore} db
 * @param {string} uid
 */
async function assertCallerCanRunDiscovery(db, uid) {
  const roles = await resolveCallerRoles(db, uid);
  if (!canRunOfferDiscovery(roles)) {
    throw new HttpsError(
      'permission-denied',
      'You do not have permission to run offer discovery.',
    );
  }
}

/**
 * @param {Date} date
 * @param {string} timeZone
 */
function formatHHmmInTimeZone(date, timeZone) {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).formatToParts(date);

  const read = (type) => parts.find((part) => part.type === type)?.value ?? '';
  const hour = read('hour').padStart(2, '0');
  const minute = read('minute').padStart(2, '0');
  const year = read('year');
  const month = read('month');
  const day = read('day');
  return {
    hhmm: `${hour}:${minute}`,
    slotKey: `${year}-${month}-${day}_${hour}:${minute}`,
  };
}

/**
 * @param {import('firebase-admin/firestore').Firestore} db
 */
async function readDiscoverySettings(db) {
  const doc = await db.collection(APP_SETTINGS).doc(DISCOVERY_SETTINGS_DOC).get();
  const data = doc.data() || {};
  const scheduledTimes = Array.isArray(data.scheduledTimes)
    ? data.scheduledTimes
        .filter((value) => typeof value === 'string' && value.trim())
        .map((value) => value.trim())
    : ['00:00', '12:00'];

  return {
    timeZone:
      typeof data.timeZone === 'string' && data.timeZone.trim()
        ? data.timeZone.trim()
        : 'Asia/Karachi',
    scheduledTimes: scheduledTimes.length > 0 ? scheduledTimes : ['00:00', '12:00'],
    autoDiscoveryEnabled: data.autoDiscoveryEnabled !== false,
    lastAutoRunSlot:
      typeof data.lastAutoRunSlot === 'string' ? data.lastAutoRunSlot : '',
  };
}

/**
 * @param {import('firebase-admin/firestore').Firestore} db
 */
async function shouldRunScheduledDiscovery(db) {
  const settings = await readDiscoverySettings(db);
  if (!settings.autoDiscoveryEnabled) {
    return { shouldRun: false, settings };
  }

  const now = new Date();
  const zoned = formatHHmmInTimeZone(now, settings.timeZone);
  if (!settings.scheduledTimes.includes(zoned.hhmm)) {
    return { shouldRun: false, settings };
  }
  if (settings.lastAutoRunSlot === zoned.slotKey) {
    return { shouldRun: false, settings };
  }
  return { shouldRun: true, settings, slotKey: zoned.slotKey };
}

/**
 * @param {Record<string, unknown>} brand
 */
function brandWebsiteUrl(brand) {
  const website =
    typeof brand.websiteUrl === 'string' ? brand.websiteUrl.trim() : '';
  if (website) {
    return website;
  }
  const sources = Array.isArray(brand.urlSources) ? brand.urlSources : [];
  for (const source of sources) {
    if (!source || typeof source !== 'object') {
      continue;
    }
    const type = String(source.type || source.kind || '').toLowerCase();
    const url = typeof source.url === 'string' ? source.url.trim() : '';
    if (url && (type === 'website' || type === 'web' || type === 'store')) {
      return url;
    }
  }
  return '';
}

/**
 * @param {string} value
 */
function cleanDiscountNumber(value) {
  return String(value || '').replace(/,/g, '').trim();
}

/**
 * @param {string} text
 * @returns {{
 *   suggestedDiscountText: string,
 *   suggestedDiscountType: string,
 *   suggestedDiscountValue: number,
 * } | null}
 */
function parseDiscountHint(text) {
  const normalized = String(text || '').replace(/\s+/g, ' ').trim();
  if (!normalized) {
    return null;
  }

  const patterns = [
    {
      regex: /up\s*to\s*(\d[\d,]*)\s*%\s*(?:off|discount)?/i,
      build: (match) => ({
        suggestedDiscountText: `Up to ${cleanDiscountNumber(match[1])}% off`,
        suggestedDiscountType: 'upto_percentage',
        suggestedDiscountValue: Number.parseInt(cleanDiscountNumber(match[1]), 10),
      }),
    },
    {
      regex: /up\s*to\s*(?:rs\.?|pkr|₨)\s*(\d[\d,]*)\s*(?:off|discount)?/i,
      build: (match) => ({
        suggestedDiscountText: `Up to Rs. ${cleanDiscountNumber(match[1])} off`,
        suggestedDiscountType: 'upto_amount',
        suggestedDiscountValue: Number.parseInt(cleanDiscountNumber(match[1]), 10),
      }),
    },
    {
      regex: /flat\s*(\d[\d,]*)\s*%\s*(?:off|discount)?/i,
      build: (match) => ({
        suggestedDiscountText: `${cleanDiscountNumber(match[1])}% off`,
        suggestedDiscountType: 'percentage',
        suggestedDiscountValue: Number.parseInt(cleanDiscountNumber(match[1]), 10),
      }),
    },
    {
      regex: /flat\s*(?:rs\.?|pkr|₨)\s*(\d[\d,]*)\s*(?:off|discount)?/i,
      build: (match) => ({
        suggestedDiscountText: `Rs. ${cleanDiscountNumber(match[1])} off`,
        suggestedDiscountType: 'flat',
        suggestedDiscountValue: Number.parseInt(cleanDiscountNumber(match[1]), 10),
      }),
    },
    {
      regex: /flat\s*(\d[\d,]*)\s*off/i,
      build: (match) => ({
        suggestedDiscountText: `Rs. ${cleanDiscountNumber(match[1])} off`,
        suggestedDiscountType: 'flat',
        suggestedDiscountValue: Number.parseInt(cleanDiscountNumber(match[1]), 10),
      }),
    },
    {
      regex: /(?:rs\.?|pkr|₨)\s*(\d[\d,]*)\s*(?:off|discount)/i,
      build: (match) => ({
        suggestedDiscountText: `Rs. ${cleanDiscountNumber(match[1])} off`,
        suggestedDiscountType: 'flat',
        suggestedDiscountValue: Number.parseInt(cleanDiscountNumber(match[1]), 10),
      }),
    },
    {
      regex: /(?:save|get)\s*(?:rs\.?|pkr|₨)?\s*(\d[\d,]*)\s*(?:off|discount)?/i,
      build: (match) => ({
        suggestedDiscountText: `Rs. ${cleanDiscountNumber(match[1])} off`,
        suggestedDiscountType: 'flat',
        suggestedDiscountValue: Number.parseInt(cleanDiscountNumber(match[1]), 10),
      }),
    },
    {
      regex: /(\d[\d,]*)\s*%\s*(?:off|discount)/i,
      build: (match) => ({
        suggestedDiscountText: `${cleanDiscountNumber(match[1])}% off`,
        suggestedDiscountType: 'percentage',
        suggestedDiscountValue: Number.parseInt(cleanDiscountNumber(match[1]), 10),
      }),
    },
    {
      regex: /(\d[\d,]*)\s*%\b/i,
      build: (match) => ({
        suggestedDiscountText: `${cleanDiscountNumber(match[1])}% off`,
        suggestedDiscountType: 'percentage',
        suggestedDiscountValue: Number.parseInt(cleanDiscountNumber(match[1]), 10),
      }),
    },
  ];

  for (const pattern of patterns) {
    const match = normalized.match(pattern.regex);
    if (!match) {
      continue;
    }
    const built = pattern.build(match);
    if (
      !Number.isFinite(built.suggestedDiscountValue) ||
      built.suggestedDiscountValue <= 0
    ) {
      continue;
    }
    return built;
  }

  return null;
}

/**
 * @param {...string} sources
 */
function findDiscountHint(...sources) {
  for (const source of sources) {
    const hint = parseDiscountHint(source);
    if (hint) {
      return hint;
    }
  }
  return parseDiscountHint(sources.filter(Boolean).join(' '));
}

/**
 * @param {string} html
 * @param {Record<string, unknown>} brand
 */
function extractWebsiteOfferHint(html, brand) {
  const ogTitle = html.match(
    /property=["']og:title["'][^>]*content=["']([^"']+)["']/i,
  );
  const ogDescription = html.match(
    /property=["']og:description["'][^>]*content=["']([^"']+)["']/i,
  );
  const titleTag = html.match(/<title[^>]*>([^<]+)<\/title>/i);
  const ogImage = html.match(
    /property=["']og:image["'][^>]*content=["']([^"']+)["']/i,
  );

  const suggestedTitle = (
    ogTitle?.[1] ||
    titleTag?.[1] ||
    brand.name ||
    'Offer'
  )
    .trim()
    .slice(0, 180);

  const plainText = html
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  const suggestedDescription = (
    ogDescription?.[1] ||
    plainText.slice(0, 500)
  )
    .trim()
    .slice(0, 500);

  const discountHint = findDiscountHint(suggestedTitle, plainText.slice(0, 8000));
  const saleSignal =
    /\b(sale|discount|clearance|deal|offer|eid|ramadan|promo)\b/i.test(
      `${suggestedTitle} ${plainText.slice(0, 2000)}`,
    );

  if (!saleSignal && !discountHint) {
    return null;
  }

  const categoryCodes = Array.isArray(brand.categoryIds)
    ? brand.categoryIds.filter((id) => typeof id === 'string' && id.trim())
    : [];
  const cityCodes = Array.isArray(brand.cityIds)
    ? brand.cityIds.filter((id) => typeof id === 'string' && id.trim())
    : [];

  return {
    suggestedTitle,
    suggestedDescription,
    suggestedDiscountText: discountHint?.suggestedDiscountText || '',
    suggestedDiscountType: discountHint?.suggestedDiscountType || '',
    suggestedDiscountValue: discountHint?.suggestedDiscountValue ?? null,
    suggestedCategoryCodes: categoryCodes,
    suggestedCityCodes: cityCodes,
    imageUrl: ogImage?.[1]?.trim() || '',
    confidenceScore: discountHint ? 0.78 : saleSignal ? 0.55 : 0.35,
    rawText: plainText.slice(0, 4000),
  };
}

/**
 * @param {import('firebase-admin/firestore').Firestore} db
 * @param {string} brandId
 * @param {string} sourceUrl
 * @param {string} suggestedTitle
 */
async function findExistingDiscovery(db, brandId, sourceUrl, suggestedTitle) {
  const byUrl = await db
    .collection(DISCOVERED_OFFERS)
    .where('brandId', '==', brandId)
    .where('sourceUrl', '==', sourceUrl)
    .limit(10)
    .get();
  if (!byUrl.empty) {
    return byUrl.docs.sort((a, b) => {
      const aMs = a.data().createdAt?.toMillis?.() ?? 0;
      const bMs = b.data().createdAt?.toMillis?.() ?? 0;
      return bMs - aMs;
    })[0];
  }

  const since = Timestamp.fromMillis(Date.now() - DUPLICATE_WINDOW_MS);
  const normalizedTitle = normalizeTitle(suggestedTitle);
  const recent = await db
    .collection(DISCOVERED_OFFERS)
    .where('brandId', '==', brandId)
    .where('createdAt', '>', since)
    .limit(25)
    .get();

  return (
    recent.docs.find((doc) => {
      return normalizeTitle(doc.data().suggestedTitle) === normalizedTitle;
    }) || null
  );
}

/**
 * @param {import('firebase-admin/firestore').Firestore} db
 * @param {string} convertedOfferId
 */
async function convertedOfferStillExists(db, convertedOfferId) {
  const offerId = String(convertedOfferId || '').trim();
  if (!offerId) {
    return false;
  }
  const snap = await db.collection('offers').doc(offerId).get();
  return snap.exists;
}

/**
 * @param {Record<string, unknown>} hint
 * @param {Record<string, unknown>} brand
 * @param {string} brandId
 * @param {string} brandName
 * @param {string} sourceUrl
 */
function buildDiscoverySuggestionFields(hint, brand, brandId, brandName, sourceUrl) {
  const categoryCodes = Array.isArray(brand.categoryIds)
    ? brand.categoryIds.filter((id) => typeof id === 'string' && id.trim())
    : [];
  const cityCodes = Array.isArray(brand.cityIds)
    ? brand.cityIds.filter((id) => typeof id === 'string' && id.trim())
    : [];

  return {
    brandId,
    brandName,
    sourceType: 'website',
    sourceUrl,
    rawText: hint.rawText,
    suggestedTitle: hint.suggestedTitle,
    suggestedDescription: hint.suggestedDescription,
    suggestedDiscountText: hint.suggestedDiscountText,
    suggestedDiscountType: hint.suggestedDiscountType || '',
    suggestedDiscountValue: hint.suggestedDiscountValue ?? null,
    suggestedCategoryCodes: categoryCodes,
    suggestedCityCodes: cityCodes,
    imageUrl: hint.imageUrl,
    confidenceScore: hint.confidenceScore,
  };
}

/**
 * @param {import('firebase-admin/firestore').Firestore} db
 * @param {Record<string, unknown>} brand
 * @param {string} sourceUrl
 * @param {Record<string, unknown>} hint
 */
async function upsertDiscoverySuggestion(db, brand, sourceUrl, hint) {
  const brandId = String(brand.id || '').trim();
  const brandName = String(brand.name || '').trim();
  const fields = buildDiscoverySuggestionFields(
    hint,
    brand,
    brandId,
    brandName,
    sourceUrl,
  );
  const refreshPayload = {
    ...fields,
    updatedAt: FieldValue.serverTimestamp(),
    checkedAt: FieldValue.serverTimestamp(),
  };

  const existingSnap = await findExistingDiscovery(
    db,
    brandId,
    sourceUrl,
    hint.suggestedTitle,
  );

  if (!existingSnap) {
    await db.collection(DISCOVERED_OFFERS).add({
      ...fields,
      status: 'pending_review',
      convertedOfferId: '',
      rejectionReason: '',
      duplicateOfOfferId: '',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      checkedAt: FieldValue.serverTimestamp(),
    });
    return { type: 'discovered' };
  }

  const existing = existingSnap.data() || {};
  const status = String(existing.status || '');

  if (status === 'converted') {
    const stillExists = await convertedOfferStillExists(
      db,
      existing.convertedOfferId,
    );
    if (stillExists) {
      await existingSnap.ref.update(refreshPayload);
      return { type: 'duplicate' };
    }
    await existingSnap.ref.update({
      ...refreshPayload,
      status: 'pending_review',
      convertedOfferId: '',
      rejectionReason: '',
      duplicateOfOfferId: '',
    });
    return { type: 'reactivated' };
  }

  if (status === 'rejected' || status === 'duplicate') {
    await existingSnap.ref.update({
      ...refreshPayload,
      status: 'pending_review',
      convertedOfferId: '',
      rejectionReason: '',
      duplicateOfOfferId: '',
    });
    return { type: 'reactivated' };
  }

  if (status === 'source_error') {
    await existingSnap.ref.update({
      ...refreshPayload,
      status: 'pending_review',
      rejectionReason: '',
      convertedOfferId: '',
      duplicateOfOfferId: '',
    });
    return { type: 'reactivated' };
  }

  if (status === 'pending_review') {
    await existingSnap.ref.update(refreshPayload);
    return { type: 'refreshed' };
  }

  await existingSnap.ref.update(refreshPayload);
  return { type: 'duplicate' };
}

/**
 * @param {import('firebase-admin/firestore').Firestore} db
 * @param {Record<string, unknown>} brand
 * @param {string} sourceUrl
 */
async function discoverFromWebsite(db, brand, sourceUrl) {
  const brandId = String(brand.id || '').trim();
  const brandName = String(brand.name || '').trim();
  if (!brandId || !sourceUrl) {
    return { type: 'error' };
  }

  let html = '';
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);
    const response = await fetch(sourceUrl, {
      signal: controller.signal,
      headers: {
        'User-Agent': DISCOVERY_USER_AGENT,
        Accept: 'text/html,application/xhtml+xml',
      },
      redirect: 'follow',
    });
    clearTimeout(timeout);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    html = await response.text();
  } catch (error) {
    logger.warn('offer_discovery fetch failed', {
      brandId,
      sourceUrl,
      error: error instanceof Error ? error.message : String(error),
    });
    await db.collection(DISCOVERED_OFFERS).add({
      brandId,
      brandName,
      sourceType: 'website',
      sourceUrl,
      rawText: '',
      suggestedTitle: brandName,
      suggestedDescription: '',
      suggestedDiscountText: '',
      suggestedDiscountType: '',
      suggestedDiscountValue: null,
      suggestedCategoryCodes: [],
      suggestedCityCodes: [],
      imageUrl: '',
      confidenceScore: 0,
      status: 'source_error',
      convertedOfferId: '',
      rejectionReason: error instanceof Error ? error.message : 'Fetch failed',
      duplicateOfOfferId: '',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      checkedAt: FieldValue.serverTimestamp(),
    });
    return { type: 'error' };
  }

  const hint = extractWebsiteOfferHint(html, brand);
  if (!hint) {
    return { type: 'skipped' };
  }

  return upsertDiscoverySuggestion(db, brand, sourceUrl, hint);
}

/**
 * @param {import('firebase-admin/firestore').Firestore} db
 */
async function discoverBrandOffersCore(db) {
  const snapshot = await db
    .collection(BRANDS)
    .where('isActive', '==', true)
    .get();

  let checkedBrands = 0;
  let discoveredCount = 0;
  let duplicateCount = 0;
  let errorCount = 0;

  for (const doc of snapshot.docs) {
    const brand = { id: doc.id, ...doc.data() };
    const websiteUrl = brandWebsiteUrl(brand);
    if (!websiteUrl) {
      continue;
    }

    checkedBrands += 1;
    const result = await discoverFromWebsite(db, brand, websiteUrl);
    if (result.type === 'discovered' || result.type === 'reactivated') {
      discoveredCount += 1;
    } else if (result.type === 'duplicate') {
      duplicateCount += 1;
    } else if (result.type === 'error') {
      errorCount += 1;
    }
  }

  return { checkedBrands, discoveredCount, duplicateCount, errorCount };
}

/**
 * @param {import('firebase-admin/firestore').Firestore} db
 * @param {() => object} adminCallableOptions
 */
function registerOfferDiscoveryFunctions(db, adminCallableOptions) {
  const discoverBrandOffersScheduled = onSchedule(
    {
      schedule: '*/15 * * * *',
      timeZone: 'Asia/Karachi',
      region: 'us-central1',
    },
    async () => {
      const gate = await shouldRunScheduledDiscovery(db);
      if (!gate.shouldRun) {
        return;
      }

      const result = await discoverBrandOffersCore(db);
      await db.collection(APP_SETTINGS).doc(DISCOVERY_SETTINGS_DOC).set(
        {
          lastAutoRunSlot: gate.slotKey,
          lastAutoRunAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      logger.info('discoverBrandOffersScheduled complete', {
        slotKey: gate.slotKey,
        ...result,
      });
    },
  );

  const runDiscoverBrandOffers = onCall(adminCallableOptions(), async (req) => {
    if (!req.auth?.uid) {
      throw new HttpsError('unauthenticated', 'Sign in required.');
    }
    await assertCallerCanRunDiscovery(db, req.auth.uid);
    const result = await discoverBrandOffersCore(db);
    logger.info('runDiscoverBrandOffers manual', {
      uid: req.auth.uid,
      ...result,
    });
    return result;
  });

  const dispatchOfferDiscoveryJob = onDocumentCreated(
    'offer_discovery_jobs/{jobId}',
    async (event) => {
      const snap = event.data;
      if (!snap) {
        return;
      }

      const data = snap.data() || {};
      if (data.status !== 'pending') {
        return;
      }

      const requestedByUid = String(data.requestedByUid || '').trim();
      try {
        if (!requestedByUid) {
          throw new HttpsError('invalid-argument', 'requestedByUid is required.');
        }
        await assertCallerCanRunDiscovery(db, requestedByUid);
        const result = await discoverBrandOffersCore(db);
        await snap.ref.update({
          status: 'ready',
          checkedBrands: result.checkedBrands,
          discoveredCount: result.discoveredCount,
          duplicateCount: result.duplicateCount,
          errorCount: result.errorCount,
          completedAt: FieldValue.serverTimestamp(),
        });
        logger.info('offer_discovery_jobs complete', {
          jobId: snap.id,
          requestedByUid,
          ...result,
        });
      } catch (error) {
        const errorCode =
          error instanceof HttpsError ? error.code : 'internal';
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        await snap.ref.update({
          status: 'failed',
          errorCode,
          errorMessage,
          completedAt: FieldValue.serverTimestamp(),
        });
        logger.error('offer_discovery_jobs failed', {
          jobId: snap.id,
          requestedByUid,
          errorCode,
          errorMessage,
        });
      }
    },
  );

  return {
    discoverBrandOffersScheduled,
    runDiscoverBrandOffers,
    dispatchOfferDiscoveryJob,
  };
}

module.exports = {
  discoverBrandOffersCore,
  registerOfferDiscoveryFunctions,
};
