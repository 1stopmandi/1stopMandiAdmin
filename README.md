# 1StopMandi Admin App

Separate Flutter mobile app for admin order review and management.

## Setup

### 1. Firebase project

1. Create / open your Firebase project at https://console.firebase.google.com
2. Add an Android app with package name `com.onestopmandi.admin`
3. Download `google-services.json` → place it at `android/app/google-services.json`
4. (iOS) Download `GoogleService-Info.plist` → place it at `ios/Runner/GoogleService-Info.plist`

### 2. Backend — Firebase service account

1. Firebase console → Project Settings → Service Accounts → Generate new private key
2. Set the downloaded JSON as an environment variable in your backend:
   ```
   FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
   ```

### 3. Run migrations

```bash
cd Backend
npm run migrate
```

This runs migrations `031` (deliver_by columns + new statuses) and `032` (device_tokens table).

### 4. Build and run the admin app

The admin app **defaults to the production API** (`https://1s-89e678997d014bf3bd82bf5c6d3e78ba.ecs.ap-south-1.on.aws`) — same backend as the buyer app — so login and orders work without running a local server.

```bash
cd 1stopMandiAdmin
flutter pub get
flutter run
```

The login screen shows **API: …** in debug — confirm it points to production unless you intentionally use local dev.

**Local backend only** (optional):

```bash
# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Physical device (replace with your Mac's LAN IP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:3000
```

Your Mac must reach Neon DB (internet + valid `DATABASE_URL` in `Backend/.env`) when using a local backend.

## Key features

- **Login** via OTP (phone or email) — admin role is enforced; non-admin users are rejected
- **Orders** — list with status filters; accept, reject, request delivery extension
- **Clients** — B2B buyer list with search and filters; create/edit profiles; setup approval; billing summary; mark orders paid; block/unblock
- **Products** — catalog list with search, category and active filters; create/edit products; view pricing slabs; deactivate/reactivate
- **Categories** — list with sort order and product counts; create/edit; deactivate/reactivate (blocked when active products exist)
- **Uploaded Orders** — review buyer photo uploads; build cart lines; mark ready or reject
- **Users** — platform user list with stats; promote to admin; block/unblock; view orders
- **Legacy Pricing** — per-product base price + slabs; audit log; revert
- **Bulk Pricing** — CSV export/import (preview → confirm); quick slug-based batch update
- **Navigation** — bottom tabs (Orders | Clients | Products | Categories) + side menu for all modules
- **FCM push notifications** for new orders, buyer responses to extensions

## Order status flow

```
pending → confirmed (accept)
pending → rejected  (reject + reason)
pending → extension_requested (request time change)

extension_requested → confirmed (buyer approves OR admin accepts original)
extension_requested → pending   (buyer rejects → back to admin)
extension_requested → rejected  (admin rejects)
```
# 1stopMandiAdmin
# 1stopMandiAdmin
# 1stopMandiAdmin
