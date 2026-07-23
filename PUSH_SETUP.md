# Push Notifications — Setup

Push (shift / announcement / chat) needs Firebase Cloud Messaging on **both** the
backend and the app. Until configured, the app degrades gracefully: in-app
notifications + polling keep working, only OS-level push is disabled.

## Backend (planno_backend)
1. Firebase Console → Project Settings → **Service accounts** → *Generate new
   private key* → save the JSON.
2. Set `FIREBASE_SERVICE_ACCOUNT_PATH` in `.env` to its path (see `.env.example`).
   On GCP you can instead rely on default credentials and set only
   `FIREBASE_PROJECT_ID`.
3. Restart the server. On boot you should see
   `Firebase Admin initialized from service account file`.

## Flutter app (Wrenta)
1. Install the FlutterFire CLI: `dart pub global activate flutterfire_cli`.
2. From the app root run `flutterfire configure` and pick the same Firebase
   project. This **regenerates** `lib/firebase_options.dart` (currently a
   placeholder that throws) and writes:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
3. **iOS only:** upload your APNs auth key in Firebase Console → Cloud Messaging,
   and enable Push Notifications + Background Modes (Remote notifications) in
   Xcode.
4. Rebuild. On login the device token is registered automatically
   (`NotificationService.onLogin`), and tapping a notification deep-links to the
   relevant screen (shift / absence / announcement / chat).

## Verifying end-to-end
- Log in on a physical device (push doesn't work on iOS simulators).
- Have a manager post an announcement or send a chat message → the device should
  receive a banner, and the in-app bell badge should increment.
