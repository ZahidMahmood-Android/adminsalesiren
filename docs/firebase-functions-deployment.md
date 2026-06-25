# Firebase Cloud Functions — Deployment Guide

How to deploy Salesiren Cloud Functions, what they do, and how we fixed the **build service account permission** error on project `salesiren-5539c`.

See also: [`firebase-setup.md`](./firebase-setup.md), [`firestore-schema.md`](./firestore-schema.md).

---

## What we deploy

| Item | Value |
|------|--------|
| Project ID | `salesiren-5539c` |
| Project number | `508084936274` |
| Source | `apps/adminpanel/functions/` |
| Runtime | Node.js 20 (Gen 2) |
| Region | `us-central1` |

### Function: `dispatchOfferPushOnPublish`

- **Trigger:** Firestore `offers/{offerId}` document write (no-op).
- **Purpose:** Push dispatch is handled exclusively by `dispatchOfferPushOnJob` when the admin panel writes `offer_push_jobs`.

### Function: `dispatchOfferPushOnJob`

- **Trigger:** Firestore `offer_push_jobs/{jobId}` document write.
- **Purpose:** Primary dispatch path for Flutter Web. The admin panel writes `offer_push_jobs`; this function sends FCM without a browser CORS request.
- **Recipients:** All mobile users with at least one `fcmTokens` entry and `notificationEnabled !== false` (not admin-panel roles).
- **Images:** Reads `notification_requests/{requestId}.includeImage`; when true, attaches the offer image to FCM notification/data payloads. When false, sends title/body only.
- **Job result:** Always writes a completion result or `lastError` / `lastFcmError` to `offer_push_jobs/{jobId}` so the admin panel shows the first FCM error when `successCount=0`.

### Function: `sendOfferPush` (callable)

- **Type:** HTTPS callable (`us-central1`).
- **Purpose:** Non-web immediate dispatch fallback. Flutter Web skips this callable and relies on `dispatchOfferPushOnJob` to avoid browser CORS failures.
- **Auth:** Signed-in owner, manager, brand admin, or admin role from `users/{uid}` or owner/admin reference from `admins/{uid}`.
- **CORS:** Explicitly enabled for web callable preflight (`cors: true`).
- **Returns:** `{ successCount, recipientCount, tokenCount, invalidTokenCount, skipped?, reason? }`

Admin panel code creates/approves `notification_requests`, schedules `offer_push_jobs`, calls `sendOfferPush`, and updates `notification_requests` to `sent` with counts.

### Registration email verification (Flutter Web)

| Function | Type | Purpose |
|----------|------|---------|
| `dispatchRegistrationEmailVerificationJob` | Firestore `registration_email_verification_jobs/{jobId}` create | **Primary path on Flutter Web.** Owner writes a job; function creates Auth user, returns `customToken`, checks status, or cancels pending verification without browser callable CORS. |
| `adminStartRegistrationEmailVerification` | Callable | Non-web fallback to start verification. |
| `adminCheckRegistrationEmailStatus` | Callable | Non-web fallback to poll verification status. |
| `adminCancelRegistrationEmailVerification` | Callable | Non-web fallback to delete pending Auth user. |

Deploy:

```bash
firebase deploy --only functions:dispatchRegistrationEmailVerificationJob,functions:adminStartRegistrationEmailVerification,functions:adminCheckRegistrationEmailStatus,functions:adminCancelRegistrationEmailVerification,firestore:rules --project salesiren-5539c
```

### Registration email verification IAM (`signBlob`)

**Symptom:** Admin **Send verification email** fails with:

```text
Permission iam.serviceAccounts.signBlob is required …
```

**Cause:** The job trigger calls `auth.createCustomToken()`. The function runtime service account must be allowed to sign tokens.

**Step 1 — Confirm runtime service account**

