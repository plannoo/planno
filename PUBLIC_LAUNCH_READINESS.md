# Public Launch Readiness — Wrenta (Flutter app + backend + web)

_Audit date: 2026-07-02_

Covers three repos:
- **Flutter app** — `C:\FlutterApps\Aplano` (package `com.wrenta.app`)
- **Backend** — `C:\FlutterApps\planno_backend` (Render, Neon Postgres)
- **Web app** — `C:\web\aplano` (React 18 + TS + Vite, admin/web counterpart)

---

## Do this in the next 5 minutes (data-loss risk, zero cost)

**Commit the web app.** Almost the entire `C:\web\aplano` codebase — the real API
integration layer, auth, and routing — is sitting uncommitted in the working tree.
Git history only has 3 commits and doesn't reflect any of this. One bad `git clean`,
a crashed machine, or an accidental `git checkout .` and it's gone. Commit it now,
before anything else.

---

## Real blockers — backend (`planno_backend`)

1. **Uploaded files will vanish.** `STORAGE_BACKEND` defaults to local disk
   (`src/config/env.ts:75-78`), and `render.yaml` never configures S3 or a
   persistent disk mount. Render's free/starter tiers wipe local disk on every
   redeploy. Every shift attachment, absence doc, and profile upload a user
   submits will silently disappear the next time you deploy. Needs S3 (env vars
   already exist for it — `AWS_REGION`, `S3_BUCKET`, etc. — just unused) before
   real users touch it.

2. **Free tier cold starts are a dealbreaker for real users.** Render's free plan
   (`render.yaml:6`, `plan: free`) spins down after ~15 min idle; first request
   after that takes 30-60s. That's your login screen randomly hanging for real
   customers. Needs at least a paid Render plan (or equivalent).

3. **No monitoring at all.** No Sentry, no uptime checks, nothing beyond stdout
   logs. If the backend goes down or starts 500ing, you find out when a customer
   emails you.

4. **No verified backup strategy.** DB is on Neon — Neon has its own PITR on paid
   tiers, but nothing in the repo confirms it's enabled or documents a recovery
   plan if data gets corrupted.

5. **CORS is looser than it should be.** `app.ts:61-71` uses `credentials: true`
   with an effectively-any-origin policy (`ALLOWED_ORIGINS=*` in `render.yaml`).
   Actual exploitability is low since auth is Bearer-token-only (no cookies), but
   it's still worth tightening to real domains before launch as basic hygiene.

**Confirmed OK / good state:**
- 243/243 tests passing, 21/21 suites.
- Secrets only ever read from `process.env`, zod-validated, placeholder secrets
  actively rejected.
- Rate limiting is reasonable (global + per-auth-endpoint + per-user).
- Email sending is real (Resend SDK), not a stub.
- Prisma migration drift from earlier notes is **already resolved** (fixed
  same-day as it was flagged) — `prisma migrate status` reports schema is up to
  date against the live Neon DB.

---

## Real blockers — Flutter app

1. **Release APK is signed with the debug keystore**
   (`android/app/build.gradle.kts:38-42`). Google Play will flatly reject this on
   upload. Needs a real keystore + signing config.

2. **"Privacy Policy" and "Terms of Service" on the signup screen are fake.**
   (`lib/pages/auth/signup_page.dart:241-257`) — plain styled text with no link,
   no route, nothing behind them. Both app stores require a real, working privacy
   policy — for an app touching GPS location and biometric auth, this is close to
   an automatic rejection.

3. **Account deletion is explicitly disabled by design.**
   (`lib/pages/profile/menu_page.dart:1417-1418` — code comment: "Account
   deletion is intentionally not exposed in the app... that's an admin/web
   operation.") Apple requires in-app self-service deletion for any app with
   account creation — this is a near-guaranteed rejection on iOS specifically.

4. **A real crash bug, not just a review issue.** Biometric clock-in uses Face ID
   via `local_auth`, but `ios/Runner/Info.plist` is missing
   `NSFaceIDUsageDescription`. On any iPhone X or newer, tapping "Clock In" with
   biometrics enabled will crash the app outright.

5. **Dashboard shows fake data.** `lib/providers/dashboard_provider.dart:42` —
   `_weeklyHours = 32.5; // TODO: fetch from time-tracking repository`. Every
   user's weekly-hours stat is hardcoded, never wired to real data.

**Should-fix (not launch-blocking):**
- No crash reporting (Sentry/Crashlytics) — Firebase is already wired, so
  Crashlytics is a near-zero-cost add.
- Missing `POST_NOTIFICATIONS` permission on Android — notifications silently
  fail to show on Android 13+.
- Confirm `chatComingSoon` / `notificationsComingSoon` / `profileComingSoon` /
  `teamScheduleComingSoon` l10n strings are truly unreachable dead code, not
  exposed anywhere.

**Confirmed OK / good state:**
- `flutter analyze` clean.
- No hardcoded secrets beyond expected public Firebase client keys.
- iOS is genuinely scaffolded (bundle id, `GoogleService-Info.plist`, usage
  strings for camera/photo-library/location) — not vaporware, just untested on a
  real biometric device.

---

## Real blockers — web app (`C:\web\aplano`)

The app is much further along than its own README claims — the README says "no
backend exists yet, mock data only," which is false; there's a full 20+ module
API layer wired to the real backend with token refresh and route guards. The
docs are just stale and should be updated to avoid misleading anyone onboarding.

1. **8 of 19 tests are failing**, all in the Time Clock Terminal component — look
   like real behavioral bugs, not flaky tests.
2. **Not deployed anywhere.** No Vercel/Netlify/Docker config, no live URL. Right
   now this app exists only on a local machine.
3. Once committed and deployed, needs its production `VITE_API_URL` pointed at
   the real backend and confirmed against the backend's CORS allowlist.

**Should-fix:**
- 2.3MB main JS bundle (684KB gzip), no code-splitting — Vite itself flags this.
- Audit error/loading-state coverage on the ~28 components that don't reference
  `catch`/loading state.

---

## Realistic read

This is not a "flip a switch" launch. Three genuinely separate pieces of work:

- **Backend infra hardening** (S3 storage, paid tier, monitoring, backup
  verification) — the most consequential gap because it risks real customer data
  loss, and it's mostly configuration, not code. Realistically a day or two.
- **Store compliance for the Flutter app** (signing, privacy policy page,
  account deletion flow, the Face ID crash fix) — a few days of focused work, but
  genuinely required before either store will accept the app.
- **Web app** — needs its failing tests fixed and a deployment pipeline stood up;
  the app itself is more complete than its docs suggest.

None of this is "start over" territory — it's a defined, finishable punch list.
But "ready for the public" realistically means **1-2 weeks of focused work**, not
a same-day build. The highest-leverage fix first is the S3/file-storage issue,
because that one silently loses real customer data if you launch without it.
