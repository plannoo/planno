# Wrenta — Architecture Summary

Multi-location employee time tracking & scheduling app (Flutter, Provider pattern).

---

## Stack

| Layer | Choice |
|-------|--------|
| State | `Provider` (ChangeNotifier) |
| HTTP | `Dio` singleton with JWT interceptor + auto-refresh |
| Local | `SharedPreferences` (tokens, session, locale) |
| Push | `firebase_messaging` + `flutter_local_notifications` |
| Maps | `geolocator` (GPS geofence) |
| i18n | Custom `AppLocalizations` (EN + DE, ~230 keys) |

## Directory Layout

```
lib/
├── main.dart                         # Entry — route resolution, MultiProvider
├── core/
│   ├── network/
│   │   ├── api_client.dart           # Dio singleton, JWT interceptor, 401→refresh
│   │   ├── api_config.dart           # Endpoint path constants
│   │   └── api_exceptions.dart       # Sealed exception hierarchy
│   ├── services/
│   │   ├── prefs_service.dart        # Static SharedPreferences wrapper
│   │   └── notification_service.dart # FCM init, token registration, foreground/background routing
│   ├── l10n/
│   │   ├── app_localizations.dart    # ~230 translation keys, .of(context)
│   │   ├── app_en.arb
│   │   └── app_de.arb
│   ├── theme/
│   │   ├── app_colors.dart           # Full palette (primary, slate, semantic, status)
│   │   ├── app_text_styles.dart      # Typography (h4–overline, body, label, caption)
│   │   ├── app_dimensions.dart       # Spacing, radius, icon, button, avatar sizes
│   │   └── app_theme.dart            # Material 3 ThemeData
│   └── utils/
│       ├── date_formatter.dart       # Time, duration, distance formatting
│       └── validators.dart           # required, email, password, minLength
│
├── models/                           # (12 files)
│   ├── user_model.dart               # id, email, firstName, role, avatarUrl, assignedLocationIds
│   ├── shift_model.dart              # id, role, date, startTime, endTime, location, duration, breakMinutes
│   ├── absence.dart                  # AbsenceModel, AbsenceType (6), AbsenceStatus (3)
│   ├── absence_summary.dart          # usedDays, totalDays, remainingDays, usagePercentage
│   ├── activity_model.dart           # ActivityModel — clock event log entries
│   ├── announcement_model.dart       # AnnouncementModel, AnnouncementListResult
│   ├── chat_model.dart               # ChatMessage, Conversation
│   ├── notification_model.dart       # NotificationModel + fromJson/fromFcmData, 7 categories
│   ├── team_member_model.dart        # TeamMemberModel + MemberShiftStatus enum
│   ├── location.dart                 # WorkLocation — lighter model (fromJson/toJson)
│   ├── work_location_model.dart      # WorkLocationModel — heavier, with distanceTo/isWithinWorkZone
│   └── workplace_location.dart       # WorkplaceLocation + LocationStatus + LocationStatusType (5)
│
├── repositories/                     # (8 files — abstract interface + impls)
│   ├── user_repository.dart          # ApiUserRepository + StubUserRepository
│   ├── clock_repository.dart         # ApiClockRepository + MockClockRepository + TodayActivities response types
│   ├── absence_repository.dart       # ApiAbsenceRepository + MockAbsenceRepository
│   ├── shift_repository.dart         # ApiShiftRepository + MockShiftRepository
│   ├── schedule_repository.dart      # MockScheduleRepository + CancelToken/CancelledError
│   ├── notification_repository.dart  # NotificationRepositoryImpl + NoOpNotificationRepo
│   ├── announcement_repository.dart  # ApiAnnouncementRepository + MockAnnouncementRepository
│   └── device_token_repository.dart  # DeviceTokenRepositoryImpl
│
├── providers/                        # (10 files — ChangeNotifier state managers)
│   ├── app_provider.dart             # AppProviders — MultiProvider wiring (FutureBuilder init)
│   ├── auth_provider.dart            # signIn / signOut / tryRestoreSession
│   ├── clock_provider.dart           # clockIn/Out, break start/end, GPS geofence, session timer, restore state
│   ├── schedule_provider.dart        # Team + My Shifts tabs, cancel-token pattern, weekly hours
│   ├── absence_provider.dart         # Load absences, submit, summary
│   ├── dashboard_provider.dart       # Greeting, announcements, quick actions data
│   ├── notifications_provider.dart   # Cursor pagination, FCM subscription, optimistic markRead/markAllRead
│   ├── announcement_provider.dart    # Announcement list + unread count
│   ├── chat_provider.dart            # Conversations + messages (mock data)
│   └── locale_provider.dart          # Locale switching, persisted to PrefsService
│
├── pages/                            # (18 files)
│   ├── navigation_shell.dart         # 5-tab IndexedStack (Dashboard, Schedule, Clock, Chat, Profile)
│   ├── onboarding/onboarding.dart    # 3-page carousel → login on skip/home on complete
│   ├── auth/login_page.dart          # Email/password form → NavigationShell
│   ├── auth/signup_page.dart         # Registration form → NavigationShell
│   ├── dashboard/dashboard.dart      # Greeting, bell badge, quick actions, announcements
│   ├── schedule/teamschedule.dart    # Team + My Shifts tabs, calendar, location filter
│   ├── schedule/myschedule.dart      # CompactCalendar + shift list + weekly progress
│   ├── time_tracking/clockin_page.dart # Clock face, location card, action buttons, activity log
│   ├── time_tracking/time_account_page.dart  # Static time balance (not wired to provider)
│   ├── chat/chat_page.dart           # Conversation list + message thread (mock data)
│   ├── notification/notification_page.dart # Grouped list, swipe-dismiss, mark all read
│   ├── profile/menu_page.dart        # Profile edit, work details, documents, language, logout
│   ├── profile/availability_page.dart # Day-by-day availability toggles (static state)
│   ├── profile/language_settings_tile.dart  # Language picker tile (reused)
│   ├── absence/absence_page.dart     # Summary card + tabs (Upcoming/Past/All)
│   ├── absence/new_absence_page.dart # Type, date range, reason form
│   ├── absence/confirmation_page.dart # Success screen after submission
│   └── absence/request_history.dart  # Tabbed absences + shift changes, search
│
├── widgets/                          # (22 files)
│   ├── clockIn/ (7 files)            # ClockFaceCard, LocationCard, LocationStatusWidget, etc.
│   ├── absence/ (4 files)            # AbsenceSummaryCard, AbsenceCard, expandable variants
│   ├── teams/ (5 files)              # WeeklyHoursCard (bar chart), MyShiftCard, CompactCalendar, etc.
│   ├── common/ (4 files)             # AnnouncementCard, SectionHeader, QuickActionTile, CustomAppBar
│   ├── Buttons/ (5 files)            # PrimaryButton, SecondaryButton, DestructiveButton, etc.
│   ├── input/ (2 files)              # CustomTextField, DatePickerField
│   ├── layouts/notification_tile.dart # Dismissible notification row
│   └── unspecified.dart              # Catch-all (some duplicated constants)
```

