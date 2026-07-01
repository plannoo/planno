# Flutter ↔ Backend Alignment Notes
# Generated from analysis of the Flutter codebase

---

## 🔴 CRITICAL — Will break at runtime if not fixed

### 1. Enum serialization mismatch (Absence)

Flutter's `AbsenceModel.fromJson` does:
```dart
type: AbsenceType.values.firstWhere((e) => e.name == json['type']),
```
`enum.name` in Dart returns the camelCase member name, so:

| Flutter expects in JSON | Backend currently returns |
|---|---|
| `"vacation"` | `"VACATION"` |
| `"sickLeave"` | `"SICK_LEAVE"` |
| `"personalDay"` | `"PERSONAL_DAY"` |
| `"training"` | `"TRAINING"` |
| `"pending"` | `"PENDING"` |
| `"approved"` | `"APPROVED"` |
| `"rejected"` | `"REJECTED"` |

**Fix — add a serializer in the backend absence route:**
```typescript
// In your absence route response, map the enum before sending:
function toFlutterType(t: string): string {
  const map: Record<string, string> = {
    VACATION: 'vacation', SICK_LEAVE: 'sickLeave',
    PERSONAL_DAY: 'personalDay', TRAINING: 'training',
    UNPAID: 'unpaid', STANDBY: 'standby',
  };
  return map[t] ?? t.toLowerCase();
}
function toFlutterStatus(s: string): string {
  return s.toLowerCase(); // PENDING→pending, APPROVED→approved, REJECTED→rejected
}
```
Or fix it Flutter-side by adding case-insensitive matching in `fromJson`.

---

### 2. Shift JSON key casing

`ShiftModel.fromJson` in Flutter reads camelCase keys:
```dart
startTime: DateTime.parse(json['startTime'] as String),
endTime:   DateTime.parse(json['endTime']   as String),
```
But the backend `Shift` model uses snake_case Prisma field names.

**Fix — in the shift route response, rename the fields:**
```typescript
// Transform before sending:
{
  id, role, date,
  startTime: shift.startTime.toISOString(),  // not start_time
  endTime:   shift.endTime.toISOString(),    // not end_time
  location:  shift.location?.name ?? '',
  address:   shift.location?.address ?? shift.shiftAddress ?? '',
  latitude:  shift.location?.latitude ?? 0,
  longitude: shift.location?.longitude ?? 0,
  notes:     shift.comment ?? null,
}
```

---

### 3. User model field names

`UserModel.fromJson` reads:
```dart
firstName: json['first_name'],
lastName:  json['last_name'],
avatarUrl: json['avatar_url'],
assignedLocationIds: json['assigned_location_ids'],
```
Prisma returns `firstName` (camelCase). The `GET /api/users/me` route must
transform to snake_case before responding.

---

### 4. Auth response shape

`AuthProvider.signIn` reads:
```dart
final accessToken  = body['access_token']  as String;
final refreshToken = body['refresh_token'] as String;
```
And the refresh endpoint sends `{ refresh_token: refreshToken }`.
Make sure your auth routes return exactly these keys (snake_case).

---

## 🟡 IMPORTANT — Missing backend endpoints used by the Flutter app

### Clock break endpoints

The `TimeClockScreen` and `ClockProvider` call `startBreak()` / `endBreak()` but:
- `ApiConfig` only has `/api/clock/in` and `/api/clock/out`
- `ClockRepository` interface has no break methods

**Add to `ApiConfig` in Flutter (or confirm backend routes):**
```dart
static const String breakStart = '/api/clock/break/start';
static const String breakEnd   = '/api/clock/break/end';
```
Our backend already has these routes (`POST /api/clock/break/start`, `/break/end`). ✅

### Clock endpoint paths

Flutter `ApiConfig` uses:
- `/api/clock/in`
- `/api/clock/out`

Our backend routes are mounted at `/api/clock` with paths `/in` and `/out`.
Confirm the full URLs match: `POST /api/clock/in` and `POST /api/clock/out`. ✅

### Location override request

`TimeClockScreen._showOverrideRequestDialog` sends an override request but has no
backend call (marked `TODO`). Add:
```dart
static const String clockOverride = '/api/clock/override-request';
```
Backend needs: `POST /api/clock/override-request { userId, lat, lng, reason }`.

---

## 🟢 NEW endpoints — add to Flutter's ApiConfig

All of these are built on the backend but not yet wired into Flutter:

