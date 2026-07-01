import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

abstract class AppLocalizations {
  const AppLocalizations();

  static AppLocalizations of(BuildContext context) {
    final loc = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (loc == null) {
      throw FlutterError(
        'AppLocalizations.of() called with a context that does not contain '
        'an AppLocalizations. Add AppLocalizations.delegate to MaterialApp.',
      );
    }
    return loc;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('de'),
  ];

  // ── General ───────────────────────────────────────────────────────────────
  String get appName;
  String get appTagline;
  String get ok;
  String get cancel;
  String get save;
  String get retry;
  String get close;
  String get back;
  String get next;
  String get submit;
  String get loading;
  String get somethingWentWrong;
  String get noInternetConnection;
  String get requestTimedOut;
  String get sessionExpired;
  String get search;
  String get markAll;
  String get today;
  String get yesterday;
  String get earlier;
  String get all;
  String get unread;
  String get details;
  String get export;
  String get exportedSuccess;
  String get refreshLocation;
  String get currentSession;
  String get members;
  String get noShiftsDay;
  String get noShiftsScheduled;
  String get clockedIn;   // "CLOCKED IN" badge

  // ── Settings ──────────────────────────────────────────────────────────────
  String get settingsLanguage;

  // ── Login ─────────────────────────────────────────────────────────────────
  String get loginTitle;
  String get loginEmailLabel;
  String get loginEmailHint;
  String get loginPasswordLabel;
  String get loginForgotPassword;
  String get loginRememberMe;
  String get loginButton;
  String get loginNoAccount;
  String get loginSignUp;
  String get loginEmptyFields;
  String get loginWrongCredentials;

  // ── Sign-up ───────────────────────────────────────────────────────────────
  String get signUpTitle;
  String get signUpSubtitle;
  String signUpStep(int step, int total, String label);
  String get signUpStepPersonalDetails;
  String get signUpFullName;
  String get signUpFullNameHint;
  String get signUpWorkEmail;
  String get signUpWorkEmailHint;
  String get signUpEmployeeId;
  String get signUpEmployeeIdHint;
  String get signUpPassword;
  String get signUpPasswordHint;
  String get signUpButton;
  String get signUpHaveAccount;
  String get signUpLogIn;
  String signUpTerms(String termsLink, String privacyLink);
  String get signUpTermsOfService;
  String get signUpPrivacyPolicy;

  // ── Onboarding ────────────────────────────────────────────────────────────
  String get onboardingPage1Title;
  String get onboardingPage1Body;
  String get onboardingPage2Title;
  String get onboardingPage2Body;
  String get onboardingPage3Title;
  String get onboardingPage3Body;
  String get onboardingSkip;
  String get onboardingGetStarted;
  String get onboardingUpcomingShifts;
  String get onboardingTapToSwap;
  String get onboardingYourShift;
  String get onboardingTeamAvailability;
  String get onboardingInstantUpdates;

  // ── Navigation ────────────────────────────────────────────────────────────
  String get navDashboard;
  String get navSchedule;
  String get navTracking;
  String get navMessages;
  String get navMore;
  // legacy keys kept for any code that still uses them
  String get navHome;
  String get navClock;
  String get navChat;
  String get navNotifications;
  String get navMenu;

  // ── Dashboard ─────────────────────────────────────────────────────────────
  String get dashboardAnnouncements;
  String get dashboardViewAll;
  String get dashboardQuickActions;
  String get dashboardOpenShifts;
  String get dashboardOpenShiftsSubtitle;
  String get homeNoAnnouncements;
  String get homeNoOpenShifts;
  String get dashboardRequests;
  String get dashboardRequestsSubtitle;
  String get dashboardHandover;
  String get dashboardHandoverSubtitle;
  String get dashboardReports;
  String get dashboardWeeklySummary;
  String dashboardWeeklyHours(String logged, String target);
  String dashboardGreetingMorning(String name);
  String dashboardGreetingAfternoon(String name);
  String dashboardGreetingEvening(String name);
  String get dashboardNotClockedIn;
  String get dashboardTodayShift;
  String get dashboardClockInNow;

  // ── Clock ─────────────────────────────────────────────────────────────────
  String get clockTitle;
  String get clockOnDuty;
  String get clockNotClockedIn;
  String get clockLive;
  String get clockIn;
  String get clockOut;
  String get clockInNow;
  String get clockInSuccess;
  String clockOutSuccess(String session);
  String get clockStartBreak;
  String get clockEndBreak;
  String get clockEndBreakLabel;   // short label for active break button
  String get clockBreakLabel;      // short label "Break"
  String get clockRequestOverride;
  String get clockOutsideWorkZoneTitle;
  String get clockOutsideWorkZoneBody;
  String get clockRequestOverrideTitle;
  String get clockRequestOverrideBody;
  String get clockSendRequest;
  String get clockOverrideSent;
  String get clockOnDutyStatus;
  String get clockNotClockedInStatus;
  String get clockSessionActive;
  String get clockCurrentSession;
  String clockTodayShift(String time);
  String get clockTodaysShiftLabel;
  String get clockViewDetails;
  String get clockLocation;
  String get clockGettingLocation;
  String get clockWithinWorkZone;
  String get clockOutsideWorkZone;
  String get clockRecentActivity;
  String get clockNoActivityToday;
  String get clockLocationServicesDisabled;
  String get clockLocationPermissionDenied;
  String get clockLocationPermissionPermanentlyDenied;
  String get clockLocationFailed;
  String get clockDisclaimerClockIn;
  String get clockDisclaimerClockOut;
  String get clockBiometricReason;
  String get clockBiometricFailed;
  String get clockDisclaimerLocation;


 // ── Widget-level strings ─
/// Location status: user is inside the geofence  → "Within work zone"
  String get locationWithinZone;
 
  /// Location status: user is outside the geofence → "Outside work zone"
  String get locationOutsideZone;
 
  /// Appended after distance when outside zone     → "away"
  String get locationAway;
 
  /// OnDutyStatus badge label                      → "ON DUTY"
  String get dutyStatusOnDuty;
 