---

## Data Flow

```
Pages/Widgets  ──context.read/watch()──>  Providers (ChangeNotifier)
                                                │
                                        async method calls
                                                │
                                                v
                                        Repositories
                                           │       │
                                     Api*Impl   Mock*Impl
                                     (Dio HTTP)  (fake)
```

### Example: Clock In

1. User taps **Clock In** → `ClockPage._handleClockIn()`
2. `context.read<ClockProvider>().clockIn()`
3. ClockProvider guards: workplace loaded? GPS ready? Within geofence?
4. Calls `_repo.clockIn(lat, lng, distance, accuracy)`
5. On success → sets state, starts 1s `Timer.periodic`, adds activity, returns `null`
6. On failure → rolls back state, returns error string
7. UI shows snackbar (success) or dialog (geofence → override) or snackbar (other error)

---

## Navigation

```
main.dart
  └── AppProviders (MultiProvider + FutureBuilder for LocaleProvider + NotificationService)
       └── MaterialApp
            ├── /onboarding  →  onboarding.dart (3-page carousel)
            ├── /login       →  login_page.dart
            ├── /signup      →  signup_page.dart
            └── /home        →  NavigationShell (5-tab IndexedStack)
                                  ├── Tab 0: Dashboard
                                  ├── Tab 1: Team Schedule
                                  ├── Tab 2: Clock
                                  ├── Tab 3: Chat
                                  └── Tab 4: Profile
```

---

## Provider ↔ Repository Wiring

| Provider | Repository | Pages |
|----------|-----------|-------|
| `AuthProvider` | `UserRepository` | Login, Signup, main.dart route guard |
| `ClockProvider` | `ClockRepository` | ClockPage |
| `ScheduleProvider` | `ScheduleRepository` + `ShiftRepository` | TeamSchedulePage, MySchedulePage |
| `AbsenceProvider` | `AbsenceRepository` | AbsencePage, NewAbsencePage, RequestHistory |
| `DashboardProvider` | `ShiftRepository` + `AnnouncementRepository` | DashboardPage |
| `ChatProvider` | *(mock data internals)* | ChatPage |
| `NotificationsProvider` | `NotificationRepository` (no-op when logged out) | NotificationPage, DashboardPage (bell badge) |
| `AnnouncementProvider` | `AnnouncementRepository` | DashboardPage |
| `LocaleProvider` | `PrefsService` | MenuPage, LanguageSettingsTile |

---

## Current State

### Fully Wired
- Auth (login, signup, session restore, logout with FCM deregister)
- Clock in/out (GPS geofence, break tracking, activity log, pessimistic API, session state restore)
- Schedule (team + my shifts, weekly hours, cancel-token pattern)
- Absence (list, summary, submit)
- Notifications (cursor pagination, FCM foreground subscription, optimistic mark read)
- Announcements (list, unread count)
- Locale switching (EN/DE, persisted)
- Push notifications (FCM token registration, background handler, notification tap routing)

### Partial / Mock-Only
- **Chat** — UI complete, mock data, no repository
- **Time Account** — static UI, no provider
- **Availability** — local state only, no persistence
- **Profile edit** — form UI, no update API call
- **Change Password** — sheet UI, no API
- **Dark Mode** — toggle UI only
- `MockClockRepository`, `MockAbsenceRepository`, `MockShiftRepository` — need `Api*` replacements

### Tech Debt
- 3 overlapping location models (`WorkLocation`, `WorkLocationModel`, `WorkplaceLocation`)
- `widgets/unspecified.dart` duplicates constants/widgets from dedicated files
- Legacy `core/theme.dart` (24 lines) alongside `core/theme/` subdirectory