```dart
// Announcements (dashboard panel)
static const String announcements       = '/api/announcements';
static const String announcementUnread  = '/api/announcements/unread-count';

// Timesheets
static const String timesheetWeek   = '/api/timesheets/me/week';
static const String timesheetMonth  = '/api/timesheets/me/month';

// Absences
static const String absenceCalendar = '/api/absences/calendar';
static const String absenceCreate   = '/api/absences/calendar';  // POST

// Availability
static const String availability    = '/api/availabilities/me';

// Documents (Meine Dokumente)
static const String myDocuments     = '/api/documents/me';

// Terminal
static const String terminalSession = '/api/terminal/session';
static const String terminalClock   = '/api/terminal/clock';

// Reports (managers only)
static const String reportDetailed  = '/api/reports/detailed';
static const String reportSummed    = '/api/reports/summed';
```

---

## 🔧 Mock repositories that need replacing

| Repository | Current implementation | What to wire to |
|---|---|---|
| `MockClockRepository` | Fake delay | `POST /api/clock/in`, `/out`, `/break/start`, `/break/end` |
| `MockAbsenceRepository` | Hardcoded data | `GET /api/absences/list/detailed`, `POST /api/absences/calendar` |
| `MockShiftRepository` | Hardcoded data | `GET /api/shifts` |

`ApiUserRepository` is already real. ✅

---

## 📋 Flutter model gaps

### AbsenceModel missing `note` field
`AbsenceModel` has `reason` field but the absence creation modal in Image 3 sends
a `comment`. Backend stores it as `note`. Either align the field name or map in
the route.

### ActivityModel — icon/color fields
`ActivityModel.fromJson` stores `icon` as `codePoint` int string and `color` as
int. The backend `Activity` table doesn't store these — they are UI-only
presentation values that the Flutter app derives from the activity `type`.
**Do not try to store icon/color on the backend.** Let Flutter determine them
based on the `type` field:
```dart
// In Flutter, derive icon/color from type, not from JSON
factory ActivityModel.fromBackend(Map<String, dynamic> json) {
  final type = json['type'] as String; // 'CLOCK_IN', 'CLOCK_OUT', etc.
  return ActivityModel(
    id:    json['id'],
    type:  _parseType(type),
    title: _titleFor(type),
    icon:  _iconFor(type),
    color: _colorFor(type),
    date:  DateTime.parse(json['timestamp']),
    time:  DateTime.parse(json['timestamp']),
  );
}
```

### Shift `working_days` computation
`AbsenceModel` has `workingDays: json['working_days'] as int`. 
The backend `Absence` model doesn't store `working_days` directly — it computes
it from `startDate`, `endDate`, excluding weekends and public holidays.
Add it to the absence response:
```typescript
// In absence route response:
{
  ...absence,
  working_days: effectiveDays(absence.startDate, absence.endDate, holidays),
}
```

---

## 📦 pubspec.yaml — packages to add for new features

```yaml
dependencies:
  # For the time clock terminal QR scan (mobile check-in)
  mobile_scanner: ^5.0.0      # scan QR codes
  # OR
  qr_flutter: ^4.1.0          # display QR codes in-app

  # For file attachments (absence/shift)
  file_picker: ^8.0.0
  http_parser: ^4.0.2         # for multipart upload

  # For push notifications (announcements, shift updates)
  firebase_messaging: ^15.0.0
  firebase_core: ^3.0.0

  # For image/avatar upload
  image_picker: ^1.0.0

  # For offline support / caching
  hive_flutter: ^1.1.0        # or drift / isar
```

---

## 🌐 Locale-aware API calls

The Flutter app supports German and English (`LocaleProvider`).
Send the user's locale to the backend so error messages and labels can be
returned in the right language:

```dart
// In ApiClient, read the locale and set the Accept-Language header:
final locale = await PrefsService.getLanguageCode() ?? 'en';
options.headers['Accept-Language'] = locale;
```

Backend middleware:
```typescript
app.use((req, res, next) => {
  req.locale = req.headers['accept-language']?.split('-')[0] ?? 'en';
  next();
});
```

---

## Summary checklist

- [ ] Map Prisma/TypeScript enum values → Flutter camelCase in all absence responses
- [ ] Transform shift JSON to camelCase (`startTime`, `endTime`, etc.)
- [ ] Transform user JSON to snake_case (`first_name`, `last_name`, `avatar_url`, `assigned_location_ids`)  
- [ ] Add `working_days` to absence API response
- [ ] Add `POST /api/clock/override-request` endpoint
- [ ] Replace MockClockRepository with real ApiClockRepository in Flutter
- [ ] Replace MockAbsenceRepository with real ApiAbsenceRepository in Flutter
- [ ] Replace MockShiftRepository with real ApiShiftRepository in Flutter
- [ ] Add new ApiConfig entries for announcements, timesheets, documents, terminal
- [ ] Add `breakStart`/`breakEnd` methods to ClockRepository interface
- [ ] Do NOT store icon/color in backend Activity table — derive in Flutter from `type`
- [ ] Send `Accept-Language` header from Flutter for locale-aware responses
