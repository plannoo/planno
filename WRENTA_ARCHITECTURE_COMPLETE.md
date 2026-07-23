# Wrenta — Complete Architectural & System Design Document

> **Generated:** 2026-06-03  
> **Purpose:** AI-ready comprehensive reference for the entire Wrenta codebase  
> **Version:** 1.0.0+1  
> **Tech Stack:** Flutter 3.35+ / Dart 3.10.4+ / Provider / Dio / Firebase

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [System Architecture](#2-system-architecture)
3. [Directory Structure](#3-directory-structure)
4. [Data Models](#4-data-models)
5. [State Management (Providers)](#5-state-management)
6. [Repository Layer](#6-repository-layer)
7. [API / Network Layer](#7-api--network-layer)
8. [Presentation Layer (Pages)](#8-presentation-layer)
9. [Widgets Subsystem](#9-widgets-subsystem)
10. [Theme & Design System](#10-theme--design-system)
11. [Localization / i18n](#11-localization--i18n)
12. [Services](#12-services)
13. [Routing & Navigation](#13-routing--navigation)
14. [Push Notifications (FCM)](#14-push-notifications)
15. [Platform Configuration](#15-platform-configuration)
16. [Testing](#16-testing)
17. [Known Tech Debt](#17-known-tech-debt)
18. [Planned Migrations](#18-planned-migrations)
19. [API Endpoints Reference](#19-api-endpoints-reference)
20. [Data Flow Diagrams](#20-data-flow-diagrams)

---

## 1. Project Overview

| Property | Value |
|---|---|
| **App Name** | Wrenta |
| **Purpose** | Multi-location employee time tracking, shift scheduling, absence management, team chat, and push notifications |
| **Target Platforms** | iOS, Android, Web (PWA) |
| **SDK** | Dart `>=3.10.4 <4.0.0`, Flutter `>=3.35.0` (stable) |
| **State Management** | Provider (`ChangeNotifier` + `ChangeNotifierProxyProvider`) |
| **HTTP Client** | Dio (singleton with JWT interceptor) |
| **Local Storage** | SharedPreferences (no encryption — tokens stored in plaintext) |
| **Push Notifications** | Firebase Cloud Messaging (FCM) + `flutter_local_notifications` |
| **Geolocation** | `geolocator` package for GPS-based clock-in geofence verification |
| **Localization** | Custom `AppLocalizations` (English + German, ~232 keys) |
| **Backend Status** | Auth fully wired to real API; all other features use mock repositories |
| **Build ID** | `com.example.wrenta` (placeholder — needs replacement) |

---

## 2. System Architecture

### 2.1 Layered Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                             │
│                                                                   │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────────┐  │
│  │  Pages (18)  │  │  Widgets (22)│  │  Navigation Shell     │  │
│  │  - Dashboard │  │  - Buttons   │  │  IndexedStack (5-tab) │  │
│  │  - Schedule  │  │  - Cards     │  │  BottomNavigationBar  │  │
│  │  - Clock     │  │  - Inputs    │  │                       │  │
│  │  - Absence   │  │  - Layouts   │  └────────────────────────┘  │
│  │  - Chat      │  └──────────────┘                              │
│  │  - Profile   │                                                │
│  └─────────────┘                                                 │
│         │ read / watch via Provider                              │
├─────────┼────────────────────────────────────────────────────────┤
│         ▼                                                        │
│                    STATE MANAGEMENT (PROVIDERS)                   │
│                                                                   │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌──────────────────┐ │
│  │   Auth    │ │   Clock   │ │ Schedule  │ │  Dashboard       │ │
│  │  Provider │ │  Provider │ │ Provider  │ │  Provider        │ │
│  ├───────────┤ ├───────────┤ ├───────────┤ ├──────────────────┤ │
│  │  Absence  │ │   Chat    │ │Notificatns│ │  Announcement    │ │
│  │  Provider │ │  Provider │ │ Provider  │ │  Provider        │ │
│  ├───────────┤ └───────────┘ └───────────┘ └──────────────────┘ │
│  │  Locale   │                                                  │
│  │  Provider │  ┌─────────────────────────────────────────┐     │
│  └───────────┘  │  AppProviders (MultiProvider wiring)    │     │
│                 └─────────────────────────────────────────┘     │
├──────────────────────────────────────────────────────────────────┤
│                    REPOSITORY LAYER                               │
│                                                                   │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌───────────┐ │
│  │    User     │ │    Clock    │ │   Shift     │ │  Absence  │ │
│  │  Repository │ │  Repository │ │  Repository │ │ Repository│ │
│  │  (real API) │ │  (mock)     │ │  (mock)     │ │  (mock)   │ │
│  ├─────────────┤ ├─────────────┤ ├─────────────┤ ├───────────┤ │
│  │  Schedule   │ │ Notification│ │ Announcement │ │   Device  │ │
│  │  Repository │ │  Repository │ │  Repository  │ │   Token   │ │
│  │  (mock)     │ │  (NoOp/HTTP)│ │  (mock)      │ │ Repository│ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └───────────┘ │
│         │              │              │              │           │
├─────────┼──────────────┼──────────────┼──────────────┼───────────┤
│         ▼              ▼              ▼              ▼           │
│                       DATA LAYER                                 │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐      │
│  │                 ApiClient (Dio Singleton)               │      │
│  │  • JWT Bearer Auth Interceptor                         │      │
│  │  • Auto token refresh on 401                           │      │
│  │  • Typed ApiException hierarchy                        │      │
│  │  • Request/response logging                            │      │
│  └────────────────────────────────────────────────────────┘      │
│                         +                                        │
│  ┌────────────────────────────────────────────────────────┐      │
│  │              SharedPreferences (PrefsService)           │      │
│  │  • Auth tokens (access + refresh)                      │      │
│  │  • Session/profile data                                │      │
│  │  • Locale preference                                   │      │
│  │  • Onboarding flag                                     │      │
│  └────────────────────────────────────────────────────────┘      │
│                         +                                        │
│  ┌────────────────────────────────────────────────────────┐      │
│  │              Firebase Cloud Messaging                   │      │
│  │  • FCM token registration                              │      │
│  │  • Foreground/background message handling              │      │
│  │  • Local notification display                          │      │
│  └────────────────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Architecture Pattern

**Current:** Provider + Repository pattern with separated interface/mock/real implementations.

- **Presentation** reads state via `context.watch<T>()` and `context.read<T>()`
- **State Management** (`ChangeNotifier` providers) orchestrate business logic
- **Repository Layer** abstracts data sources behind interfaces
- **Data Layer** consists of `ApiClient` (HTTP), `PrefsService` (local storage), and Firebase

### 2.3 Dependency Injection

All providers are wired in `AppProviders` (lib/providers/app_provider.dart) as a `MultiProvider` tree:

```
AppProviders
├── Provider<ClockRepository> → MockClockRepository
├── Provider<AbsenceRepository> → MockAbsenceRepository
├── Provider<ShiftRepository> → MockShiftRepository
├── Provider<UserRepository> → ApiUserRepository (REAL)
├── Provider<ScheduleRepository> → MockScheduleRepository
├── Provider<DeviceTokenRepository> → DeviceTokenRepositoryImpl
├── ChangeNotifierProxyProvider2<UserRepository, DeviceTokenRepository, AuthProvider>
├── ChangeNotifierProvider<LocaleProvider> → from FutureBuilder
├── ChangeNotifierProxyProvider<AuthProvider, NotificationsProvider>
├── ChangeNotifierProvider<ChatProvider>
├── ChangeNotifierProxyProvider<ScheduleRepository, ScheduleProvider>
├── ChangeNotifierProxyProvider<ShiftRepository, DashboardProvider>
├── ChangeNotifierProxyProvider<ClockRepository, ClockProvider>
└── ChangeNotifierProxyProvider<AbsenceRepository, AbsenceProvider>
```

**Initialization flow** (inside `AppProviders`):
1. `LocaleProvider.create()` — loads persisted locale from SharedPreferences
2. `NotificationService.instance.init()` — sets up FCM, registers token
3. `AuthProvider.tryRestoreSession()` — attempts silent login via stored refresh token
4. All providers load their data on first access

---

## 3. Directory Structure

```
C:\FlutterApps\Wrenta\
│
├── .gitignore
├── .metadata                          # Flutter metadata (channel: stable, revision: f6ff1529fd)
├── analysis_options.yaml              # Lint rules (package:flutter_lints/flutter.yaml)
├── WRENTA_ARCHITECTURE.md             # Existing brief architecture doc
├── FLUTTER_BACKEND_ALIGNMENT.md       # Backend JSON alignment issues
├── pubspec.yaml                       # Dependency manifest
├── pubspec.lock                       # Locked dependency versions
├── README.md                          # 445-line project documentation
│
├── android/
│   ├── app/
│   │   ├── build.gradle.kts           # Package: com.example.wrenta, AGP 8.11.1, Java 17, Kotlin 2.2.20
│   │   └── src/                       # Native Android source
│   ├── build.gradle.kts               # Root Gradle config
│   ├── gradle.properties
│   ├── gradle/wrapper/
│   ├── settings.gradle.kts
│   └── local.properties
│
├── ios/
│   ├── Flutter/
│   ├── Runner/
│   │   ├── AppDelegate.swift
│   │   ├── Info.plist                 # Location, photo library, file access permissions
│   │   ├── Assets.xcassets/
│   │   └── Base.lproj/
│   ├── Runner.xcodeproj/
│   ├── Runner.xcworkspace/
│   └── RunnerTests/
│
├── lib/
│   ├── main.dart                      # App entry point + route resolution
│   │
│   ├── core/
│   │   ├── l10n/
│   │   │   ├── app_en.arb             # 504 English strings
│   │   │   ├── app_de.arb             # 167 German strings
│   │   │   └── app_localizations.dart # 954-line custom i18n (EN + DE)
│   │   │
│   │   ├── network/
│   │   │   ├── api_client.dart        # Dio singleton + JWT interceptor + token refresh
│   │   │   ├── api_config.dart        # All endpoint path constants
│   │   │   └── api_exceptions.dart    # Sealed exception hierarchy
│   │   │
│   │   ├── services/
│   │   │   ├── notification_service.dart  # FCM setup + foreground/background routing
│   │   │   └── prefs_service.dart         # SharedPreferences wrapper
│   │   │
│   │   ├── theme/
│   │   │   ├── app_colors.dart        # Full color palette (primary, neutral, semantic)
│   │   │   ├── app_dimensions.dart    # Spacing, radius, icon sizes, component dimensions
│   │   │   ├── app_text_styles.dart   # Typography scale (display → overline)
│   │   │   └── app_theme.dart         # Material 3 ThemeData (light only)
│   │   │
│   │   ├── theme.dart                 # Legacy duplicate (minor differences)
│   │   │
│   │   └── utils/
│   │       ├── date_formatter.dart    # Time/duration/distance formatting
│   │       └── validators.dart        # Form validation helpers
│   │
│   ├── models/
│   │   ├── absence.dart               # AbsenceModel + AbsenceType + AbsenceStatus
│   │   ├── absence_summary.dart       # AbsenceSummaryModel (quota tracking)
│   │   ├── activity_model.dart        # ActivityModel + ActivityType
│   │   ├── announcement_model.dart    # AnnouncementModel
│   │   ├── chat_model.dart            # ChatMessage + Conversation
│   │   ├── location.dart              # WorkLocation (DB-aligned, lighter)
│   │   ├── notification_model.dart    # NotificationModel + NotificationCategory
│   │   ├── shift_model.dart           # ShiftModel (full schedule entry)
│   │   ├── team_member_model.dart     # TeamMemberModel + MemberShiftStatus
│   │   ├── user_model.dart            # UserModel (auth profile)
│   │   ├── work_location_model.dart   # WorkLocationModel (geofence-aware)
│   │   └── workplace_location.dart    # WorkplaceLocation (3rd variant)
│   │
│   ├── pages/
│   │   ├── absence/
│   │   │   ├── absence_page.dart
│   │   │   ├── confirmation_page.dart
│   │   │   ├── new_absence_page.dart
│   │   │   └── request_history.dart
│   │   │
│   │   ├── auth/
│   │   │   ├── login_page.dart
│   │   │   └── signup_page.dart
│   │   │
│   │   ├── chat/
│   │   │   └── chat_page.dart
│   │   │
│   │   ├── dashboard/
│   │   │   └── dashboard.dart
│   │   │
│   │   ├── notification/
│   │   │   └── notification_page.dart
│   │   │
│   │   ├── onboarding/
│   │   │   └── onboarding.dart
│   │   │
│   │   ├── profile/
│   │   │   ├── availability_page.dart
│   │   │   ├── language_settings_tile.dart
│   │   │   └── menu_page.dart
│   │   │
│   │   ├── schedule/
│   │   │   ├── myschedule.dart
│   │   │   └── teamschedule.dart
│   │   │
│   │   ├── time_tracking/
│   │   │   ├── clockin_page.dart
│   │   │   └── time_account_page.dart
│   │   │
│   │   └── navigation_shell.dart      # 5-tab IndexedStack shell
│   │
│   ├── providers/
│   │   ├── absence_provider.dart
│   │   ├── announcement_provider.dart
│   │   ├── app_provider.dart          # MultiProvider wiring + async init
│   │   ├── auth_provider.dart
│   │   ├── chat_provider.dart
│   │   ├── clock_provider.dart
│   │   ├── dashboard_provider.dart
│   │   ├── locale_provider.dart
│   │   ├── notifications_provider.dart
│   │   └── schedule_provider.dart
│   │
│   ├── repositories/
│   │   ├── absence_repository.dart    # Interface + Api + Mock
│   │   ├── announcement_repository.dart # Interface + Api + Mock
│   │   ├── clock_repository.dart      # Interface + Api + Mock + inner models
│   │   ├── device_token_repository.dart # Interface + HTTP impl
│   │   ├── notification_repository.dart # Abstract + NoOp + HTTP impl
│   │   ├── schedule_repository.dart   # Interface + Mock (+ CancelToken)
│   │   ├── shift_repository.dart      # Interface + Api + Mock
│   │   └── user_repository.dart       # Interface + Api + Stub
│   │
│   ├── widgets/
│   │   ├── absence/
│   │   │   ├── absence_card.dart
│   │   │   ├── absence_card_expandable.dart
│   │   │   ├── absence_list_card.dart
│   │   │   └── absence_summary_card.dart
│   │   │
│   │   ├── Buttons/
│   │   │   ├── custom_fab.dart
│   │   │   ├── destructive_button.dart
│   │   │   ├── icon_text_button.dart
│   │   │   ├── primary_button.dart
│   │   │   └── secondary_button.dart
│   │   │
│   │   ├── clockIn/
│   │   │   ├── clock_face_card.dart
│   │   │   ├── location_card.dart
│   │   │   ├── location_filter_bar.dart
│   │   │   ├── location_map_preview.dart
│   │   │   ├── location_status_widget.dart
│   │   │   ├── on_duty_status.dart
│   │   │   ├── recent_activity.dart
│   │   │   └── today_shift_card.dart
│   │   │
│   │   ├── common/
│   │   │   ├── announcement_card.dart
│   │   │   ├── custom_app_bar.dart
│   │   │   ├── quick_action_tile.dart
│   │   │   └── section_header.dart
│   │   │
│   │   ├── input/
│   │   │   ├── custom_text_field.dart
│   │   │   └── date_picker_field.dart
│   │   │
│   │   ├── layouts/
│   │   │   └── notification_tile.dart
│   │   │
│   │   └── teams/
│   │       ├── compact_calendar.dart
│   │       ├── create_shift_sheet.dart
│   │       ├── my_shift_card.dart
│   │       ├── team_member_shift_card.dart
│   │       └── weekly_hours_card.dart
│   │
│   └── (legacy: unspecifed.dart, activity_item.dart)
│
├── plans/
│   └── architecture_design.md         # 573-line Clean Architecture + BLoC migration plan
│
├── test/
│   └── widget_test.dart               # Minimal smoke test (17 lines)
│
└── web/
    ├── favicon.png
    ├── firebase-messaging-sw.js       # FCM service worker with notification routing
    ├── icons/
    ├── index.html
    └── manifest.json
```

---

## 4. Data Models

### 4.1 UserModel (`lib/models/user_model.dart`)
```dart
UserModel {
  String id
  String email
  String firstName
  String lastName
  String role                          // "employee" | "manager" | "admin"
  String? avatarUrl
  String? phone
  List<String> assignedLocationIds
  // Getters:
  String get fullName                  // "$firstName $lastName"
  String get initials                  // First letter of first + last name, uppercased
  bool get isManager                   // role == 'manager'
  bool get isAdmin                     // role == 'admin'
}
```
- JSON keys: `id`, `email`, `first_name`, `last_name`, `role`, `avatar_url`, `phone`, `assigned_location_ids`
- Includes `copyWith` (using `Wrapped<T>` for nullable fields), `==`/`hashCode` by `id`

### 4.2 ShiftModel (`lib/models/shift_model.dart`)
```dart
ShiftModel {
  String id
  String role
  DateTime date
  DateTime startTime
  DateTime endTime
  String location
  String address
  double latitude
  double longitude
  String? notes
  int? breakMinutes
  String? roleColor                     // hex color string
  String? label
  List<String> hashtags
  // Getters:
  Duration get duration                 // endTime - startTime
  bool get isToday
  String get formattedStartTime         // "9:00 AM"
  String get formattedEndTime           // "5:00 PM"
  String get timeRange                  // "9:00 AM - 5:00 PM"
}
```
- JSON keys: `id`, `role`, `date`, `startTime`, `endTime`, `location`, `address`, `latitude`, `longitude`, `notes`, `breakMinutes`, `roleColor`, `label`, `hashtags`
- 12-hour time formatting

### 4.3 AbsenceModel (`lib/models/absence.dart`)
```dart
enum AbsenceType { vacation, training, sickLeave, personalDay, unpaid, standby }
enum AbsenceStatus { pending, approved, rejected }

AbsenceModel {
  String id
  AbsenceType type
  DateTime startDate
  DateTime endDate
  int workingDays
  AbsenceStatus status
  String? reason
  // Getters (derived display):
  String get formattedDateRange
  String get typeLabel, typeDisplayName
  IconData get typeIcon
  Color get typeBackgroundColor, typeIconColor, typeColor
  String get statusLabel, statusDisplayName
  Color get statusBackgroundColor, statusTextColor, statusColor
}
```
- JSON keys (input flexible): `id`, `type`, `status`, `start_date`/`startDate`, `end_date`/`endDate`, `working_days`/`workingDays`, `reason`/`note`
- German-language type parsing supported (e.g., `"krankheit"` → `sickLeave`)
- Alias: `typedef Absence = AbsenceModel`

### 4.4 AbsenceSummaryModel (`lib/models/absence_summary.dart`)
```dart
AbsenceSummaryModel {
  int usedDays
  int totalDays
  DateTime validUntil
  // Getters:
  int get remainingDays                // totalDays - usedDays
  double get usagePercentage           // usedDays / totalDays
  String get formattedValidUntil
}
```

### 4.5 NotificationModel (`lib/models/notification_model.dart`)
```dart
enum NotificationCategory { shift, absence, message, clockIn, task, announcement, system }

NotificationModel {
  String id
  String title
  String body
  DateTime createdAt
  NotificationCategory category
  bool isRead
  Map<String, dynamic> data
  // Getters:
  IconData get icon                    // per category
  Color get iconColor, iconBackground  // per category
  String get timeAgo                   // "Just now", "5m ago", "2h ago", "3d ago", "1w ago"
}
```
- Factory: `fromJson()` for API responses
- Factory: `fromFcmData()` for raw FCM messages
- Category mapping from backend `NotificationType` string: `SHIFT_ASSIGNED`, `SHIFT_UPDATED`, `SHIFT_CANCELLED`, `ABSENCE_APPROVED`, `ABSENCE_REJECTED`, `TASK_ASSIGNED`, `ANNOUNCEMENT`, `CHAT_MESSAGE`

### 4.6 TeamMemberModel (`lib/models/team_member_model.dart`)
```dart
enum MemberShiftStatus { active, onBreak, notStarted, completed, absent }

TeamMemberModel {
  String id
  String name
  String role
  String? avatarUrl
  DateTime? shiftStart
  DateTime? shiftEnd
  MemberShiftStatus status
  String? locationId
  String? breakDuration
  // Getters:
  String get initials
  String get formattedShiftStart, formattedShiftEnd
  Color get statusDotColor
  bool get hasStatusDot
}
```

### 4.7 ActivityModel (`lib/models/activity_model.dart`)
```dart
enum ActivityType { clockIn, clockOut, breakStart, breakEnd, other }

ActivityModel {
  String id
  IconData icon
  String title
  DateTime date
  DateTime time
  Color color
  ActivityType type
  // Getters:
  String get formattedDate             // "Monday, Oct 23"
  String get formattedTime             // "9:00 AM"
}
```

### 4.8 ChatMessage + Conversation (`lib/models/chat_model.dart`)
```dart
ChatMessage {
  String id
  String senderId
  String senderName
  String? senderAvatarUrl
  String body
  DateTime sentAt
  bool isRead
  // Getters: initials, timeLabel
}

Conversation {
  String id
  String title
  List<String> participants
  List<ChatMessage> messages
  bool isGroup
  String? avatarUrl
  // Getters: lastMessage, unreadCount, initials
}
```

### 4.9 AnnouncementModel (`lib/models/announcement_model.dart`)
```dart
AnnouncementModel {
  String id
  String title
  String message
  String createdAt                      // raw string (not DateTime)
  String author
  bool isRead
  String? attachmentId
}

AnnouncementListResult {
  List<AnnouncementModel> items
  int unreadCount
  String? nextCursor
}
```

### 4.10 Location Models (3 overlapping variants — TECH DEBT)

#### WorkLocation (`lib/models/location.dart`)
- DB-aligned, lighter model
- Fields: `id`, `name`, `address`, `locationCode`, `latitude`, `longitude`, `geofenceRadiusMeters`, `gpsBufferMeters`, `locationType` (String), `isActive`, `requiresGeofence`, `timezone`, `managerName`, `managerEmail`, `isPrimaryLocation`
- Getter: `effectiveRadiusMeters`, `icon`, `color`

#### WorkLocationModel (`lib/models/work_location_model.dart`)
- Geofence-aware with Geolocator dependency
- Fields: same as WorkLocation but with `LocationType` enum, `geofenceRadiusMeters`, `gpsBufferMeters`, plus `distanceTo(Position)`, `isWithinWorkZone(Position)`

#### WorkplaceLocation (`lib/models/workplace_location.dart`)
- Simpler, standalone model
- Fields: `name`, `address`, `latitude`, `longitude`, `geofenceRadiusMeters`, `gpsBufferMeters`
- Methods: `distanceTo(Position)`, `isWithinWorkZone(Position)`, `isWithinStrictGeofence(Position)`, `formatDistance(meters)`, `getLocationStatus(Position?)`
- Companion: `LocationStatus` class + `LocationStatusType` enum

---

## 5. State Management

### 5.1 AuthProvider (`lib/providers/auth_provider.dart`)
```dart
enum AuthStatus { unauthenticated, loading, authenticated, error }

Fields:
  AuthStatus status
  UserModel? user
  String? errorMessage
  bool isLoggedIn                       // status == authenticated

Methods:
  Future<void> tryRestoreSession()      // Boot-time: refresh token → getMe()
  Future<void> signIn(email, password, rememberEmail)
  Future<void> signOut()

Flow:
  signIn() → POST /api/auth/login → saveTokens() → GET /api/users/me → saveLoginSession()
  tryRestoreSession() → POST /api/auth/refresh → GET /api/users/me
  signOut() → deregister FCM token → clear PrefsService → set unauthenticated
```

### 5.2 ClockProvider (`lib/providers/clock_provider.dart`)
```dart
enum ClockStatus { idle, clockedIn, onBreak }

Fields:
  ClockStatus clockStatus
  Duration sessionTime
  Duration breakTime
  bool isActionLoading
  String? lastError
  // Location:
  bool isLoadingLocation
  bool isWithinWorkZone
  double distanceMeters
  Position? currentPosition
  String? locationError
  // Workplace:
  WorkLocationModel? workplace
  bool isLoadingWorkplace
  String? workplaceError
  // Activity log:
  List<ActivityModel> activities

Methods:
  Future<void> initialise()              // Load workplace + location + restore session
  Future<String?> clockIn()
  Future<String?> clockOut()
  Future<String?> startBreak()
  Future<String?> endBreak()
  Future<String?> requestOverride(reason)
  Future<void> fetchCurrentLocation()
  Future<void> checkLocationPermissionAndFetch()

Key Design Decisions:
  - PESSIMISTIC state: only mutate after successful API call; rollback on failure
  - isActionLoading gates double-submissions
  - Session state restored from server on app restart (handles crash while clocked in)
  - Session timer: Timer.periodic(1s) increments only during active (non-break) time
  - Break timer: separate timer that pauses session timer
  - Activity log bounded to 50 entries
  - Geofence: uses WorkLocationModel.distanceTo() vs effectiveRadiusMeters
```

### 5.3 ScheduleProvider (`lib/providers/schedule_provider.dart`)
```dart
enum ScheduleTab { team, myShifts }
enum ScheduleLoadState { initial, loading, loaded, error }

Fields:
  ScheduleTab activeTab
  DateTime selectedDate
  List<WorkLocationModel> locations
  String? selectedLocationId            // null = "All Locations"
  List<TeamMemberModel> teamMembers
  List<ShiftModel> myShifts
  ScheduleLoadState state
  String? error
  // Computed:
  List<ShiftModel> myShiftsForSelectedDate
  double weeklyTargetHours              // 40.0
  double weeklyHoursLogged
  List<double> weeklyDailyHours         // Mon-Sun bar chart values
  String weekRangeLabel
  DateTime weekStart

Methods:
  Future<void> initialise()
  void switchTab(ScheduleTab)
  void selectDate(DateTime)
  void selectLocation(String?)
  Future<void> createShift(memberId, locationId, startTime, endTime, role, notes?)
  Future<String> exportSchedule()

Design:
  - CancelToken support for aborting stale requests (rapid tab/date switching)
  - Weekly hours computed from myShifts in the ISO week of selectedDate
  - Daily hours for bar chart: Mon(0) through Sun(6)
```

### 5.4 DashboardProvider (`lib/providers/dashboard_provider.dart`)
```dart
enum DashboardLoadState { initial, loading, loaded, error }

Fields:
  DashboardLoadState state
  ShiftModel? todayShift
  double weeklyHours                    // hardcoded: 32.5
  double targetWeeklyHours              // 40.0
  String? errorMessage

Methods:
  String greetingFor(String firstName)  // "Good morning/afternoon/evening, {name}"
  Future<void> load()
```

### 5.5 AbsenceProvider (`lib/providers/absence_provider.dart`)
```dart
enum AbsenceLoadState { initial, loading, loaded, submitting, error }

Fields:
  AbsenceLoadState state
  AbsenceSummaryModel? summary
  List<AbsenceModel> upcoming
  List<AbsenceModel> past
  String? errorMessage

Methods:
  Future<void> loadAbsences()           // Parallel fetch: summary + upcoming + past
  Future<String?> submitAbsence(AbsenceModel)
```

### 5.6 NotificationsProvider (`lib/providers/notifications_provider.dart`)
```dart
enum NotificationsLoadState { initial, loading, loaded, error }

Fields:
  List<NotificationModel> items
  NotificationsLoadState state
  String? error
  String? nextCursor                    // null = no more pages
  bool loadingMore
  int unreadCount                       // computed locally, falls back to server
  bool hasUnread

Methods:
  Future<void> init()                   // load() + syncUnreadCount() + subscribeFcm()
  Future<void> load()
  Future<void> loadMore()
  Future<void> markRead(String id)      // OPTIMISTIC: update local, then API; rollback on failure
  Future<void> markAllRead()

Design:
  - Cursor-based pagination
  - FCM foreground messages prepended to list in real-time
  - Optimistic markRead/markAllRead with rollback
```

### 5.7 AnnouncementProvider (`lib/providers/announcement_provider.dart`)
*(Full file not read, but from repository analysis)*
```dart
Fields:
  List<AnnouncementModel> announcements
  int unreadCount
  bool isLoading
  int page
  bool hasMore

Methods:
  Future<void> loadAnnouncements()
  Future<void> markAsRead(String id)
  Future<void> markAllAsRead()
  Future<void> refreshUnreadCount()
```

### 5.8 ChatProvider (`lib/providers/chat_provider.dart`)
```dart
enum ChatLoadState { initial, loading, loaded, error }

Fields:
  List<Conversation> conversations
  ChatLoadState state
  String? activeConversationId
  Conversation? activeConversation
  int totalUnread                       // sum of unreadCount across all conversations

Methods:
  Future<void> load()                   // Mock data only
  void openConversation(String id)      // Marks messages from others as read
  void closeConversation()
  Future<void> sendMessage(conversationId, body)
```

### 5.9 LocaleProvider (`lib/providers/locale_provider.dart`)
```dart
Fields:
  Locale locale                         // default: en

Methods:
  static Future<LocaleProvider> create() // Load persisted code from PrefsService
  Future<void> setLocale(Locale)
  Future<void> setLanguageCode(String)
```

---

## 6. Repository Layer

All repositories follow the same pattern: **abstract interface** → **real implementation** + **mock/stub implementation**.

### 6.1 UserRepository
| Method | Returns | Description |
|---|---|---|
| `getMe()` | `Future<UserModel>` | GET /api/users/me |
| `updateProfile(fields)` | `Future<UserModel>` | PATCH /api/users/me |
| **Impl:** `ApiUserRepository` — real Dio calls | | |
| **Stub:** `StubUserRepository` — returns hardcoded Alex Johnson user | | |

### 6.2 ClockRepository
| Method | Returns | Description |
|---|---|---|
| `clockIn(lat, lng, distance, accuracy, shiftId?)` | `Future<void>` | POST /api/clock/in |
| `clockOut(lat, lng, accuracy)` | `Future<void>` | POST /api/clock/out |
| `startBreak()` | `Future<void>` | POST /api/clock/break/start |
| `endBreak()` | `Future<void>` | POST /api/clock/break/end |
| `requestOverride(lat, lng, reason?)` | `Future<void>` | POST /api/clock/override-request |
| `getWorkLocation()` | `Future<WorkLocationModel>` | GET /work-locations |
| `getTodayActivities()` | `Future<TodayActivities>` | GET /clock/today |
| **Impl:** `ApiClockRepository` — real Dio | | |
| **Mock:** `MockClockRepository` — 200-300ms delays, Berlin HQ (52.5200, 13.4050) | | |

**Response Models (in clock_repository.dart):**
- `TodayActivitiesSummary { bool isClockedIn, bool isOnBreak }`
- `TodayActivityEntry { DateTime timestamp, String type }`
- `TodayActivities { TodayActivitiesSummary summary, List<TodayActivityEntry> data }`

### 6.3 ShiftRepository
| Method | Returns | Description |
|---|---|---|
| `getShiftsForWeek(weekStart)` | `Future<List<ShiftModel>>` | GET /api/shifts?from=...&to=... |
| `getTodayShift()` | `Future<ShiftModel?>` | GET /api/shifts?from=today&to=today |
| `getTeamShifts(weekStart)` | `Future<List<ShiftModel>>` | GET /api/shifts?from=...&to=...&all=true |
| **Impl:** `ApiShiftRepository` — real Dio | | |
| **Mock:** `MockShiftRepository` — returns a single shift (Floor Manager, 9-5) | | |

### 6.4 ScheduleRepository
| Method | Returns | Description |
|---|---|---|
| `getLocations()` | `Future<List<WorkLocationModel>>` | 4 mock locations (Berlin, Hamburg, Munich, Remote) |
| `getTeamShifts(date, locationId?)` | `Future<List<TeamMemberModel>>` | 6 mock team members |
| `getMyShifts(month, cancelToken?)` | `Future<List<ShiftModel>>` | Mon-Fri shifts for entire month (9-5, Floor Manager) |
| `createShift(memberId, locationId, date, startTime, endTime, role, notes?)` | `Future<void>` | Not yet wired |
| `exportSchedule(date, locationId?)` | `Future<String>` | Returns "schedule_YYYY-MM-DD.csv" |
| **Only Mock:** `MockScheduleRepository` | | |

### 6.5 AbsenceRepository
| Method | Returns | Description |
|---|---|---|
| `getSummary()` | `Future<AbsenceSummaryModel>` | GET /api/absences/entitlement?absenceType=VACATION&year=... |
| `getUpcoming()` | `Future<List<AbsenceModel>>` | GET /api/absences/list/detailed?from=...&status=PENDING,APPROVED |
| `getPast()` | `Future<List<AbsenceModel>>` | GET /api/absences/list/detailed?to=... |
| `submitAbsence(absence)` | `Future<void>` | POST /api/absences/calendar |
| **Impl:** `ApiAbsenceRepository` — real Dio | | |
| **Mock:** `MockAbsenceRepository` — 12/24 vacation days, 3 absences | | |

### 6.6 NotificationRepository
| Method | Returns | Description |
|---|---|---|
| `list(unreadOnly, limit, cursor)` | `Future<NotificationPage>` | GET /notifications?limit=...&cursor=... |
| `getUnreadCount()` | `Future<int>` | GET /notifications/unread-count |
| `markAsRead(id)` | `Future<void>` | PATCH /notifications/{id}/read |
| `markAllAsRead()` | `Future<void>` | PATCH /notifications/read-all |
| **NoOp:** `NoOpNotificationRepo` — all empty/default | | |
| **HTTP:** `NotificationRepositoryImpl` — real Dio (used when authenticated) | | |

### 6.7 AnnouncementRepository
| Method | Returns | Description |
|---|---|---|
| `list(cursor, limit, search, onlyUnread)` | `Future<AnnouncementListResult>` | GET /api/announcements |
| `getUnreadCount()` | `Future<int>` | GET /api/announcements/unread-count |
| `markRead(id)` | `Future<void>` | POST /api/announcements/{id}/read |
| `markAllRead()` | `Future<void>` | POST /api/announcements/read-all |
| **Impl:** `ApiAnnouncementRepository` — real Dio | | |
| **Mock:** `MockAnnouncementRepository` — 1 German announcement | | |

### 6.8 DeviceTokenRepository
| Method | Returns | Description |
|---|---|---|
| `registerToken(token, platform)` | `Future<void>` | POST /device-tokens |
| `removeToken(token)` | `Future<void>` | DELETE /device-tokens |
| `removeAllTokens()` | `Future<void>` | DELETE /device-tokens/all |
| **Impl:** `DeviceTokenRepositoryImpl` — real Dio | | |

---

## 7. API / Network Layer

### 7.1 ApiClient (`lib/core/network/api_client.dart`)
- **Type:** Singleton (Dio-based)
- **Base URL:** Configurable via `--dart-define=API_BASE_URL=...`, defaults to `https://api.wrenta.io`
- **Timeouts:** Connect 10s, Receive 20s, Send 15s
- **Defaults:** `Content-Type: application/json`, `Accept: application/json`

#### Interceptors
1. **_AuthInterceptor** (custom):
   - Adds `Authorization: Bearer <token>` from SharedPreferences to every request
   - On 401: attempts single token refresh via `POST /api/auth/refresh`
   - On refresh success: retries original request with new token
   - On refresh failure: clears tokens, propagates UnauthorizedException
   - Skips interceptor for refresh endpoint itself (`skipAuthInterceptor: true`)
2. **LogInterceptor** (Dio built-in):
   - Logs request body and response body via print

#### Error Mapping (`_mapDioError`)
| DioExceptionType | ApiException |
|---|---|
| connectionTimeout / sendTimeout / receiveTimeout | `RequestTimeoutException` |
| connectionError | `NetworkException` |
| badResponse (401) | `UnauthorizedException` |
| badResponse (403) | `ForbiddenException` |
| badResponse (404) | `NotFoundException` |
| badResponse (422) | `ValidationException` (with field errors) |
| badResponse (5xx) | `ServerException` (with statusCode) |
| cancel | `UnknownException('Request was cancelled.')` |
| other | `UnknownException` |

### 7.2 ApiException Hierarchy (`lib/core/network/api_exceptions.dart`)
```
ApiException (sealed)
├── NetworkException                     # No internet / DNS failure
├── RequestTimeoutException              # Timeout
├── ServerException { int statusCode }   # 5xx
├── UnauthorizedException                # 401
├── ForbiddenException                   # 403
├── NotFoundException                    # 404
├── ValidationException { Map<String, List<String>> fieldErrors }  # 422
├── ParseException                       # Malformed response
└── UnknownException                     # Catch-all
```

### 7.3 ApiConfig Endpoints (`lib/core/network/api_config.dart`)

#### Auth
| Method | Path | Description |
|---|---|---|
| POST | `/api/auth/login` | Login with email/password |
| POST | `/api/auth/refresh` | Refresh JWT token |
| POST | `/api/auth/logout` | Logout (invalidate session) |

#### User
| Method | Path | Description |
|---|---|---|
| GET | `/api/users/me` | Get current user profile |
| PUT/PATCH | `/api/users/me` | Update current user profile |

#### Shifts
| Method | Path | Description |
|---|---|---|
| GET | `/api/shifts` | List shifts (with from/to/query params) |

#### Clock
| Method | Path | Description |
|---|---|---|
| POST | `/api/clock/in` | Clock in |
| POST | `/api/clock/out` | Clock out |
| POST | `/api/clock/break/start` | Start break |
| POST | `/api/clock/break/end` | End break |
| GET | `/api/clock/team` | Team clock statuses |
| GET | `/api/clock/log` | Clock activity log |
| POST | `/api/clock/override-request` | Request location override |

#### Absences
| Method | Path | Description |
|---|---|---|
| GET | `/api/absences/calendar` | Absence calendar data |
| GET | `/api/absences/calendar/requests` | Absence requests |
| GET | `/api/absences/list/detailed` | Detailed absence list |
| GET | `/api/absences/entitlement` | Absence entitlement/summary |
| GET | `/api/absences/bans` | Absence bans |
| GET | `/api/absences/school-holidays` | School holiday data |

#### Availabilities
| Method | Path | Description |
|---|---|---|
| GET | `/api/availabilities/me` | My availabilities |
| GET | `/api/availabilities/check` | Availability check |

#### Announcements
| Method | Path | Description |
|---|---|---|
| GET | `/api/announcements` | List announcements |
| GET | `/api/announcements/unread-count` | Unread count |
| POST | `/api/announcements/read-all` | Mark all read |
| POST | `/api/announcements/{id}/read` | Mark single read |

#### Timesheets
| Method | Path | Description |
|---|---|---|
| GET | `/api/timesheets/me/week` | Weekly timesheet |
| GET | `/api/timesheets/me/month` | Monthly timesheet |

#### Device Tokens (not in ApiConfig, hardcoded in repositories)
| Method | Path | Description |
|---|---|---|
| POST | `/device-tokens` | Register FCM token |
| DELETE | `/device-tokens` | Remove FCM token |
| DELETE | `/device-tokens/all` | Remove all tokens |

---

## 8. Presentation Layer

### 8.1 NavigationShell — 5-Tab Shell (`lib/pages/navigation_shell.dart`)
```
┌─────────────────────────────────────────┐
│  IndexedStack (preserves state)         │
│  ┌─────────────────────────────────────┐│
│  │  Tab 0: DashboardPage              ││
│  │  Tab 1: TeamSchedulePage           ││
│  │  Tab 2: ClockPage                  ││
│  │  Tab 3: ChatPage                   ││
│  │  Tab 4: ProfilePage                ││
│  └─────────────────────────────────────┘│
├─────────────────────────────────────────┤
│  BottomNavigationBar                    │
│  [Home] [Schedule] [Clock] [Chat] [Menu]│
└─────────────────────────────────────────┘
```

- Uses `IndexedStack` to keep page state alive across tab switches
- Bottom nav uses custom widget (not Flutter's `BottomNavigationBar`) for full control
- Labels from `AppLocalizations` (i18n)

### 8.2 Onboarding (`lib/pages/onboarding/onboarding.dart`)
- 3-page carousel with `SmoothPageIndicator`
- "Skip" and "Get Started" buttons
- Checks `PrefsService.hasSeenOnboarding()` to skip on subsequent launches

### 8.3 LoginPage (`lib/pages/auth/login_page.dart`)
- Email + Password fields
- Remember Me checkbox
- Links to Signup
- Uses `AuthProvider.signIn()`
- Shows localized error messages

### 8.4 SignupPage (`lib/pages/auth/signup_page.dart`)
- Multi-step: Personal Details → Account Setup
- Fields: full name, work email, employee ID, password
- Terms of Service + Privacy Policy links

### 8.5 Dashboard (`lib/pages/dashboard/dashboard.dart`)
- Time-of-day greeting (morning/afternoon/evening) from `DashboardProvider.greetingFor()`
- User name from `AuthProvider.user`
- Bell icon with unread badge → `/notifications`
- Quick Actions: Open Shifts, Requests, Handover
- Weekly Summary card (logged hours vs target)
- Announcements section (latest)

### 8.6 MySchedule (`lib/pages/schedule/myschedule.dart`)
- Horizontal date picker (static dates)
- Shift cards with role colors
- Weekly progress bar

### 8.7 TeamSchedule (`lib/pages/schedule/teamschedule.dart`)
- Tab bar: Team / My Shifts
- Calendar date picker
- Location filter chips
- Team member list with status dots (active/green, break/yellow, etc.)

### 8.8 ClockInPage (`lib/pages/time_tracking/clockin_page.dart`)
- "On Duty" / "Not Clocked In" status pill
- Analog clock face card
- Location card with zone status (green=within, red=outside)
- Action buttons: Clock In/Out, Start/End Break, Request Override
- Recent Activity timeline
- GPS geofence enforcement (must be within zone to clock in)

### 8.9 TimeAccountPage (`lib/pages/time_tracking/time_account_page.dart`)
- Overtime balance (static hardcoded values)
- Monthly trend chart (placeholder bars)
- Expandable month details

### 8.10 AbsencePage (`lib/pages/absence/absence_page.dart`)
- Summary card (used/remaining/total days + progress indicator)
- Upcoming absences list
- Past requests list
- FAB → `/new-absence`

### 8.11 NewAbsencePage (`lib/pages/absence/new_absence_page.dart`)
- Absence type selector (Vacation, Training, Sick Leave, Personal Day, Unpaid, Stand-by)
- Start/End date pickers
- Reason text field
- File attachment (file_picker)
- Submit with validation

### 8.12 ConfirmationPage (`lib/pages/absence/confirmation_page.dart`)
- Success checkmark animation, message, "Back to Home" button

### 8.13 RequestHistory (`lib/pages/absence/request_history.dart`)
- Tab 1: Absence Requests (filtered by status: pending/approved/rejected)
- Tab 2: Shift Changes (placeholder)
- Search bar

### 8.14 ChatPage (`lib/pages/chat/chat_page.dart`)
- Conversation list with avatars, last message, unread badge
- Message thread view (bubbles)
- Text input with send button
- All mock data via `ChatProvider`

### 8.15 NotificationPage (`lib/pages/notification/notification_page.dart`)
- Grouped list (Today, Yesterday, Earlier)
- "Mark all as read" button
- Tiles with category icon + color + timeAgo

### 8.16 MenuPage (`lib/pages/profile/menu_page.dart`)
- User avatar + name header
- Settings: Profile, Documents, Language, App Info
- Actions: Change Password, Logout

### 8.17 AvailabilityPage (`lib/pages/profile/availability_page.dart`)
- Day-by-day availability toggles (Mon-Sun)
- Time slot configuration per day

### 8.18 LanguageSettingsTile (`lib/pages/profile/language_settings_tile.dart`)
- Dropdown/toggle: English / Deutsch / System Default

---

## 9. Widgets Subsystem

### 9.1 Button Widgets (`lib/widgets/Buttons/`)
| Widget | Description |
|---|---|
| `PrimaryButton` | Filled primary color, loading spinner, disabled state, optional icon |
| `SecondaryButton` | Outlined with onSurface color, loading state |
| `DestructiveButton` | Red text button with delete icon |
| `IconTextButton` | Icon + label with flexible styling |
| `CustomFab` | Styled FloatingActionButton (primary/secondary) |

### 9.2 ClockIn Widgets (`lib/widgets/clockIn/`)
| Widget | Description |
|---|---|
| `OnDutyStatus` | Colored pill badge (green=on duty, gray=not clocked in) |
| `ClockFaceCard` | Styled analog clock with hour/minute tick marks |
| `LocationFilterBar` | Horizontal chip bar for location selection |
| `LocationStatusWidget` | Colored zone indicator (green=within, red=outside) |
| `LocationMapPreview` | Placeholder gray container with Map pin icon |
| `LocationCard` | Location name + address + status + distance display |
| `TodayShiftCard` | Current shift time range card |
| `RecentActivity` | Timeline list with activity type icon + time |

### 9.3 Absence Widgets (`lib/widgets/absence/`)
| Widget | Description |
|---|---|
| `AbsenceSummaryCard` | Used/remaining/total with linear progress indicator |
| `AbsenceCard` | Type icon + color dot, type/status/dates with status chip |
| `AbsenceCardExpandable` | Same as above + expandable reason section |
| `AbsenceListCard` | ListTile variant with leading icon |

### 9.4 Team Schedule Widgets (`lib/widgets/teams/`)
| Widget | Description |
|---|---|
| `WeeklyHoursCard` | Bar chart with per-day logged hours (max 5 bars) |
| `MyShiftCard` | Shift with time range, location, colored role tag |
| `CreateShiftSheet` | Bottom sheet form for creating shifts |
| `TeamMemberShiftCard` | Avatar + name + role + status dot + shift time |
| `CompactCalendar` | Mini calendar grid with date dots |

### 9.5 Common Widgets (`lib/widgets/common/`)
| Widget | Description |
|---|---|
| `QuickActionTile` | Tappable card with icon + title + subtitle |
| `SectionHeader` | Section title + "View all" link |
| `AnnouncementCard` | Title, message preview, timestamp, unread indicator |
| `CustomAppBar` | Back button + title + optional actions |

### 9.6 Input Widgets (`lib/widgets/input/`)
| Widget | Description |
|---|---|
| `CustomTextField` | Decorated TextField with leading icon |
| `DatePickerField` | Date display + picker trigger |

### 9.7 Layout Widgets (`lib/widgets/layouts/`)
| Widget | Description |
|---|---|
| `NotificationTile` | Icon (per category) + title + body + timeAgo |

---

## 10. Theme & Design System

### 10.1 AppColors (`lib/core/theme/app_colors.dart`)
```
Primary:     #2563EB (blue) + light variants
Neutral:     Slate scale 50-900
Semantic:    Success #22C55E, Warning #F59E0B, Error #EF4444, Info #3B82F6
Status:      Active #22C55E, Inactive #94A3B8, Pending #F59E0B, Approved #22C55E, Rejected #EF4444
Surface:     Background #F8FAFC, Surface #FFFFFF, SurfaceVariant #F1F5F9
Accent:      Purple #8B5CF6, Amber #FBBF24, Orange #F97316
```

### 10.2 AppTextStyles (`lib/core/theme/app_text_styles.dart`)
```
h4:  20px/700  → section headers
h5:  18px/700  → card titles
h6:  16px/700  → subsection headers
bodyLarge:   16px/500  → primary content
bodyMedium:  15px/500  → secondary content
bodySmall:   14px/500  → tertiary/helper
bodyBold:    15px/700  → emphasized
labelLarge/Medium/Small:  15/14/13px, 600 weight
caption:     12px/500
overline:    12px/800, 0.5 letter-spacing
sectionLabel: 13px/600, 0.5 letter-spacing
buttonLarge: 16px/700
buttonMedium: 15px/700
monospace:   15px/600, Courier
link:        15px/600, underlined
```

### 10.3 AppDimensions (`lib/core/theme/app_dimensions.dart`)
```
Spacing:  xs(4), sm(8), md(12), lg(16), xl(20), xxl(32), 2xl(24), 3xl(32), 4xl(40), 5xl(48), 6xl(64)
Radius:   xs(4), sm(8), md(12), lg(16), xl(20), 2xl(24), full(999)
Icons:    xs(16), sm(20), md(24), lg(28), xl(32), 2xl(40)
Buttons:  sm(40), md(48), lg(56), xl(64)
Avatars:  xs(24), sm(32), md(48), lg(64), xl(80), 2xl(100), 3xl(140)
Cards:    padding sm(12), md(16), lg(20), xl(24)
Inputs:   height(56)
```

### 10.4 AppTheme (`lib/core/theme/app_theme.dart`)
- Material 3 `ThemeData` (light only)
- Uses `ColorScheme.fromSeed(seedColor: primary, brightness: light)`
- Custom components: AppBar, ElevatedButton, OutlinedButton, InputDecoration, BottomNavigationBar, FloatingActionButton, Divider
- Font family: `'Inter'`
- No dark theme

### 10.5 Legacy theme.dart
- Minimal duplicate file with 5 color constants
- Not used by main app — likely dead code

---

## 11. Localization / i18n

### 11.1 Architecture
- **Custom implementation** (not using Flutter's ARB tooling despite `.arb` files existing)
- `AppLocalizations` abstract class with `of(context)` static accessor
- Custom delegate `_AppLocalizationsDelegate` that instantiates the correct language
- ~232 unique string keys across ~954 lines
- `.arb` files are documentation/reference only — actual strings are hardcoded in Dart

### 11.2 Supported Languages
| Code | File | Strings |
|---|---|---|
| `en` | `app_en.arb` | ~504 lines |
| `de` | `app_de.arb` | ~167 lines |

### 11.3 Key Categories
- General: appName, ok, cancel, save, submit, loading, error messages
- Auth: login, signup, email, password, rememberMe
- Navigation: navDashboard, navSchedule, navTracking, navMessages, navMore
- Clock: clockIn, clockOut, breakStart, breakEnd, locationStatus
- Absence: absence types, status labels, summary
- Schedule: shift labels, team view, calendar
- Notifications: empty state, markRead, categories
- Chat: send, typeMessage, empty conversations
- Profile: settings, language, logout, availability
- Validation: field-specific error messages

---

## 12. Services

### 12.1 PrefsService (`lib/core/services/prefs_service.dart`)
- Wraps `SharedPreferences` with typed static methods
- **Keys:**
  - `has_seen_onboarding` (bool)
  - `is_logged_in` (bool)
  - `user_email`, `user_name`, `employee_id` (String)
  - `remembered_email` (String)
  - `auth_access_token`, `auth_refresh_token` (String)
  - `language_code` (String)
- **Methods:**
  - `hasSeenOnboarding()` / `markOnboardingSeen()`
  - `isLoggedIn()` / `saveLoginSession()` / `saveRegistration()` / `logout()`
  - `saveTokens()` / `getAccessToken()` / `getRefreshToken()` / `clearTokens()`
  - `getUserEmail()` / `getUserName()` / `getEmployeeId()` / `getRememberedEmail()`
  - `getLanguageCode()` / `saveLanguageCode()`
- **Security:** Tokens stored in plaintext (no encryption — tech debt)

### 12.2 NotificationService (`lib/core/services/notification_service.dart`)
- Singleton managing FCM push notifications
- **Initialization flow (init()):**
  1. Register background handler (`_firebaseBackgroundHandler`)
  2. Request notification permissions
  3. Initialize local notifications (Android channels: `planno_shifts` high importance, `planno_general` high)
  4. Register FCM token with backend (`POST /device-tokens`)
  5. Listen for FCM token refreshes
  6. Wire up foreground message → local notification display
  7. Wire up tap handlers for background and terminated states
- **Background handler:** Re-initializes Firebase, logs message
- **Foreground handler:** Shows local notification via `flutter_local_notifications` with channel selection based on `data.type`
- **Navigation routing:** `navigatorKey` + `_routeFromData()` maps notification types to routes:
  - `SHIFT_ASSIGNED/UPDATED/CANCELLED` → `/shifts`
  - `ABSENCE_APPROVED/REJECTED` → `/absences`
  - `ANNOUNCEMENT` → `/announcements/{id}`
  - `TASK_ASSIGNED` → `/tasks`
  - default → `/notifications`
- **Dependencies:** `firebase_core`, `firebase_messaging`, `flutter_local_notifications`

---

## 13. Routing & Navigation

### 13.1 Approach
- **Navigator 1.0** with named routes (no router package)

### 13.2 Route Table (in `main.dart`)
| Route | Widget | Notes |
|---|---|---|
| `/` | `OnboardingPage` or `NavigationShell` | Resolved at startup based on `PrefsService` |
| `/onboarding` | `OnboardingScreen` | |
| `/login` | `LoginPage` | |
| `/signup` | `CreateAccountScreen` | |
| `/home` | `NavigationShell` | 5-tab shell |
| Additional routes via `Navigator.pushNamed()`: | | |
| `/absences` | `AbsencePage` | |
| `/new-absence` | `NewAbsencePage` | |
| `/confirmation` | `ConfirmationPage` | |
| `/request-history` | `RequestHistoryPage` | |
| `/chat` | `ChatPage` | |
| `/notifications` | `NotificationPage` | |
| `/profile` | `MenuPage` | |
| `/availability` | `AvailabilityPage` | |
| `/time-account` | `TimeAccountPage` | |
| `/team-schedule` | `TeamSchedulePage` | |
| `/my-schedule` | `MySchedulePage` | |

### 13.3 Initial Route Resolution
```dart
main() → _resolveInitialRoute() {
  if (!hasSeenOnboarding) → '/onboarding'
  if (isLoggedIn) → '/home'
  else → '/login'
}
```

---

## 14. Push Notifications

### 14.1 Architecture
```
┌──────────────┐     FCM Push     ┌──────────────────┐
│  Backend     │ ──────────────→  │  Firebase Cloud  │
│  (sends      │                  │  Messaging       │
│  notification│                  └────────┬─────────┘
│  type + data)│                           │
└──────────────┘                           │
                  ┌────────────────────────┼──────────────────────┐
                  │                        │                      │
                  ▼                        ▼                      ▼
           ┌─────────────┐       ┌───────────────┐      ┌──────────────┐
           │  OnMessage  │       │ OnMessage     │      │ Background   │
           │  (foreground)│       │ OpenedApp     │      │ Isolate     │
           │             │       │ (background→   │      │ (terminated)│
           │  Show local │       │  foreground)   │      │             │
           │  notif via  │       │               │      │ Log +       │
           │  fl_notif   │       │ Route to      │      │ (future: DB)│
           │             │       │ screen        │      │             │
           └─────────────┘       └───────────────┘      └──────────────┘
```

### 14.2 Web Service Worker (`web/firebase-messaging-sw.js`)
- **Firebase version:** 10.12.0 (compat)
- **Firebase config:** Placeholder values (`REPLACE_WITH_YOUR_*`)
- **Notification icons:** Mapped by type (shift, absence, announcement, task)
- **Click routing:** Same route mapping as native (shifts, absences, announcements, tasks, notifications)
- **Behavior:** Groups notifications by type tag, opens/focuses existing tab or creates new

### 14.3 Notification Type Mapping
| Backend Type | Category | Route | Icon |
|---|---|---|---|
| `SHIFT_ASSIGNED` | shift | `/shifts` | icon-shift.png |
| `SHIFT_UPDATED` | shift | `/shifts` | icon-shift.png |
| `SHIFT_CANCELLED` | shift | `/shifts` | icon-shift.png |
| `ABSENCE_APPROVED` | absence | `/absences` | icon-absence.png |
| `ABSENCE_REJECTED` | absence | `/absences` | icon-absence.png |
| `ANNOUNCEMENT` | announcement | `/announcements/{id}` | icon-announcement.png |
| `TASK_ASSIGNED` | task | `/tasks` | icon-task.png |
| `CHAT_MESSAGE` | message | (chat) | default |

---

## 15. Platform Configuration

### 15.1 Android (`android/app/build.gradle.kts`)
```
package:         com.example.wrenta (placeholder)
compileSdk:      flutter.wrapper
minSdk:          flutter.wrapper
targetSdk:       flutter.wrapper
Java:            Java 17
Kotlin:          2.2.20
AGP:             8.11.1
signing:         debug signing config (even for release — placeholder)
```

### 15.2 iOS (`ios/Runner/Info.plist`)
```
Bundle ID:          $(PRODUCT_BUNDLE_IDENTIFIER) (placeholder)
Supported ORIENT:   portrait + landscape (iPhone), all (iPad)
Permissions:
  - NSLocationWhenInUseUsageDescription
  - NSPhotoLibraryUsageDescription
  - NSFileProviderDomainUsageDescription
High refresh rate:  CADisableMinimumFrameDurationOnPhone = true
```

### 15.3 Web (`web/`)
```
index.html:        Standard Flutter web entry point
manifest.json:     PWA manifest
favicon.png:       App favicon
firebase-messaging-sw.js: 93-line FCM service worker
icons/:            Notification type icons
```

---

## 16. Testing

| Test File | Type | Coverage |
|---|---|---|
| `test/widget_test.dart` | Widget (smoke) | Verifies `WrentaApp` renders without crashing |

**Missing tests:**
- No unit tests for models (serialization, copyWith, helpers)
- No unit tests for providers (state transitions, API calls)
- No unit tests for repositories (mock verification)
- No unit tests for services (PrefsService, NotificationService)
- No widget tests for any page or widget
- No integration tests
- No golden file tests

---

## 17. Known Tech Debt

| # | Issue | Severity | Location |
|---|---|---|---|
| 1 | **3 overlapping location models** — `WorkLocation`, `WorkLocationModel`, `WorkplaceLocation` with different fields and geofence logic | High | `models/` |
| 2 | **Only auth uses real API** — all other features use mock repositories | High | `repositories/` |
| 3 | **Placeholder app IDs** — `com.example.wrenta`, `$(PRODUCT_BUNDLE_IDENTIFIER)` | High | Android/iOS config |
| 4 | **Firebase not fully configured** — `firebase_options.dart` may be missing, web FCM has placeholder values | High | `web/firebase-messaging-sw.js` |
| 5 | **No secure storage** — JWT tokens in plaintext SharedPreferences | High | `PrefsService` |
| 6 | **No dark theme** — only light theme implemented | Medium | `app_theme.dart` |
| 7 | **No router package** — Navigator 1.0 with named routes | Medium | `main.dart` |
| 8 | **ARB files unused** — `.arb` files exist but strings are hardcoded in Dart | Medium | `l10n/` |
| 9 | **Legacy `theme.dart`** — duplicates constants from `core/theme/` | Low | `core/theme.dart` |
| 10 | **Legacy widget files** — `unspecified.dart`, `activity_item.dart` | Low | `widgets/` |
| 11 | **Pagination inconsistency** — cursor-based for notifications, page-based for announcements | Medium | `providers/` |
| 12 | **No offline support** — no local caching or SQLite/Hive | Medium | entire app |
| 13 | **Hardcoded geofence** — Berlin office (52.5200, 13.4050) in mock | Low | `MockClockRepository` |
| 14 | **No error handling middleware** — exceptions caught per-provider | Medium | `providers/` |
| 15 | **Static dashboard data** — weekly hours hardcoded to 32.5 | Low | `DashboardProvider` |
| 16 | **No widget tests** — only 1 smoke test (17 lines) | High | `test/` |
| 17 | **`widgets/layouts/`** — contains `notification_tile.dart` but lives under `layouts/` | Low | directory structure |

---

## 18. Planned Migrations (from `plans/architecture_design.md`)

The existing 573-line design document recommends:

### 18.1 Clean Architecture + BLoC Pattern
```
┌──────────────────────────────────────────────────────────────┐
│  Domain Layer (entities + use cases)                         │
├──────────────────────────────────────────────────────────────┤
│  Data Layer (repositories + DTOs + data sources)             │
├──────────────────────────────────────────────────────────────┤
│  Presentation Layer (BLoC + widgets)                         │
└──────────────────────────────────────────────────────────────┘
```

### 18.2 Recommended Package Additions
| Package | Purpose |
|---|---|
| `flutter_bloc` | State management |
| `equatable` | Value equality for BLoC states |
| `json_annotation` + `freezed` | Code generation for models |
| `go_router` | Declarative routing |
| `hive` or `drift` | Local database (offline support) |
| `flutter_secure_storage` | Encrypted token storage |
| `connectivity_plus` | Network awareness |
| `sentry_flutter` | Crash reporting |
| `firebase_core/messaging` | Production Firebase setup |

### 18.3 4-Week Roadmap
| Week | Focus |
|---|---|
| 1 | Foundation: domain layer, use cases, real API wiring |
| 2 | Core Features: clock, schedule, absence with real repos |
| 3 | Polish: caching, offline, error handling, dark theme |
| 4 | Quality: tests, CI/CD, performance, security |

---

## 19. API Endpoints Reference

### Auth
| Method | Endpoint | Request | Response |
|---|---|---|---|
| POST | `/api/auth/login` | `{ email, password }` | `{ access_token, refresh_token }` |
| POST | `/api/auth/refresh` | `{ refresh_token }` | `{ access_token, refresh_token }` |
| POST | `/api/auth/logout` | — | 200 OK |

### User
| Method | Endpoint | Response |
|---|---|---|
| GET | `/api/users/me` | `UserModel` JSON |
| PATCH | `/api/users/me` | Updated `UserModel` JSON |

### Shifts
| Method | Endpoint | Query Params | Response |
|---|---|---|---|
| GET | `/api/shifts` | `from`, `to`, `all?` | `List<ShiftModel>` |

### Clock
| Method | Endpoint | Request Body |
|---|---|---|
| POST | `/api/clock/in` | `{ latitude?, longitude?, accuracy?, distance_from_workplace, shift_id? }` |
| POST | `/api/clock/out` | `{ latitude?, longitude?, accuracy? }` |
| POST | `/api/clock/break/start` | — |
| POST | `/api/clock/break/end` | — |
| GET | `/api/clock/team` | — |
| GET | `/api/clock/log` | — |
| POST | `/api/clock/override-request` | `{ latitude?, longitude?, reason? }` |

### Absences
| Method | Endpoint | Params | Response |
|---|---|---|---|
| GET | `/api/absences/entitlement` | `absenceType`, `year` | `List<entitlement>` |
| GET | `/api/absences/list/detailed` | `from`, `to`, `status` | `List<AbsenceModel>` |
| POST | `/api/absences/calendar` | Absence body | 201 Created |

### Notifications
| Method | Endpoint | Response |
|---|---|---|
| GET | `/notifications` | `{ data: [...], nextCursor }` |
| GET | `/notifications/unread-count` | `{ data: { count } }` |
| PATCH | `/notifications/{id}/read` | 200 OK |
| PATCH | `/notifications/read-all` | 200 OK |

### Announcements
| Method | Endpoint | Response |
|---|---|---|
| GET | `/api/announcements` | `{ data: [...], nextCursor, unreadCount }` |
| GET | `/api/announcements/unread-count` | `{ unreadCount }` |
| POST | `/api/announcements/{id}/read` | 200 OK |
| POST | `/api/announcements/read-all` | 200 OK |

### Device Tokens
| Method | Endpoint | Request |
|---|---|---|
| POST | `/device-tokens` | `{ token, platform }` |
| DELETE | `/device-tokens` | `{ token }` |
| DELETE | `/device-tokens/all` | — |

### Availabilities
| Method | Endpoint |
|---|---|
| GET | `/api/availabilities/me` |
| GET | `/api/availabilities/check` |

### Timesheets
| Method | Endpoint |
|---|---|
| GET | `/api/timesheets/me/week` |
| GET | `/api/timesheets/me/month` |

---

## 20. Data Flow Diagrams

### 20.1 Authentication Flow
```
User                     AuthProvider                   ApiClient              Backend
 │                          │                              │                      │
 │  signIn(email, pwd)     │                              │                      │
 │ ──────────────────────→ │                              │                      │
 │                          │  POST /api/auth/login        │                      │
 │                          │ ──────────────────────────→ │ ──────────────────→ │
 │                          │                              │ ←── tokens ─────── │
 │                          │  saveTokens()                │                      │
 │                          │  saveLoginSession()          │                      │
 │                          │  GET /api/users/me           │                      │
 │                          │ ──────────────────────────→ │ ──────────────────→ │
 │                          │ ←── UserModel ────────────── │ ←── profile ────── │
 │                          │                              │                      │
 │  ←── authenticated ──── │                              │                      │
```

### 20.2 Clock In Flow (with Geofence)
```
User                     ClockProvider                Geolocator         ClockRepo           Backend
 │                          │                            │                  │                  │
 │  clockIn()               │                            │                  │                  │
 │ ──────────────────────→ │                            │                  │                  │
 │                          │  fetchCurrentLocation()    │                  │                  │
 │                          │ ───────────────────────→ │                  │                  │
 │                          │ ←── Position ──────────── │                  │                  │
 │                          │                            │                  │                  │
 │                          │  distanceTo(workplace)    │                  │                  │
 │                          │  isWithinWorkZone() check │                  │                  │
 │                          │                            │                  │                  │
 │                          │  if NOT within zone       │                  │                  │
 │                          │  ← return error           │                  │                  │
 │                          │                            │                  │                  │
 │                          │  if within zone:          │                  │                  │
 │                          │  _repo.clockIn(...)        │                  │                  │
 │                          │ ────────────────────────────────────────────→ │ ───────────────→ │
 │                          │ ←── success ────────────────────────────────── ←── 200 OK ──── │
 │                          │                            │                  │                  │
 │                          │  _clockStatus = clockedIn  │                  │                  │
 │                          │  _startSessionTimer()      │                  │                  │
 │                          │  _addActivity()            │                  │                  │
 │                          │                            │                  │                  │
 │  ←── UI updates ─────── │                            │                  │                  │
```

### 20.3 Session Restore on App Restart
```
App Start                  ClockProvider                   ClockRepo
 │                            │                               │
 │  initialise()              │                               │
 │ ────────────────────────→ │                               │
 │                            │  getTodayActivities()          │
 │                            │ ────────────────────────────→ │
 │                            │ ←── TodayActivities ────────── │
 │                            │                               │
 │                            │  if isClockedIn:               │
 │                            │    find last CLOCK_IN event   │
 │                            │    compute sessionTime        │
 │                            │    startSessionTimer()        │
 │                            │    clockStatus = clockedIn    │
 │                            │                               │
 │                            │  if isOnBreak:                │
 │                            │    find last BREAK_START      │
 │                            │    compute breakTime          │
 │                            │    startBreakTimer()          │
 │                            │    clockStatus = onBreak      │
 │                            │                               │
 │  ←── state restored ───── │                               │
```

### 20.4 Optimistic Mark-Read Flow
```
User              NotificationsProvider          Backend
 │                        │                        │
 │  tap notification      │                        │
 │ ────────────────────→ │                        │
 │                        │                        │
 │  OPTIMISTIC:           │                        │
 │  _items[idx].isRead = true                     │
 │  notifyListeners()      │                        │
 │                        │                        │
 │  PATCH /notifications/{id}/read                │
 │ ────────────────────────────────────────────→ │
 │                        │                        │
 │  if FAILURE:           │                        │
 │  _items[idx].isRead = false (rollback)          │
 │  notifyListeners()      │                        │
 │                        │                        │
 │  ←── UI reflects ──── │                        │
```

### 20.5 Push Notification Flow
```
Backend                              FCM                      NotificationService          App
  │                                  │                              │                     │
  │  Send push (type + data)         │                              │                     │
  │ ──────────────────────────────→ │                              │                     │
  │                                  │                              │                     │
  │                                  │  ┌─ App state ──┐           │                     │
  │                                  │  │              │           │                     │
  │                                  │  │ Foreground   │─────────→ │  Show local notif   │
  │                                  │  │              │           │  via fl_notif       │
  │                                  │  │              │           │                     │
  │                                  │  │ Background   │─────────→ │  _handleNotifTap()  │
  │                                  │  │ → Foreground │           │  → pushNamed(route) │
  │                                  │  │              │           │                     │
  │                                  │  │ Terminated   │─────────→ │  getInitialMessage()│
  │                                  │  │              │           │  → pushNamed(route) │
  │                                  │  └──────────────┘           │                     │
```

### 20.6 Repository Pattern (Mock vs Real)
```
Provider
    │
    ├── UserRepository (interface)
    │       ├── ApiUserRepository ──── Dio ──── Real Backend ✅ (USED)
    │       └── StubUserRepository ──── Returns hardcoded data
    │
    ├── ClockRepository (interface)
    │       ├── ApiClockRepository ──── Dio ──── Real Backend
    │       └── MockClockRepository ──── 200ms delay + Berlin HQ ✅ (USED)
    │
    ├── AbsenceRepository (interface)
    │       ├── ApiAbsenceRepository ──── Dio ──── Real Backend
    │       └── MockAbsenceRepository ──── 12/24 days, 3 absences ✅ (USED)
    │
    ├── ShiftRepository (interface)
    │       ├── ApiShiftRepository ──── Dio ──── Real Backend
    │       └── MockShiftRepository ──── Single mock shift ✅ (USED)
    │
    ├── NotificationRepository (abstract)
    │       ├── NotificationRepositoryImpl ──── Dio ──── Real Backend (used when auth'd)
    │       └── NoOpNotificationRepo ──── All empty (used when logged out)
    │
    ├── ScheduleRepository (interface)
    │       └── MockScheduleRepository ──── 4 locations, 6 members ✅ (ONLY)
    │
    └── AnnouncementRepository (interface)
            ├── ApiAnnouncementRepository ──── Dio ──── Real Backend
            └── MockAnnouncementRepository ──── 1 German announcement ✅ (USED)
```

---

## Appendix A: Dependency Graph

```
flutter (SDK)
├── provider 6.1.5     → State management
├── dio 5.9.2          → HTTP client
├── geolocator 14.0.2   → GPS location
├── shared_preferences 2.5.4  → Local storage
├── file_picker 8.3.7  → Document upload
├── flutter_localizations (SDK) → i18n
├── intl 0.20.2        → Date/number formatting
├── cupertino_icons 1.0.8  → iOS icons
├── firebase_core      → Firebase init (not in pubspec? referenced in code)
├── firebase_messaging → FCM (not in pubspec? referenced in code)
├── flutter_local_notifications → Local push display (referenced in code)
└── uuid               → UUID generation (transitive)
```

> **Note:** Firebase packages (`firebase_core`, `firebase_messaging`) and `flutter_local_notifications` are imported in source code but may only be available as transitive/platform dependencies. Check `pubspec.lock` for exact versions.

## Appendix B: Key File Line Counts

| File | Lines | Purpose |
|---|---|---|
| `app_localizations.dart` | 954 | i18n English + German strings |
| `clock_provider.dart` | 446 | Clock state machine + geolocation |
| `README.md` | 445 | Project documentation |
| `api_client.dart` | 245 | Dio singleton + JWT interceptor |
| `schedule_provider.dart` | 225 | Schedule/scheduling state |
| `schedule_repository.dart` | 205 | Mock schedule data + CancelToken |
| `clock_repository.dart` | 196 | Clock in/out/break API + mock |
| `auth_provider.dart` | 173 | Authentication state machine |
| `PrefsService.dart` | 164 | SharedPreferences wrapper |
| `app_provider.dart` | 143 | MultiProvider wiring + async init |
| `workplace_location.dart` | 152 | Location model with geofence |
| `chat_provider.dart` | 142 | Chat with mock conversations |
| `absence.dart` | 140 | Absence model + enums |
| `user_model.dart` | 129 | User profile model |
| `notification_model.dart` | 127 | Notification model + helpers |
| `absence_repository.dart` | 119 | Absence API + mock |
| `app_theme.dart` | 107 | Material 3 ThemeData |
| `work_location_model.dart` | 98 | Geofence-aware location model |
| `shift_model.dart` | 93 | Shift model |
| `team_member_model.dart` | 86 | Team member model |
| `announcement_repository.dart` | 100 | Announcements API + mock |
| `notification_repository.dart` | 99 | Notifications NoOp + HTTP |
| `user_repository.dart` | 78 | User API + stub |
| `main.dart` | 57 | Entry point + route resolution |
| `locale_provider.dart` | 55 | Locale switching |
| `dashboard_provider.dart` | 63 | Dashboard data |
| `date_formatter.dart` | 48 | Date/time formatting |
| `device_token_repository.dart` | 44 | FCM token HTTP API |
| `api_config.dart` | 73 | All endpoint constants |
| `api_exceptions.dart` | 75 | Exception hierarchy |
| `app_colors.dart` | 52 | Color palette |
| `app_text_styles.dart` | 32 | Typography |
| `app_dimensions.dart` | 253 | Spacing/sizing constants |
| `validators.dart` | 26 | Form validation |
| `firebase-messaging-sw.js` | 93 | Web FCM service worker |
| `navigation_shell.dart` | 122 | 5-tab shell |
