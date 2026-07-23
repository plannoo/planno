# App Store & Play submission checklist

Package / bundle id: **`com.wrenta.app`** (same on both platforms).
Version: `pubspec.yaml` → `version: 1.0.0+1` (name `1.0.0`, build `1`).

## Already in place

- **Release signing (Android)** — `android/key.properties` exists and
  `android/app/build.gradle` wires a `release` `signingConfig`. It silently
  falls back to the debug key when the properties file is missing, so always
  verify the shipped artifact (below) rather than trusting the build to fail.
- **SDK levels (Android)** — resolved `minSdkVersion 24`, `targetSdkVersion 36`
  (read from the merged release manifest). Above Play's current floor.
- **In-app account deletion** — required by both stores for apps with accounts.
  Implemented (`_DeleteAccountSheet` in `lib/pages/profile/menu_page.dart`,
  `DELETE /api/me`).
- **Privacy policy / terms screens** — `lib/pages/legal/`, routed as
  `/privacy-policy` and `/terms-of-service`.
- **iOS usage strings** — `ios/Runner/Info.plist` declares
  `NSCameraUsageDescription`, `NSLocationWhenInUseUsageDescription`,
  `NSFaceIDUsageDescription`, `NSPhotoLibraryUsageDescription`.
- **iOS privacy manifest** — `ios/Runner/PrivacyInfo.xcprivacy`, wired into the
  Runner target's Copy Bundle Resources. Declares no tracking, the
  required-reason APIs the app itself uses (UserDefaults `CA92.1`, file
  timestamp `C617.1`), and the data it collects (name, email, phone, precise
  location, photos, user id, crash data) — all linked to the user, none used for
  tracking.
- **Android permissions** — legacy `READ_EXTERNAL_STORAGE` scoped with
  `android:maxSdkVersion="32"`; `READ_MEDIA_IMAGES/VIDEO/AUDIO` cover API 33+.

## Still to do (needs you)

**Both stores**
- Store listing assets: icon, feature graphic, and screenshots per device class.
- A publicly reachable privacy-policy URL (the in-app screen is not enough —
  both consoles require a URL).
- Decide the versioning cadence; bump `version:` in `pubspec.yaml` for every
  upload (Play rejects a duplicate `versionCode`).

**Google Play**
- Fill the **Data safety** form. It must match the permissions and the iOS
  privacy manifest: location (precise, app functionality), camera, photos/media,
  name/email/phone, user id, crash data — collected, linked to the user, not
  used for tracking, not sold.
- Upload an **App Bundle** (`flutter build appbundle --release`), not the APK —
  Play requires `.aab` for new apps. The APK is fine for sideload testing.

**App Store (requires a Mac + paid Apple Developer account)**
- `flutter build ipa --release`, then upload via Xcode / Transporter.
- Confirm the privacy manifest ships: after building, check
  `Runner.app/PrivacyInfo.xcprivacy` exists in the bundle.
- Complete App Privacy answers in App Store Connect — keep them consistent with
  `PrivacyInfo.xcprivacy`.
- Provide a demo account for review (the app is login-gated; reviewers will
  reject without working credentials).

## Verifying the Android release artifact

Building successfully does **not** prove it was signed with the release key —
the Gradle config falls back to debug. Check the certificate explicitly:

```
flutter build appbundle --release
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
# or, for the bundle:
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

The printed certificate must be your release key, not `CN=Android Debug`.