  /// OnDutyStatus badge label                      → "OFF DUTY"
  String get dutyStatusOffDuty;
 
  /// OnDutyStatus badge label                      → "ON BREAK"
  String get dutyStatusOnBreak;
 
  /// RecentActivityList section header             → "Recent Activity"
  String get recentActivityTitle;
  // ── Schedule ──────────────────────────────────────────────────────────────
  String get scheduleTitle;
  String get scheduleMySchedule;
  String get scheduleTeam;
  String get scheduleTeamTab;      // short "TEAM" label in segment
  String get scheduleMyShiftsTab;  // short "MY SHIFTS" label in segment
  String get scheduleCreateShift;
  String get scheduleExportTooltip;
  String get scheduleWeeklyProgress;
  String get scheduleMorningShift;
  String get scheduleEveningBackup;
  String get scheduleOnCall;
  String get scheduleClock;
  String get scheduleWeeklyCompletePercent;

  // ── Chat ──────────────────────────────────────────────────────────────────
  String get chatTitle;
  String get chatComingSoon;
  String get chatSearch;
  String get chatNoMessages;
  String get chatStartConversation;
  String get chatNewMessage;
  String get chatMessageHint;
  String get chatYouPrefix;
  String chatMemberCount(int count);
  String get chatFailedToLoad;

  // ── Notifications ─────────────────────────────────────────────────────────
  String get notificationsTitle;
  String get notificationsComingSoon;
  String get notificationsMarkAll;
  String get notificationsMarkAllRead;
  String get notificationsAll;
  String get notificationsUnread;
  String get notificationsArchiveHint;
  String get notificationsAllCaughtUp;
  String get notificationsNoneNew;
  String get notificationsFailedToLoad;
  String notificationsUnreadCount(int count);

  // ── Absences ──────────────────────────────────────────────────────────────
  String get absencesTitle;
  String get absencesUpcoming;
  String get absencesPast;
  String get absencesNoneUpcoming;
  String get absencesNonePast;
  String absenceWorkingDay(int count);
  String get absenceUsed;
  String get absenceRemaining;
  String get absenceTotal;
  String absenceValidUntil(String date);
  String get absenceTypeVacation;
  String get absenceTypeTraining;
  String get absenceTypeSickLeave;
  String get absenceTypePersonalDay;
  String get absenceStatusApproved;
  String get absenceStatusPending;
  String get absenceStatusRejected;
  String get newAbsenceTitle;
  String get newAbsenceType;
  String get newAbsenceStartDate;
  String get newAbsenceEndDate;
  String get newAbsenceSelectDate;
  String get newAbsenceReason;
  String get newAbsenceReasonHint;
  String get newAbsenceSubmit;
  String get newAbsenceMissingDates;
  String get newAbsenceInvalidDateRange;
  String get newAbsenceSuccess;
  String newAbsenceError(String message);

  // ── Profile ───────────────────────────────────────────────────────────────
  String get profileTitle;
  String get profileComingSoon;
  String get profileEditProfile;
  String get profileSignOut;
  String get profileSignOutConfirmTitle;
  String get profileSignOutConfirmBody;
  String get profileSectionWorkDetails;
  String get profileSectionEmployment;
  String get profileSectionDocuments;
  String get profileSectionSettings;
  String get profileSectionActions;
  String get profileDepartment;
  String get profileLocation;
  String get profileStartDate;
  String get profileContract;
  String get profileContractFullTime;
  String get profileVacationAccount;
  String get profileVacationSubtitle;
  String get profileTimeAccount;
  String get profileTimeAccountSubtitle;
  String get profileAvailability;
  String get profileAvailabilitySubtitle;
  String get profileAbsenceSubtitle;
  String get profileEmploymentContract;
  String get profileEmploymentContractSub;
  String get profilePaySlips;
  String get profilePaySlipsSub;
  String get profileHealthCert;
  String get profileHealthCertSub;
  String get profileUploadDocument;
  String get profileUploading;
  String get profileUploadSuccess;
  String get profileUploadFailed;
  String get profileDarkMode;
  String get profileChangePassword;
  String get profileExportData;
  String get profileDeleteAccount;
  String get profileDeleteConfirmTitle;
  String get profileDeleteConfirmBody;
  String get profileDelete;
  String get profilePasswordCurrent;
  String get profilePasswordNew;
  String get profilePasswordConfirm;
  String get profilePasswordChanged;
  String get profilePasswordMismatch;
  String get profileUpdated;
  String get profilePhone;
  String get profileSelectLanguage;
  String get teamScheduleTitle;
  String get teamScheduleComingSoon;

  // ── Validators ────────────────────────────────────────────────────────────
  String validatorRequired(String label);
  String get validatorThisFieldRequired;
  String get validatorEmail;
  String get validatorEmailRequired;
  String get validatorPasswordRequired;
  String get validatorPasswordLength;
  String validatorMinLength(String label, int min);
}

// ─────────────────────────────────────────────────────────────────────────────
// Delegate
// ─────────────────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'de'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      locale.languageCode == 'de'
          ? const _AppLocalizationsDe()
          : const _AppLocalizationsEn();

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
  
}

// ─────────────────────────────────────────────────────────────────────────────
// English
// ─────────────────────────────────────────────────────────────────────────────

class _AppLocalizationsEn extends AppLocalizations {
  const _AppLocalizationsEn();