1. Open [Cloud Functions](https://console.cloud.google.com/functions/list?project=salesiren-5539c).
2. Click **`dispatchRegistrationEmailVerificationJob`** → **Details** → copy **Runtime service account**.

Expected after `setGlobalOptions` in `functions/index.js`:

```text
salesiren-5539c@appspot.gserviceaccount.com
```

If it still shows `508084936274-compute@developer.gserviceaccount.com`, redeploy functions so `serviceAccount: salesiren-5539c@appspot.gserviceaccount.com` is applied.

**Step 2 — Grant Service Account Token Creator**

In [IAM](https://console.cloud.google.com/iam-admin/iam?project=salesiren-5539c), for **each** runtime account from step 1 (grant both if unsure):

| Principal | Role to add |
|-----------|-------------|
| `salesiren-5539c@appspot.gserviceaccount.com` | **Service Account Token Creator** |
| `508084936274-compute@developer.gserviceaccount.com` | **Service Account Token Creator** |

Or with gcloud (project owner):

```bash
gcloud services enable iam.googleapis.com --project=salesiren-5539c

gcloud projects add-iam-policy-binding salesiren-5539c \
  --member="serviceAccount:salesiren-5539c@appspot.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator"

gcloud projects add-iam-policy-binding salesiren-5539c \
  --member="serviceAccount:508084936274-compute@developer.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator"
```

**Step 3 — Retry**

Wait ~1 minute, then click **Send verification email** again. No redeploy needed after IAM-only changes.

**Optional:** Run functions as the Firebase Admin SDK service account (already has Firebase roles). IAM → Service accounts → copy `firebase-adminsdk-…@salesiren-5539c.iam.gserviceaccount.com`, then redeploy:

```bash
FIREBASE_FUNCTIONS_SERVICE_ACCOUNT=firebase-adminsdk-XXXX@salesiren-5539c.iam.gserviceaccount.com \
  firebase deploy --only functions:dispatchRegistrationEmailVerificationJob --project salesiren-5539c
```

**2026-06-24 fix:** Push dispatch also scans token-bearing mobile user documents after role-based recipient queries. This covers older mobile users whose `fcmTokens` exist but whose role fields are missing or stale, while still excluding privileged admin roles.

### Function: `cleanupExpiredOffers`

- **Trigger:** Scheduled daily at 03:30 Asia/Karachi.
- **Purpose:** Deletes offers that have been expired for more than 10 days, removes related Storage images under `offers/{offerId}/`, and deletes linked `notification_requests` / `offer_push_jobs`.
- **IAM:** Runtime service account needs Firestore access and Storage object delete access, e.g. **Cloud Datastore User** (`roles/datastore.user`) and **Storage Object Admin** (`roles/storage.objectAdmin`) on the Firebase Storage bucket/project.

---

## Prerequisites

1. **Firebase CLI** logged in as a project Owner or Editor:
   ```bash
   firebase login
   firebase projects:list
   ```

2. **Billing enabled** on the GCP project (required for Cloud Functions Gen 2 / Cloud Run).

3. **APIs enabled** (Firebase CLI usually enables these on first deploy; Compute Engine must be enabled manually if missing):
   - Cloud Functions
   - Cloud Build
   - Artifact Registry
   - Cloud Run
   - Eventarc
   - Pub/Sub
   - Cloud Storage
   - **Compute Engine API** (`compute.googleapis.com`)

4. **Node.js** installed locally (for `npm install` in `functions/`).

---

## First-time deploy

From the admin panel app root:

```bash
cd apps/adminpanel

# Install function dependencies
cd functions && npm install && cd ..

# Deploy functions only
firebase deploy --only functions --project salesiren-5539c
```

Deploy Firestore indexes used by the function (collection group on `saved_brands.brandName`):

```bash
firebase deploy --only firestore:indexes --project salesiren-5539c
```

Deploy everything together when needed:

```bash
firebase deploy --only functions,firestore:indexes,firestore:rules --project salesiren-5539c
```

### Verify deployment

```bash
firebase functions:list --project salesiren-5539c
```

In [Firebase Console → Functions](https://console.firebase.google.com/project/salesiren-5539c/functions), confirm `dispatchOfferPushOnPublish` is active.

Test: publish an offer in the admin panel, then check **Functions → Logs** for send counts.

---

## Runtime Firestore Permission

If function logs show this while `dispatchOfferPushOnJob` reads Firestore:

```text
Missing or insufficient permissions
@google-cloud/firestore
@grpc/grpc-js
```

This is **Cloud IAM**, not Firestore security rules. Cloud Functions Admin SDK bypasses Firestore rules, but the function runtime service account still needs project IAM permission.

### Fix in Google Cloud Console

1. Open [Cloud Functions](https://console.cloud.google.com/functions/list?project=salesiren-5539c).
2. Click `dispatchOfferPushOnJob`.
3. Open **Details** and copy the **Runtime service account**.
4. Open [IAM](https://console.cloud.google.com/iam-admin/iam?project=salesiren-5539c).
5. Grant that runtime service account:
   - **Cloud Datastore User** (`roles/datastore.user`)

For this project the runtime service account is commonly:

```text
508084936274-compute@developer.gserviceaccount.com
```

### CLI equivalent

Use the service account shown in the function details:

```bash
gcloud projects add-iam-policy-binding salesiren-5539c \
  --member="serviceAccount:508084936274-compute@developer.gserviceaccount.com" \
  --role="roles/datastore.user"
```

Then publish an offer again and check `offer_push_jobs/{jobId}` for `dispatchCompletedAt`, `sentCount`, or `lastError`.

---

## Runtime FCM permission (`cloudmessaging.messages.create`)

If function logs or `offer_push_jobs.lastError` show:

```text
cloudmessaging.messages.create denied on resource
//cloudresourcemanager.googleapis.com/projects/salesiren-5539c
```

The function **runtime** service account is not allowed to send FCM via the Admin SDK.

### Code fix (deploy required)

`functions/index.js` sets Gen 2 `serviceAccount` to:

```text
salesiren-5539c@appspot.gserviceaccount.com
```

Redeploy:

```bash
firebase deploy --only functions:dispatchOfferPushOnJob,functions:sendOfferPush --project salesiren-5539c
```

Deploy cleanup only:

```bash
firebase deploy --only functions:cleanupExpiredOffers --project salesiren-5539c
```

In Cloud Functions → function **Details**, confirm **Runtime service account** is `salesiren-5539c@appspot.gserviceaccount.com` (not `508084936274-compute@...`).

### IAM fix (if deploy alone is not enough)

1. Open [IAM](https://console.cloud.google.com/iam-admin/iam?project=salesiren-5539c).
2. Find **`salesiren-5539c@appspot.gserviceaccount.com`** (App Engine default service account).
3. Grant **Firebase Admin** (`roles/firebase.admin`).

`roles/firebasemessaging.admin` alone may **not** include `cloudmessaging.messages.create`. Prefer `roles/firebase.admin` or the auto-created **`firebase-adminsdk-*@salesiren-5539c.iam.gserviceaccount.com`** account (already has Firebase Admin SDK roles).

Optional — use the Firebase Admin SDK account instead:

1. IAM → Service accounts → copy `firebase-adminsdk-…@salesiren-5539c.iam.gserviceaccount.com`.
2. Redeploy with:
   ```bash
   FIREBASE_FUNCTIONS_SERVICE_ACCOUNT=firebase-adminsdk-XXXX@salesiren-5539c.iam.gserviceaccount.com \
     firebase deploy --only functions --project salesiren-5539c
   ```

Enable the API if prompted:

```bash
gcloud services enable fcm.googleapis.com --project=salesiren-5539c
```

### CLI — grant Firebase Admin to App Engine SA

```bash
gcloud projects add-iam-policy-binding salesiren-5539c \
  --member="serviceAccount:salesiren-5539c@appspot.gserviceaccount.com" \
  --role="roles/firebase.admin"
```

### CLI — grant to Compute SA (only if you keep the default runtime account)

```bash
gcloud projects add-iam-policy-binding salesiren-5539c \
  --member="serviceAccount:508084936274-compute@developer.gserviceaccount.com" \
  --role="roles/firebase.admin"
```

Then resend a notification and confirm `sentCount > 0` on `offer_push_jobs/{jobId}`.

---

## Troubleshooting deploy with debug logs

If deploy fails, run:

```bash
firebase deploy --only functions --debug --project salesiren-5539c
```

Useful lines in the output:

- **Project number:** `"projectNumber":"508084936274"` in the Cloud Resource Manager response.
- **Build service account:** in function metadata, `"serviceAccount":"...508084936274-compute@developer.gserviceaccount.com"`.
- **Cloud Build log URL:** link under `cloud-build/builds;region=us-central1/...`.
- **IAM snapshot:** `getIamPolicy` shows which service accounts have which roles.

---

## Problem we hit (2026-06-19)

### Symptom

```
Build failed with status: FAILURE. Could not build the function due to a missing permission on the build service account.
```

Cloud Build link (example from our failed run):  
https://console.cloud.google.com/cloud-build/builds;region=us-central1/cf3259d6-ce18-42a7-957f-f27a76b18d5f?project=508084936274

### Root causes (two issues)

#### 1. Compute Engine API disabled

Debug log showed:

```text
Compute Engine API has not been used in project 508084936274 before or it is disabled.
```

Gen 2 Functions use Cloud Build with the default **Compute Engine service account**. Firebase falls back to `508084936274-compute@developer.gserviceaccount.com` when the Compute API is unavailable.

#### 2. IAM roles on the wrong service account

IAM had `roles/cloudbuild.builds.builder` on:

- `501491301903-compute@developer.gserviceaccount.com` ← **wrong project number**
- `508084936274@cloudbuild.gserviceaccount.com` ← Cloud Build SA (partial fix)

But the **actual build account** for our function was:

```text
508084936274-compute@developer.gserviceaccount.com
```

That account did **not** have `cloudbuild.builds.builder`, `logging.logWriter`, or `artifactregistry.writer`.

Granting roles to `501491301903-*` does nothing for project `508084936274`.

---

## Solution (what fixed it)

### Step 1 — Enable Compute Engine API

```bash
gcloud services enable compute.googleapis.com --project=salesiren-5539c
```

Or use the [API enable link](https://console.developers.google.com/apis/api/compute.googleapis.com/overview?project=508084936274).

Wait 1–2 minutes for propagation.

### Step 2 — Grant roles to the correct accounts

Use project number **`508084936274`** (not any other number).

**Default Compute service account** (used as Gen 2 build SA):

```bash
PROJECT_ID=salesiren-5539c
COMPUTE_SA=508084936274-compute@developer.gserviceaccount.com

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$COMPUTE_SA" \
  --role="roles/cloudbuild.builds.builder"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$COMPUTE_SA" \
  --role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$COMPUTE_SA" \
  --role="roles/artifactregistry.writer"
```

**Cloud Build service account** (recommended):

```bash
BUILD_SA=508084936274@cloudbuild.gserviceaccount.com

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$BUILD_SA" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$BUILD_SA" \
  --role="roles/logging.logWriter"
```

### Step 3 — Redeploy

```bash
cd apps/adminpanel
firebase deploy --only functions --project salesiren-5539c
```

### Step 4 — Verify IAM in Console

**Google Cloud Console → IAM & Admin → IAM** — confirm:

| Principal | Roles |
|-----------|--------|
| `508084936274-compute@developer.gserviceaccount.com` | Cloud Build Service Account, Logs Writer, Artifact Registry Writer |
| `508084936274@cloudbuild.gserviceaccount.com` | Cloud Build Service Account, Artifact Registry Writer, Logs Writer |

Remove mistaken bindings for `501491301903-*` if they were added to this project.

---

## Console alternative (no gcloud)

1. Open [IAM](https://console.cloud.google.com/iam-admin/iam?project=salesiren-5539c).
2. Find **`508084936274-compute@developer.gserviceaccount.com`** (Default compute service account).
3. **Edit principal → Add role:**
   - Cloud Build Service Account
   - Logs Writer
   - Artifact Registry Writer
4. Save and redeploy functions.

---

## If deploy still fails

### Failed to set IAM Policy / Unable to set the invoker

**Symptom:** Deploy updates some functions but fails on new or updated **callable** (`onCall`) functions with:

```text
Failed to set the IAM Policy on the Service projects/.../services/admin...
Unable to set the invoker for the IAM policy
```

**Cause:** Gen 2 callables are Cloud Run services. Setting `invoker: 'public'` (required for Flutter/web `httpsCallable`) updates Cloud Run IAM. That needs **Cloud Functions Admin** (`roles/cloudfunctions.admin`). `roles/cloudfunctions.developer` can deploy code but not change IAM.

**Fix (pick one):**

1. **Grant deployer IAM (recommended)** — [IAM](https://console.cloud.google.com/iam-admin/iam?project=salesiren-5539c) → your Google account → add **Cloud Functions Admin**, then redeploy:
   ```bash
   firebase deploy --only functions:adminStartRegistrationEmailVerification,functions:adminCheckRegistrationEmailStatus,functions:adminCancelRegistrationEmailVerification --project salesiren-5539c
   ```

2. **Manual invoker (project owner)** — [Cloud Run](https://console.cloud.google.com/run?project=salesiren-5539c) → each failed service → **Permissions** → **Grant access** → principal `allUsers`, role **Cloud Run Invoker**. Then rerun deploy (code-only update).

3. **gcloud (one service example):**
   ```bash
   gcloud run services add-iam-policy-binding adminstartregistrationemailverification \
     --region=us-central1 \
     --member=allUsers \
     --role=roles/run.invoker \
     --project=salesiren-5539c
   ```
   Repeat for `admincheckregistrationemailstatus` and `admincancelregistrationemailverification` (Cloud Run names are lowercase).

All admin-panel `onCall` exports in `functions/index.js` use `adminCallableOptions()` (`invoker: 'public'` + explicit localhost/production CORS regex list). Auth is enforced inside the handler via `request.auth`, not by private Cloud Run IAM.

---

1. Open the **Cloud Build** log URL from the `--debug` output.
2. Read the last error line — it names the exact missing permission (sometimes `storage.objects.get` on `gcf-v2-sources-*` buckets).
3. Reference: [Cloud Functions troubleshooting — Build service account](https://cloud.google.com/functions/docs/troubleshooting#build-service-account).

Common extra roles if needed:

- `roles/storage.objectViewer` on the project or GCF source buckets
- `roles/iam.serviceAccountUser` so the build SA can act as the runtime SA

---

## Runtime note

Cloud Functions use **Node.js 22** (`functions/package.json` → `"engines": { "node": "22" }`).

Node.js 20 was deprecated on 2026-04-30 and is decommissioned on **2026-10-30**. Deploy with Node 22 locally:

```bash
cd functions && nvm use   # reads .nvmrc
cd .. && firebase deploy --only functions
```

If you change the runtime version, redeploy all functions so Firebase picks up the new runtime.

---

## Quick reference — service accounts

| Account | Email pattern | Used for |
|---------|---------------|----------|
| Default Compute | `{PROJECT_NUMBER}-compute@developer.gserviceaccount.com` | Gen 2 function **build** and often **runtime** |
| Cloud Build | `{PROJECT_NUMBER}@cloudbuild.gserviceaccount.com` | Cloud Build jobs |
| App Engine default | `{PROJECT_ID}@appspot.gserviceaccount.com` | Legacy Firebase / actAs checks |
| Firebase Admin SDK | `firebase-adminsdk-...@salesiren-5539c.iam.gserviceaccount.com` | Server admin access |

**Runtime IAM (Gen 2):** grant the runtime service account `roles/datastore.user` (Firestore) and `roles/firebase.admin` (FCM send). Functions should run as `salesiren-5539c@appspot.gserviceaccount.com`, not the default Compute SA.

Always use **your** project number from:

```bash
gcloud projects describe salesiren-5539c --format='value(projectNumber)'
```

Expected output: `508084936274`.

---

## Troubleshooting: billing API 429 (`project_number:563584335869`)

If deploy fails with:

```text
Request to https://cloudbilling.googleapis.com/v1/projects/salesiren-5539c/billingInfo
had HTTP Error: 429 ... consumer 'project_number:563584335869'
```

**This is not your project.** `563584335869` is Firebase CLI’s shared OAuth quota project. Your project is **`salesiren-5539c`** / **`508084936274`**.

The CLI hit a **global rate limit** on that shared project (common during heavy deploy traffic).

**Fix (use your project for API quota):**

```bash
export GOOGLE_CLOUD_QUOTA_PROJECT=salesiren-5539c
firebase deploy --only functions --project salesiren-5539c
```

Also enable **Cloud Billing API** on your project (one-time):

https://console.cloud.google.com/apis/library/cloudbilling.googleapis.com?project=salesiren-5539c

If it still fails, wait 1–2 minutes and retry (per-minute quota), or upgrade Firebase CLI (`npm i -g firebase-tools`) — newer versions route billing checks through your project more reliably.

---

## Related files

| Path | Purpose |
|------|---------|
| `functions/index.js` | Function implementation |
| `functions/package.json` | Node deps and engine |
| `firebase.json` | Functions source config |
| `firestore.indexes.json` | `saved_brands` collection group index |
| `lib/features/offers/presentation/providers/offer_providers.dart` | Creates notification request before publish |