  @override String get appName => 'Aplano';
  @override String get appTagline => 'Simplify your work schedule';
  @override String get ok => 'OK';
  @override String get cancel => 'Cancel';
  @override String get save => 'Save';
  @override String get retry => 'Retry';
  @override String get close => 'Close';
  @override String get back => 'Back';
  @override String get next => 'Next';
  @override String get submit => 'Submit';
  @override String get loading => 'Loading…';
  @override String get somethingWentWrong => 'Something went wrong';
  @override String get noInternetConnection => 'No internet connection.';
  @override String get requestTimedOut => 'The request timed out. Please try again.';
  @override String get sessionExpired => 'Your session has expired. Please log in again.';
  @override String get search => 'Search';
  @override String get markAll => 'Mark all';
  @override String get today => 'TODAY';
  @override String get yesterday => 'YESTERDAY';
  @override String get earlier => 'EARLIER';
  @override String get all => 'All';
  @override String get unread => 'Unread';
  @override String get details => 'Details';
  @override String get export => 'Export';
  @override String get exportedSuccess => 'Schedule exported';
  @override String get refreshLocation => 'Refresh Location';
  @override String get currentSession => 'Current Session Time';
  @override String get members => 'Members';
  @override String get noShiftsDay => 'No shifts on this day.';
  @override String get noShiftsScheduled => 'No shifts scheduled for this day.';
  @override String get clockedIn => 'CLOCKED IN';

  @override String get settingsLanguage => 'Language';

  @override String get loginTitle => 'Welcome back';
  @override String get loginEmailLabel => 'Email Address';
  @override String get loginEmailHint => 'Enter your email';
  @override String get loginPasswordLabel => 'Password';
  @override String get loginForgotPassword => 'Forgot Password?';
  @override String get loginRememberMe => 'Remember me';
  @override String get loginButton => 'Login';
  @override String get loginNoAccount => "Don't have an account? ";
  @override String get loginSignUp => 'Sign Up';
  @override String get loginEmptyFields => 'Please enter your email and password.';
  @override String get loginWrongCredentials => 'Incorrect email or password.';

  @override String get signUpTitle => 'Join your team';
  @override String get signUpSubtitle => 'Create your Aplano account to manage your schedule and track your work hours.';
  @override String signUpStep(int step, int total, String label) => 'Step $step of $total: $label';
  @override String get signUpStepPersonalDetails => 'Personal Details';
  @override String get signUpFullName => 'Full Name';
  @override String get signUpFullNameHint => 'e.g. John Doe';
  @override String get signUpWorkEmail => 'Work Email';
  @override String get signUpWorkEmailHint => 'name@company.com';
  @override String get signUpEmployeeId => 'Employee ID';
  @override String get signUpEmployeeIdHint => 'EMP-0000';
  @override String get signUpPassword => 'Password';
  @override String get signUpPasswordHint => 'Minimum 8 characters';
  @override String get signUpButton => 'Create Account';
  @override String get signUpHaveAccount => 'Already have an account? ';
  @override String get signUpLogIn => 'Log In';
  @override String signUpTerms(String t, String p) => 'By signing up, you agree to our $t and $p.';
  @override String get signUpTermsOfService => 'Terms of Service';
  @override String get signUpPrivacyPolicy => 'Privacy Policy';

  @override String get onboardingPage1Title => 'Track Your Time';
  @override String get onboardingPage1Body => 'Clocking in has never been easier. Log your work hours and breaks with just a single tap, keeping your schedule organized and accurate.';
  @override String get onboardingPage2Title => 'Manage Your Schedule';
  @override String get onboardingPage2Body => 'Stay on top of your shifts and see who else is working. Need a change? Request a swap in seconds.';
  @override String get onboardingPage3Title => 'Stay Connected';
  @override String get onboardingPage3Body => 'Get instant notifications for shift updates and stay in touch with your colleagues in real-time.';
  @override String get onboardingSkip => 'Skip';
  @override String get onboardingGetStarted => 'Get Started';
  @override String get onboardingUpcomingShifts => 'UPCOMING SHIFTS';
  @override String get onboardingTapToSwap => 'Tap to request swap';
  @override String get onboardingYourShift => 'YOUR SHIFT';
  @override String get onboardingTeamAvailability => "See your team's availability";
  @override String get onboardingInstantUpdates => 'Instant shift updates';

  @override String get navDashboard => 'Dashboard';
  @override String get navSchedule => 'Schedule';
  @override String get navTracking => 'Tracking';
  @override String get navMessages => 'Messages';
  @override String get navMore => 'More';
  @override String get navHome => 'Home';
  @override String get navClock => 'Clock';
  @override String get navChat => 'Chat';
  @override String get navNotifications => 'Notifications';
  @override String get navMenu => 'Menu';

  @override String get dashboardAnnouncements => 'Announcements';
  @override String get dashboardViewAll => 'View all';
  @override String get dashboardQuickActions => 'Quick Actions';
  @override String get dashboardOpenShifts => 'Open Shifts';
  @override String get dashboardOpenShiftsSubtitle => '4 available';
  @override String get homeNoAnnouncements => 'No announcements';
  @override String get homeNoOpenShifts => 'No open shifts right now';
  @override String get dashboardRequests => 'Requests';
  @override String get dashboardRequestsSubtitle => '1 pending';
  @override String get dashboardHandover => 'Handover';
  @override String get dashboardHandoverSubtitle => 'Start report';
  @override String get dashboardReports => 'Reports';
  @override String get dashboardWeeklySummary => 'Weekly Summary';
  @override String dashboardWeeklyHours(String l, String t) => '$l / $t hours logged';
  @override String dashboardGreetingMorning(String n) => 'Good morning, $n! 👋';
  @override String dashboardGreetingAfternoon(String n) => 'Good afternoon, $n! 👋';
  @override String dashboardGreetingEvening(String n) => 'Good evening, $n! 👋';
  @override String get dashboardNotClockedIn => 'Not Clocked In';
  @override String get dashboardTodayShift => "Today's Shift: 08:30 - 17:00";
  @override String get dashboardClockInNow => 'Clock In Now';

  @override String get clockTitle => 'Clock In';
  @override String get clockOnDuty => 'ON DUTY';
  @override String get clockNotClockedIn => 'NOT CLOCKED IN';
  @override String get clockLive => 'Live';
  @override String get clockIn => 'Clock In';
  @override String get clockOut => 'Clock Out';
  @override String get clockInNow => 'Clock In Now';
  @override String get clockInSuccess => 'Clocked in successfully';
  @override String clockOutSuccess(String s) => 'Clocked out — $s logged';
  @override String get clockStartBreak => 'Start Break';
  @override String get clockEndBreak => 'End Break';
  @override String get clockEndBreakLabel => 'End Break';
  @override String get clockBreakLabel => 'Break';
  @override String get clockRequestOverride => 'Request Location Override';
  @override String get clockOutsideWorkZoneTitle => 'Outside Work Zone';
  @override String get clockOutsideWorkZoneBody => 'You must be within the work zone to clock in.';
  @override String get clockRequestOverrideTitle => 'Request Override';
  @override String get clockRequestOverrideBody => 'Send a location override request to your manager? They will be notified and can approve your clock-in remotely.';
  @override String get clockSendRequest => 'Send Request';
  @override String get clockOverrideSent => 'Override request sent to manager';
  @override String get clockOnDutyStatus => 'On Duty';
  @override String get clockNotClockedInStatus => 'Not Clocked In';
  @override String get clockSessionActive => 'Session active';
  @override String get clockCurrentSession => 'Current Session Time';
  @override String clockTodayShift(String t) => "Today's Shift: $t";
  @override String get clockTodaysShiftLabel => "Today's Shift";
  @override String get clockViewDetails => 'View Details';
  @override String get clockLocation => 'Location';
  @override String get clockGettingLocation => 'Getting your location…';
  @override String get clockWithinWorkZone => 'You are within the work zone';
  @override String get clockOutsideWorkZone => 'You are outside the work zone';
  @override String get clockRecentActivity => 'Recent Activity';
  @override String get clockNoActivityToday => 'No activity yet today';
  @override String get clockLocationServicesDisabled => 'Location services are disabled. Please enable them in settings.';
  @override String get clockLocationPermissionDenied => 'Location permission denied. Please grant permission in settings.';
  @override String get clockLocationPermissionPermanentlyDenied => 'Location permissions are permanently denied. Please enable them in settings.';
  @override String get clockLocationFailed => 'Failed to get location';
  @override String get clockDisclaimerClockIn => 'Clock In: Must be within work zone.';
  @override String get clockDisclaimerClockOut => 'Clock Out: Can be done from anywhere.';
  @override String get clockBiometricReason => 'Authenticate to clock in';
  @override String get clockBiometricFailed => 'Biometric authentication failed';
  @override String get clockDisclaimerLocation => 'Your location is recorded for attendance verification.';

  @override String get scheduleTitle => 'Schedule';
  @override String get scheduleMySchedule => 'My Schedule';
  @override String get scheduleTeam => 'Team Schedule';
  @override String get scheduleTeamTab => 'TEAM';
  @override String get scheduleMyShiftsTab => 'MY SHIFTS';
  @override String get scheduleCreateShift => 'Create Shift';
  @override String get scheduleExportTooltip => 'Export schedule';
  @override String get scheduleWeeklyProgress => 'Weekly Progress';
  @override String get scheduleMorningShift => 'MORNING SHIFT';
  @override String get scheduleEveningBackup => 'EVENING BACKUP';
  @override String get scheduleOnCall => 'ON CALL';
  @override String get scheduleClock => 'Clock In';
  @override String get scheduleWeeklyCompletePercent => '% Complete';

  @override String get chatTitle => 'Messages';
  @override String get chatComingSoon => 'Chat coming soon';
  @override String get chatSearch => 'Search messages or teammates…';
  @override String get chatNoMessages => 'No messages yet';
  @override String get chatStartConversation => 'Start a conversation with your team.';
  @override String get chatNewMessage => 'New message';
  @override String get chatMessageHint => 'Message…';
  @override String get chatYouPrefix => 'You: ';
  @override String chatMemberCount(int c) => '$c members';
  @override String get chatFailedToLoad => 'Failed to load messages';

  @override String get notificationsTitle => 'Notifications';
  @override String get notificationsComingSoon => 'Notifications coming soon';
  @override String get notificationsMarkAll => 'Mark all';
  @override String get notificationsMarkAllRead => 'Mark all read';
  @override String get notificationsAll => 'All';
  @override String get notificationsUnread => 'Unread';
  @override String get notificationsArchiveHint => 'Swipe left to archive';
  @override String get notificationsAllCaughtUp => 'All caught up!';
  @override String get notificationsNoneNew => 'No new notifications.';
  @override String get notificationsFailedToLoad => 'Failed to load notifications';
  @override String notificationsUnreadCount(int c) => '$c unread';

  @override String get absencesTitle => 'Absences';
  @override String get absencesUpcoming => 'Upcoming Absences';
  @override String get absencesPast => 'Past Requests';
  @override String get absencesNoneUpcoming => 'No upcoming absences';
  @override String get absencesNonePast => 'No past requests';
  @override String absenceWorkingDay(int c) => c == 1 ? '1 working day' : '$c working days';
  @override String get absenceUsed => 'Used';
  @override String get absenceRemaining => 'Remaining';
  @override String get absenceTotal => 'Total';
  @override String absenceValidUntil(String d) => 'Valid until $d';
  @override String get absenceTypeVacation => 'Vacation';
  @override String get absenceTypeTraining => 'Training';
  @override String get absenceTypeSickLeave => 'Sick Leave';
  @override String get absenceTypePersonalDay => 'Personal Day';
  @override String get absenceStatusApproved => 'APPROVED';
  @override String get absenceStatusPending => 'PENDING';
  @override String get absenceStatusRejected => 'REJECTED';
  @override String get newAbsenceTitle => 'New Absence';
  @override String get newAbsenceType => 'Absence Type';
  @override String get newAbsenceStartDate => 'Start Date';
  @override String get newAbsenceEndDate => 'End Date';
  @override String get newAbsenceSelectDate => 'Select';
  @override String get newAbsenceReason => 'Reason (optional)';
  @override String get newAbsenceReasonHint => 'Briefly describe your absence…';
  @override String get newAbsenceSubmit => 'Submit Request';
  @override String get newAbsenceMissingDates => 'Please select start and end dates';
  @override String get newAbsenceInvalidDateRange => 'End date cannot be before start date';
  @override String get newAbsenceSuccess => 'Absence request submitted successfully';
  @override String newAbsenceError(String m) => 'Error: $m';

  @override String get profileTitle => 'Account & Profile';
  @override String get profileComingSoon => 'Profile coming soon';
  @override String get profileEditProfile => 'Edit Profile';
  @override String get profileSignOut => 'Sign Out';
  @override String get profileSignOutConfirmTitle => 'Sign out';
  @override String get profileSignOutConfirmBody => 'Are you sure you want to sign out?';
  @override String get profileSectionWorkDetails => 'WORK DETAILS';
  @override String get profileSectionEmployment => 'EMPLOYMENT OVERVIEW';
  @override String get profileSectionDocuments => 'DOCUMENT MANAGEMENT';
  @override String get profileSectionSettings => 'APP SETTINGS';
  @override String get profileSectionActions => 'ACCOUNT ACTIONS';
  @override String get profileDepartment => 'Department';
  @override String get profileLocation => 'Location';
  @override String get profileStartDate => 'Start Date';
  @override String get profileContract => 'Contract';
  @override String get profileContractFullTime => 'Full-time';
  @override String get profileVacationAccount => 'Vacation Account';
  @override String get profileVacationSubtitle => '24 days total per year';
  @override String get profileTimeAccount => 'Time Account';
  @override String get profileTimeAccountSubtitle => 'Current overtime balance';
  @override String get profileAvailability => 'Availability';
  @override String get profileAvailabilitySubtitle => 'Set your weekly routine';
  @override String get profileAbsenceSubtitle => 'History and requests';
  @override String get profileEmploymentContract => 'Employment Contract';
  @override String get profileEmploymentContractSub => 'PDF · Signed Jan 2022';
  @override String get profilePaySlips => 'Pay Slips';
  @override String get profilePaySlipsSub => 'Latest: October 2024';
  @override String get profileHealthCert => 'Health & Safety Cert.';
  @override String get profileHealthCertSub => 'Valid until Dec 2025';
  @override String get profileUploadDocument => 'Upload Document';
  @override String get profileUploading => 'Uploading…';
  @override String get profileUploadSuccess => 'uploaded';
  @override String get profileUploadFailed => 'Upload failed';
  @override String get profileDarkMode => 'Dark Mode';
  @override String get profileChangePassword => 'Change Password';
  @override String get profileExportData => 'Export My Data';
  @override String get profileDeleteAccount => 'Delete Account';
  @override String get profileDeleteConfirmTitle => 'Delete Account';
  @override String get profileDeleteConfirmBody => 'This action is permanent and cannot be undone. All your data will be deleted.';
  @override String get profileDelete => 'Delete';
  @override String get profilePasswordCurrent => 'Current Password';
  @override String get profilePasswordNew => 'New Password';
  @override String get profilePasswordConfirm => 'Confirm New Password';
  @override String get profilePasswordChanged => 'Password changed successfully';
  @override String get profilePasswordMismatch => 'Passwords do not match.';
  @override String get profileUpdated => 'Profile updated';
  @override String get profilePhone => 'Phone';
  @override String get profileSelectLanguage => 'Select Language';
  @override String get teamScheduleTitle => 'Team Schedule';
  @override String get teamScheduleComingSoon => 'Team Schedule coming soon';

  @override String validatorRequired(String label) => '$label is required';
  @override String get validatorThisFieldRequired => 'This field is required';
  @override String get validatorEmail => 'Enter a valid email address';
  @override String get validatorEmailRequired => 'Email is required';
  @override String get validatorPasswordRequired => 'Password is required';
  @override String get validatorPasswordLength => 'Password must be at least 8 characters';
  @override String validatorMinLength(String label, int min) => '$label must be at least $min characters';


// widget level
  @override String get locationWithinZone   => 'Within work zone';
  @override String get locationOutsideZone  => 'Outside work zone';
  @override String get locationAway         => 'away';
  @override String get dutyStatusOnDuty     => 'ON DUTY';
  @override String get dutyStatusOffDuty    => 'OFF DUTY';
  @override String get dutyStatusOnBreak    => 'ON BREAK';
  @override String get recentActivityTitle  => 'Recent Activity';
}

// ─────────────────────────────────────────────────────────────────────────────
// German
// ─────────────────────────────────────────────────────────────────────────────

class _AppLocalizationsDe extends AppLocalizations {
  const _AppLocalizationsDe();

  @override String get appName => 'Aplano';
  @override String get appTagline => 'Einfacher Schichtplan für dein Team';
  @override String get ok => 'OK';
  @override String get cancel => 'Abbrechen';
  @override String get save => 'Speichern';
  @override String get retry => 'Erneut versuchen';
  @override String get close => 'Schließen';
  @override String get back => 'Zurück';
  @override String get next => 'Weiter';
  @override String get submit => 'Absenden';
  @override String get loading => 'Laden…';
  @override String get somethingWentWrong => 'Etwas ist schiefgelaufen';
  @override String get noInternetConnection => 'Keine Internetverbindung.';
  @override String get requestTimedOut => 'Die Anfrage hat zu lange gedauert. Bitte erneut versuchen.';
  @override String get sessionExpired => 'Deine Sitzung ist abgelaufen. Bitte erneut anmelden.';
  @override String get search => 'Suchen';
  @override String get markAll => 'Alle markieren';
  @override String get today => 'HEUTE';
  @override String get yesterday => 'GESTERN';
  @override String get earlier => 'FRÜHER';
  @override String get all => 'Alle';
  @override String get unread => 'Ungelesen';
  @override String get details => 'Details';
  @override String get export => 'Exportieren';
  @override String get exportedSuccess => 'Schichtplan exportiert';
  @override String get refreshLocation => 'Standort aktualisieren';
  @override String get currentSession => 'Aktuelle Sitzungszeit';
  @override String get members => 'Mitglieder';
  @override String get noShiftsDay => 'Keine Schichten an diesem Tag.';
  @override String get noShiftsScheduled => 'Keine Schichten für diesen Tag geplant.';
  @override String get clockedIn => 'EINGESTEMPELT';

  @override String get settingsLanguage => 'Sprache';

  @override String get loginTitle => 'Willkommen zurück';
  @override String get loginEmailLabel => 'E-Mail-Adresse';
  @override String get loginEmailHint => 'E-Mail eingeben';
  @override String get loginPasswordLabel => 'Passwort';
  @override String get loginForgotPassword => 'Passwort vergessen?';
  @override String get loginRememberMe => 'Angemeldet bleiben';
  @override String get loginButton => 'Anmelden';
  @override String get loginNoAccount => 'Noch kein Konto? ';
  @override String get loginSignUp => 'Registrieren';
  @override String get loginEmptyFields => 'Bitte E-Mail und Passwort eingeben.';
  @override String get loginWrongCredentials => 'E-Mail oder Passwort ist falsch.';

  @override String get signUpTitle => 'Deinem Team beitreten';
  @override String get signUpSubtitle => 'Erstelle dein Aplano-Konto, um deinen Schichtplan zu verwalten.';
  @override String signUpStep(int s, int t, String l) => 'Schritt $s von $t: $l';
  @override String get signUpStepPersonalDetails => 'Persönliche Daten';
  @override String get signUpFullName => 'Vollständiger Name';
  @override String get signUpFullNameHint => 'z. B. Max Mustermann';
  @override String get signUpWorkEmail => 'Geschäftliche E-Mail';
  @override String get signUpWorkEmailHint => 'name@unternehmen.de';
  @override String get signUpEmployeeId => 'Mitarbeiter-ID';
  @override String get signUpEmployeeIdHint => 'MA-0000';
  @override String get signUpPassword => 'Passwort';
  @override String get signUpPasswordHint => 'Mindestens 8 Zeichen';
  @override String get signUpButton => 'Konto erstellen';
  @override String get signUpHaveAccount => 'Bereits ein Konto? ';
  @override String get signUpLogIn => 'Anmelden';
  @override String signUpTerms(String t, String p) => 'Mit der Registrierung stimmst du unseren $t und $p zu.';
  @override String get signUpTermsOfService => 'Nutzungsbedingungen';
  @override String get signUpPrivacyPolicy => 'Datenschutzerklärung';

  @override String get onboardingPage1Title => 'Arbeitszeit erfassen';
  @override String get onboardingPage1Body => 'Ein- und Ausstempeln war noch nie so einfach. Erfasse deine Arbeitszeiten mit nur einem Tipper.';
  @override String get onboardingPage2Title => 'Schichtplan verwalten';
  @override String get onboardingPage2Body => 'Behalte deine Schichten im Blick. Schichttausch? In Sekunden beantragt.';
  @override String get onboardingPage3Title => 'Immer verbunden';
  @override String get onboardingPage3Body => 'Erhalte sofortige Benachrichtigungen und bleib in Echtzeit mit deinen Kollegen in Kontakt.';
  @override String get onboardingSkip => 'Überspringen';
  @override String get onboardingGetStarted => 'Loslegen';
  @override String get onboardingUpcomingShifts => 'BEVORSTEHENDE SCHICHTEN';
  @override String get onboardingTapToSwap => 'Tippen zum Schichttausch';
  @override String get onboardingYourShift => 'DEINE SCHICHT';
  @override String get onboardingTeamAvailability => 'Teamverfügbarkeit einsehen';
  @override String get onboardingInstantUpdates => 'Sofortige Schichtbenachrichtigungen';

  @override String get navDashboard => 'Übersicht';
  @override String get navSchedule => 'Schichtplan';
  @override String get navTracking => 'Stempeln';
  @override String get navMessages => 'Nachrichten';
  @override String get navMore => 'Mehr';
  @override String get navHome => 'Start';
  @override String get navClock => 'Stempeln';
  @override String get navChat => 'Chat';
  @override String get navNotifications => 'Benachrichtigungen';
  @override String get navMenu => 'Menü';

  @override String get dashboardAnnouncements => 'Ankündigungen';
  @override String get dashboardViewAll => 'Alle anzeigen';
  @override String get dashboardQuickActions => 'Schnellaktionen';
  @override String get dashboardOpenShifts => 'Offene Schichten';
  @override String get dashboardOpenShiftsSubtitle => '4 verfügbar';
  @override String get homeNoAnnouncements => 'Keine Ankündigungen';
  @override String get homeNoOpenShifts => 'Derzeit keine offenen Schichten';
  @override String get dashboardRequests => 'Anfragen';
  @override String get dashboardRequestsSubtitle => '1 ausstehend';
  @override String get dashboardHandover => 'Übergabe';
  @override String get dashboardHandoverSubtitle => 'Bericht starten';
  @override String get dashboardReports => 'Berichte';
  @override String get dashboardWeeklySummary => 'Wochenzusammenfassung';
  @override String dashboardWeeklyHours(String l, String t) => '$l / $t Stunden erfasst';
  @override String dashboardGreetingMorning(String n) => 'Guten Morgen, $n! 👋';
  @override String dashboardGreetingAfternoon(String n) => 'Guten Tag, $n! 👋';
  @override String dashboardGreetingEvening(String n) => 'Guten Abend, $n! 👋';
  @override String get dashboardNotClockedIn => 'Nicht eingestempelt';
  @override String get dashboardTodayShift => 'Heutige Schicht: 08:30 - 17:00';
  @override String get dashboardClockInNow => 'Jetzt einstempeln';

  @override String get clockTitle => 'Einstempeln';
  @override String get clockOnDuty => 'IM DIENST';
  @override String get clockNotClockedIn => 'NICHT EINGESTEMPELT';
  @override String get clockLive => 'Live';
  @override String get clockIn => 'Einstempeln';
  @override String get clockOut => 'Ausstempeln';
  @override String get clockInNow => 'Jetzt einstempeln';
  @override String get clockInSuccess => 'Erfolgreich eingestempelt';
  @override String clockOutSuccess(String s) => 'Ausgestempelt – $s erfasst';
  @override String get clockStartBreak => 'Pause starten';
  @override String get clockEndBreak => 'Pause beenden';
  @override String get clockEndBreakLabel => 'Pause beenden';
  @override String get clockBreakLabel => 'Pause';
  @override String get clockRequestOverride => 'Standort-Ausnahme beantragen';
  @override String get clockOutsideWorkZoneTitle => 'Außerhalb der Arbeitszone';
  @override String get clockOutsideWorkZoneBody => 'Du musst dich in der Arbeitszone befinden, um einzustempeln.';
  @override String get clockRequestOverrideTitle => 'Ausnahme beantragen';
  @override String get clockRequestOverrideBody => 'Eine Standort-Ausnahme an deinen Vorgesetzten senden? Er kann dein Einstempeln aus der Ferne genehmigen.';
  @override String get clockSendRequest => 'Anfrage senden';
  @override String get clockOverrideSent => 'Ausnahme-Anfrage gesendet';
  @override String get clockOnDutyStatus => 'Im Dienst';
  @override String get clockNotClockedInStatus => 'Nicht eingestempelt';
  @override String get clockSessionActive => 'Sitzung aktiv';
  @override String get clockCurrentSession => 'Aktuelle Sitzungszeit';
  @override String clockTodayShift(String t) => 'Heutige Schicht: $t';
  @override String get clockTodaysShiftLabel => 'Heutige Schicht';
  @override String get clockViewDetails => 'Details anzeigen';
  @override String get clockLocation => 'Standort';
  @override String get clockGettingLocation => 'Standort wird ermittelt…';
  @override String get clockWithinWorkZone => 'Du befindest dich in der Arbeitszone';
  @override String get clockOutsideWorkZone => 'Du befindest dich außerhalb der Arbeitszone';
  @override String get clockRecentActivity => 'Letzte Aktivitäten';
  @override String get clockNoActivityToday => 'Heute noch keine Aktivitäten';
  @override String get clockLocationServicesDisabled => 'Standortdienste deaktiviert. Bitte in Einstellungen aktivieren.';
  @override String get clockLocationPermissionDenied => 'Standortberechtigung verweigert. Bitte in Einstellungen erlauben.';
  @override String get clockLocationPermissionPermanentlyDenied => 'Standortberechtigung dauerhaft verweigert. Bitte in Einstellungen aktivieren.';
  @override String get clockLocationFailed => 'Standort konnte nicht ermittelt werden';
  @override String get clockDisclaimerClockIn => 'Einstempeln: Nur in der Arbeitszone möglich.';
  @override String get clockDisclaimerClockOut => 'Ausstempeln: Von überall möglich.';
  @override String get clockBiometricReason => 'Zum Einstempeln authentifizieren';
  @override String get clockBiometricFailed => 'Biometrische Authentifizierung fehlgeschlagen';
  @override String get clockDisclaimerLocation => 'Dein Standort wird zur Anwesenheitsprüfung erfasst.';

  @override String get scheduleTitle => 'Schichtplan';
  @override String get scheduleMySchedule => 'Mein Schichtplan';
  @override String get scheduleTeam => 'Teamschichtplan';
  @override String get scheduleTeamTab => 'TEAM';
  @override String get scheduleMyShiftsTab => 'MEINE SCHICHTEN';
  @override String get scheduleCreateShift => 'Schicht erstellen';
  @override String get scheduleExportTooltip => 'Schichtplan exportieren';
  @override String get scheduleWeeklyProgress => 'Wochenfortschritt';
  @override String get scheduleMorningShift => 'FRÜHSCHICHT';
  @override String get scheduleEveningBackup => 'ABENDBEREITSCHAFT';
  @override String get scheduleOnCall => 'BEREITSCHAFT';
  @override String get scheduleClock => 'Einstempeln';
  @override String get scheduleWeeklyCompletePercent => '% abgeschlossen';

  @override String get chatTitle => 'Nachrichten';
  @override String get chatComingSoon => 'Chat – demnächst verfügbar';
  @override String get chatSearch => 'Nachrichten oder Kollegen suchen…';
  @override String get chatNoMessages => 'Noch keine Nachrichten';
  @override String get chatStartConversation => 'Starte ein Gespräch mit deinem Team.';
  @override String get chatNewMessage => 'Neue Nachricht';
  @override String get chatMessageHint => 'Nachricht…';
  @override String get chatYouPrefix => 'Du: ';
  @override String chatMemberCount(int c) => '$c Mitglieder';
  @override String get chatFailedToLoad => 'Nachrichten konnten nicht geladen werden';

  @override String get notificationsTitle => 'Benachrichtigungen';
  @override String get notificationsComingSoon => 'Benachrichtigungen – demnächst verfügbar';
  @override String get notificationsMarkAll => 'Alle markieren';
  @override String get notificationsMarkAllRead => 'Alle als gelesen markieren';
  @override String get notificationsAll => 'Alle';
  @override String get notificationsUnread => 'Ungelesen';
  @override String get notificationsArchiveHint => 'Nach links wischen zum Archivieren';
  @override String get notificationsAllCaughtUp => 'Du bist auf dem neuesten Stand!';
  @override String get notificationsNoneNew => 'Keine neuen Benachrichtigungen.';
  @override String get notificationsFailedToLoad => 'Benachrichtigungen konnten nicht geladen werden';
  @override String notificationsUnreadCount(int c) => '$c ungelesen';

  @override String get absencesTitle => 'Abwesenheiten';
  @override String get absencesUpcoming => 'Bevorstehende Abwesenheiten';
  @override String get absencesPast => 'Vergangene Anfragen';
  @override String get absencesNoneUpcoming => 'Keine bevorstehenden Abwesenheiten';
  @override String get absencesNonePast => 'Keine vergangenen Anfragen';
  @override String absenceWorkingDay(int c) => c == 1 ? '1 Arbeitstag' : '$c Arbeitstage';
  @override String get absenceUsed => 'Genutzt';
  @override String get absenceRemaining => 'Verbleibend';
  @override String get absenceTotal => 'Gesamt';
  @override String absenceValidUntil(String d) => 'Gültig bis $d';
  @override String get absenceTypeVacation => 'Urlaub';
  @override String get absenceTypeTraining => 'Weiterbildung';
  @override String get absenceTypeSickLeave => 'Krankheit';
  @override String get absenceTypePersonalDay => 'Persönlicher Tag';
  @override String get absenceStatusApproved => 'GENEHMIGT';
  @override String get absenceStatusPending => 'AUSSTEHEND';
  @override String get absenceStatusRejected => 'ABGELEHNT';
  @override String get newAbsenceTitle => 'Neue Abwesenheit';
  @override String get newAbsenceType => 'Abwesenheitsart';
  @override String get newAbsenceStartDate => 'Startdatum';
  @override String get newAbsenceEndDate => 'Enddatum';
  @override String get newAbsenceSelectDate => 'Auswählen';
  @override String get newAbsenceReason => 'Grund (optional)';
  @override String get newAbsenceReasonHint => 'Abwesenheit kurz beschreiben…';
  @override String get newAbsenceSubmit => 'Anfrage stellen';
  @override String get newAbsenceMissingDates => 'Bitte Start- und Enddatum auswählen';
  @override String get newAbsenceInvalidDateRange => 'Enddatum darf nicht vor Startdatum liegen';
  @override String get newAbsenceSuccess => 'Abwesenheitsantrag erfolgreich eingereicht';
  @override String newAbsenceError(String m) => 'Fehler: $m';

  @override String get profileTitle => 'Konto & Profil';
  @override String get profileComingSoon => 'Profil – demnächst verfügbar';
  @override String get profileEditProfile => 'Profil bearbeiten';
  @override String get profileSignOut => 'Abmelden';
  @override String get profileSignOutConfirmTitle => 'Abmelden';
  @override String get profileSignOutConfirmBody => 'Möchtest du dich wirklich abmelden?';
  @override String get profileSectionWorkDetails => 'ARBEITSDETAILS';
  @override String get profileSectionEmployment => 'BESCHÄFTIGUNGSÜBERSICHT';
  @override String get profileSectionDocuments => 'DOKUMENTENVERWALTUNG';
  @override String get profileSectionSettings => 'APP-EINSTELLUNGEN';
  @override String get profileSectionActions => 'KONTOAKTIONEN';
  @override String get profileDepartment => 'Abteilung';
  @override String get profileLocation => 'Standort';
  @override String get profileStartDate => 'Eintrittsdatum';
  @override String get profileContract => 'Vertrag';
  @override String get profileContractFullTime => 'Vollzeit';
  @override String get profileVacationAccount => 'Urlaubskonto';
  @override String get profileVacationSubtitle => '24 Tage gesamt pro Jahr';
  @override String get profileTimeAccount => 'Zeitkonto';
  @override String get profileTimeAccountSubtitle => 'Aktuelles Überstundensaldo';
  @override String get profileAvailability => 'Verfügbarkeit';
  @override String get profileAvailabilitySubtitle => 'Wöchentliche Routine festlegen';
  @override String get profileAbsenceSubtitle => 'Verlauf und Anträge';
  @override String get profileEmploymentContract => 'Arbeitsvertrag';
  @override String get profileEmploymentContractSub => 'PDF · Unterzeichnet Jan 2022';
  @override String get profilePaySlips => 'Gehaltsabrechnungen';
  @override String get profilePaySlipsSub => 'Aktuell: Oktober 2024';
  @override String get profileHealthCert => 'Sicherheitszertifikat';
  @override String get profileHealthCertSub => 'Gültig bis Dez 2025';
  @override String get profileUploadDocument => 'Dokument hochladen';
  @override String get profileUploading => 'Wird hochgeladen…';
  @override String get profileUploadSuccess => 'hochgeladen';
  @override String get profileUploadFailed => 'Upload fehlgeschlagen';
  @override String get profileDarkMode => 'Dunkelmodus';
  @override String get profileChangePassword => 'Passwort ändern';
  @override String get profileExportData => 'Daten exportieren';
  @override String get profileDeleteAccount => 'Konto löschen';
  @override String get profileDeleteConfirmTitle => 'Konto löschen';
  @override String get profileDeleteConfirmBody => 'Diese Aktion ist endgültig. Alle deine Daten werden gelöscht.';
  @override String get profileDelete => 'Löschen';
  @override String get profilePasswordCurrent => 'Aktuelles Passwort';
  @override String get profilePasswordNew => 'Neues Passwort';
  @override String get profilePasswordConfirm => 'Passwort bestätigen';
  @override String get profilePasswordChanged => 'Passwort erfolgreich geändert';
  @override String get profilePasswordMismatch => 'Passwörter stimmen nicht überein.';
  @override String get profileUpdated => 'Profil aktualisiert';
  @override String get profilePhone => 'Telefon';
  @override String get profileSelectLanguage => 'Sprache auswählen';
  @override String get teamScheduleTitle => 'Teamschichtplan';
  @override String get teamScheduleComingSoon => 'Teamschichtplan – demnächst verfügbar';

  @override String validatorRequired(String label) => '$label ist erforderlich';
  @override String get validatorThisFieldRequired => 'Dieses Feld ist erforderlich';
  @override String get validatorEmail => 'Gültige E-Mail-Adresse eingeben';
  @override String get validatorEmailRequired => 'E-Mail-Adresse ist erforderlich';
  @override String get validatorPasswordRequired => 'Passwort ist erforderlich';
  @override String get validatorPasswordLength => 'Passwort muss mindestens 8 Zeichen lang sein';
  @override String validatorMinLength(String label, int min) => '$label muss mindestens $min Zeichen lang sein';
  // widget level
   @override String get locationWithinZone   => 'In der Arbeitszone';
  @override String get locationOutsideZone  => 'Außerhalb der Arbeitszone';
  @override String get locationAway         => 'entfernt';
  @override String get dutyStatusOnDuty     => 'IM DIENST';
  @override String get dutyStatusOffDuty    => 'NICHT IM DIENST';
  @override String get dutyStatusOnBreak    => 'IN DER PAUSE';
  @override String get recentActivityTitle  => 'Letzte Aktivitäten';
}