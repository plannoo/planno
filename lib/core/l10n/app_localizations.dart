import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// ─────────────────────────────────────────────────────────────────────────────
// HOW TO USE
// ─────────────────────────────────────────────────────────────────────────────
//
// 1. Add to MaterialApp:
//      localizationsDelegates: AppLocalizations.localizationsDelegates,
//      supportedLocales:       AppLocalizations.supportedLocales,
//
// 2. Access strings anywhere you have a BuildContext:
//      final l10n = AppLocalizations.of(context);
//      Text(l10n.loginButton)
//
// 3. To add a new locale:
//      a. Add the ARB file  lib/l10n/app_<code>.arb
//      b. Add a new _AppLocalizationsXx subclass below (copy _AppLocalizationsDe)
//      c. Add the locale to supportedLocales and the switch in _AppLocalizationsDelegate.load
//
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppLocalizations {
  const AppLocalizations();

  static AppLocalizations of(BuildContext context) {
    final loc = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (loc == null) {
      throw FlutterError(
        'AppLocalizations.of() was called with a context that does not contain an AppLocalizations.\n'
        'Make sure localizationsDelegates includes AppLocalizations.delegate.',
      );
    }
    return loc;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Convenience list to pass to MaterialApp.localizationsDelegates.
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

  // ── General ─────────────────────────────────────────────────────────────────
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

  // ── Settings ───────────────────────────────────────────────────────────────────
  String get settingsLanguage;

  // ── Login ────────────────────────────────────────────────────────────────────
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

  // ── Sign-up ──────────────────────────────────────────────────────────────────
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

  // ── Onboarding ───────────────────────────────────────────────────────────────
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

  // ── Navigation ───────────────────────────────────────────────────────────────
  String get navHome;
  String get navSchedule;
  String get navClock;
  String get navChat;
  String get navNotifications;
  String get navMenu;

  // ── Dashboard ────────────────────────────────────────────────────────────────
  String get dashboardAnnouncements;
  String get dashboardViewAll;
  String get dashboardQuickActions;
  String get dashboardOpenShifts;
  String get dashboardOpenShiftsSubtitle;
  String get dashboardRequests;
  String get dashboardRequestsSubtitle;
  String get dashboardHandover;
  String get dashboardHandoverSubtitle;
  String get dashboardWeeklySummary;
  String dashboardWeeklyHours(String logged, String target);
  String dashboardGreetingMorning(String name);
  String dashboardGreetingAfternoon(String name);
  String dashboardGreetingEvening(String name);

  // ── Clock ─────────────────────────────────────────────────────────────────────
  String get clockOnDuty;
  String get clockNotClockedIn;
  String get clockLive;
  String get clockIn;
  String get clockOut;
  String get clockInNow;
  String get clockedIn;
  String get clockInSuccess;
  String clockOutSuccess(String session);
  String get clockStartBreak;
  String get clockEndBreak;
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
  String clockTodayShift(String time);
  String get clockTodaysShiftLabel;
  String get clockViewDetails;
  String get clockLocation;
  String get clockGettingLocation;
  String get clockWithinWorkZone;
  String get clockOutsideWorkZone;
  String get clockRecentActivity;
  String get clockNoActivityToday;

  // ── Absences ──────────────────────────────────────────────────────────────────
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

  // ── Placeholder screens ───────────────────────────────────────────────────────
  String get teamScheduleTitle;
  String get teamScheduleComingSoon;
  String get chatTitle;
  String get chatComingSoon;
  String get notificationsTitle;
  String get notificationsComingSoon;
  String get profileTitle;
  String get profileComingSoon;

  // ── Validators ────────────────────────────────────────────────────────────────
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
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'de':
        return const _AppLocalizationsDe();
      default:
        return const _AppLocalizationsEn();
    }
  }

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
  @override String get noInternetConnection => 'No internet connection. Please check your network.';
  @override String get requestTimedOut => 'The request timed out. Please try again.';
  @override String get sessionExpired => 'Your session has expired. Please log in again.';

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
  @override String signUpTerms(String termsLink, String privacyLink) => 'By signing up, you agree to our $termsLink and $privacyLink.';
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

  @override String get navHome => 'Home';
  @override String get navSchedule => 'Schedule';
  @override String get navClock => 'Clock';
  @override String get navChat => 'Chat';
  @override String get navNotifications => 'Notifications';
  @override String get navMenu => 'Menu';

  @override String get dashboardAnnouncements => 'Announcements';
  @override String get dashboardViewAll => 'View all';
  @override String get dashboardQuickActions => 'Quick Actions';
  @override String get dashboardOpenShifts => 'Open Shifts';
  @override String get dashboardOpenShiftsSubtitle => '4 available';
  @override String get dashboardRequests => 'Requests';
  @override String get dashboardRequestsSubtitle => '1 pending';
  @override String get dashboardHandover => 'Handover';
  @override String get dashboardHandoverSubtitle => 'Start report';
  @override String get dashboardWeeklySummary => 'Weekly Summary';
  @override String dashboardWeeklyHours(String logged, String target) => '$logged / $target hours logged';
  @override String dashboardGreetingMorning(String name) => 'Good morning, $name! 👋';
  @override String dashboardGreetingAfternoon(String name) => 'Good afternoon, $name! 👋';
  @override String dashboardGreetingEvening(String name) => 'Good evening, $name! 👋';

  @override String get clockOnDuty => 'ON DUTY';
  @override String get clockNotClockedIn => 'NOT CLOCKED IN';
  @override String get clockLive => 'Live';
  @override String get clockIn => 'Clock In';
  @override String get clockOut => 'Clock Out';
  @override String get clockInNow => 'Clock In Now';
  @override String get clockedIn => 'Clocked In';
  @override String get clockInSuccess => 'Clocked in successfully';
  @override String clockOutSuccess(String session) => 'Clocked out - $session logged';
  @override String get clockStartBreak => 'Start Break';
  @override String get clockEndBreak => 'End Break';
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
  @override String clockTodayShift(String time) => "Today's Shift: $time";
  @override String get clockTodaysShiftLabel => "Today's Shift";
  @override String get clockViewDetails => 'View Details';
  @override String get clockLocation => 'Location';
  @override String get clockGettingLocation => 'Getting your location…';
  @override String get clockWithinWorkZone => 'You are within the work zone';
  @override String get clockOutsideWorkZone => 'You are outside the work zone';
  @override String get clockRecentActivity => 'Recent Activity';
  @override String get clockNoActivityToday => 'No activity yet today';

  @override String get absencesTitle => 'Absences';
  @override String get absencesUpcoming => 'Upcoming Absences';
  @override String get absencesPast => 'Past Requests';
  @override String get absencesNoneUpcoming => 'No upcoming absences';
  @override String get absencesNonePast => 'No past requests';
  @override String absenceWorkingDay(int count) => count == 1 ? '1 working day' : '$count working days';
  @override String get absenceUsed => 'Used';
  @override String get absenceRemaining => 'Remaining';
  @override String get absenceTotal => 'Total';
  @override String absenceValidUntil(String date) => 'Valid until $date';
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
  @override String newAbsenceError(String message) => 'Error: $message';

  @override String get teamScheduleTitle => 'Team Schedule';
  @override String get teamScheduleComingSoon => 'Team Schedule coming soon';
  @override String get chatTitle => 'Chat';
  @override String get chatComingSoon => 'Chat coming soon';
  @override String get notificationsTitle => 'Notifications';
  @override String get notificationsComingSoon => 'Notifications coming soon';
  @override String get profileTitle => 'Profile';
  @override String get profileComingSoon => 'Profile coming soon';

  @override String validatorRequired(String label) => '$label is required';
  @override String get validatorThisFieldRequired => 'This field is required';
  @override String get validatorEmail => 'Enter a valid email address';
  @override String get validatorEmailRequired => 'Email is required';
  @override String get validatorPasswordRequired => 'Password is required';
  @override String get validatorPasswordLength => 'Password must be at least 8 characters';
  @override String validatorMinLength(String label, int min) => '$label must be at least $min characters';
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
  @override String get noInternetConnection => 'Keine Internetverbindung. Bitte überprüfe deine Verbindung.';
  @override String get requestTimedOut => 'Die Anfrage hat zu lange gedauert. Bitte versuche es erneut.';
  @override String get sessionExpired => 'Deine Sitzung ist abgelaufen. Bitte melde dich erneut an.';

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
  @override String get loginEmptyFields => 'Bitte gib E-Mail-Adresse und Passwort ein.';
  @override String get loginWrongCredentials => 'E-Mail-Adresse oder Passwort ist falsch.';

  @override String get signUpTitle => 'Deinem Team beitreten';
  @override String get signUpSubtitle => 'Erstelle dein Aplano-Konto, um deinen Schichtplan zu verwalten und deine Arbeitszeiten zu erfassen.';
  @override String signUpStep(int step, int total, String label) => 'Schritt $step von $total: $label';
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
  @override String signUpTerms(String termsLink, String privacyLink) => 'Mit der Registrierung stimmst du unseren $termsLink und unserer $privacyLink zu.';
  @override String get signUpTermsOfService => 'Nutzungsbedingungen';
  @override String get signUpPrivacyPolicy => 'Datenschutzerklärung';

  @override String get onboardingPage1Title => 'Arbeitszeit erfassen';
  @override String get onboardingPage1Body => 'Ein- und Ausstempeln war noch nie so einfach. Erfasse deine Arbeitszeiten und Pausen mit nur einem Tipper – übersichtlich und genau.';
  @override String get onboardingPage2Title => 'Schichtplan verwalten';
  @override String get onboardingPage2Body => 'Behalte deine Schichten im Blick und sieh, wer sonst noch arbeitet. Schichttausch? In Sekunden beantragt.';
  @override String get onboardingPage3Title => 'Immer verbunden';
  @override String get onboardingPage3Body => 'Erhalte sofortige Benachrichtigungen bei Schichtänderungen und bleib in Echtzeit mit deinen Kollegen in Kontakt.';
  @override String get onboardingSkip => 'Überspringen';
  @override String get onboardingGetStarted => 'Loslegen';
  @override String get onboardingUpcomingShifts => 'BEVORSTEHENDE SCHICHTEN';
  @override String get onboardingTapToSwap => 'Tippen zum Schichttausch';
  @override String get onboardingYourShift => 'DEINE SCHICHT';

  @override String get navHome => 'Start';
  @override String get navSchedule => 'Schichtplan';
  @override String get navClock => 'Stempeln';
  @override String get navChat => 'Chat';
  @override String get navNotifications => 'Benachrichtigungen';
  @override String get navMenu => 'Menü';

  @override String get dashboardAnnouncements => 'Ankündigungen';
  @override String get dashboardViewAll => 'Alle anzeigen';
  @override String get dashboardQuickActions => 'Schnellaktionen';
  @override String get dashboardOpenShifts => 'Offene Schichten';
  @override String get dashboardOpenShiftsSubtitle => '4 verfügbar';
  @override String get dashboardRequests => 'Anfragen';
  @override String get dashboardRequestsSubtitle => '1 ausstehend';
  @override String get dashboardHandover => 'Übergabe';
  @override String get dashboardHandoverSubtitle => 'Bericht starten';
  @override String get dashboardWeeklySummary => 'Wochenzusammenfassung';
  @override String dashboardWeeklyHours(String logged, String target) => '$logged / $target Stunden erfasst';
  @override String dashboardGreetingMorning(String name) => 'Guten Morgen, $name! 👋';
  @override String dashboardGreetingAfternoon(String name) => 'Guten Tag, $name! 👋';
  @override String dashboardGreetingEvening(String name) => 'Guten Abend, $name! 👋';

  @override String get clockOnDuty => 'IM DIENST';
  @override String get clockNotClockedIn => 'NICHT EINGESTEMPELT';
  @override String get clockLive => 'Live';
  @override String get clockIn => 'Einstempeln';
  @override String get clockOut => 'Ausstempeln';
  @override String get clockInNow => 'Jetzt einstempeln';
  @override String get clockedIn => 'Eingestempelt';
  @override String get clockInSuccess => 'Erfolgreich eingestempelt';
  @override String clockOutSuccess(String session) => 'Ausgestempelt – $session erfasst';
  @override String get clockStartBreak => 'Pause starten';
  @override String get clockEndBreak => 'Pause beenden';
  @override String get clockRequestOverride => 'Standort-Ausnahme beantragen';
  @override String get clockOutsideWorkZoneTitle => 'Außerhalb der Arbeitszone';
  @override String get clockOutsideWorkZoneBody => 'Du musst dich innerhalb der Arbeitszone befinden, um dich einzustempeln.';
  @override String get clockRequestOverrideTitle => 'Ausnahme beantragen';
  @override String get clockRequestOverrideBody => 'Eine Standort-Ausnahme an deinen Vorgesetzten senden? Er wird benachrichtigt und kann dein Einstempeln aus der Ferne genehmigen.';
  @override String get clockSendRequest => 'Anfrage senden';
  @override String get clockOverrideSent => 'Ausnahme-Anfrage an Vorgesetzten gesendet';
  @override String get clockOnDutyStatus => 'Im Dienst';
  @override String get clockNotClockedInStatus => 'Nicht eingestempelt';
  @override String get clockSessionActive => 'Sitzung aktiv';
  @override String clockTodayShift(String time) => 'Heutige Schicht: $time';
  @override String get clockTodaysShiftLabel => 'Heutige Schicht';
  @override String get clockViewDetails => 'Details anzeigen';
  @override String get clockLocation => 'Standort';
  @override String get clockGettingLocation => 'Standort wird ermittelt…';
  @override String get clockWithinWorkZone => 'Du befindest dich in der Arbeitszone';
  @override String get clockOutsideWorkZone => 'Du befindest dich außerhalb der Arbeitszone';
  @override String get clockRecentActivity => 'Letzte Aktivitäten';
  @override String get clockNoActivityToday => 'Heute noch keine Aktivitäten';

  @override String get absencesTitle => 'Abwesenheiten';
  @override String get absencesUpcoming => 'Bevorstehende Abwesenheiten';
  @override String get absencesPast => 'Vergangene Anfragen';
  @override String get absencesNoneUpcoming => 'Keine bevorstehenden Abwesenheiten';
  @override String get absencesNonePast => 'Keine vergangenen Anfragen';
  @override String absenceWorkingDay(int count) => count == 1 ? '1 Arbeitstag' : '$count Arbeitstage';
  @override String get absenceUsed => 'Genutzt';
  @override String get absenceRemaining => 'Verbleibend';
  @override String get absenceTotal => 'Gesamt';
  @override String absenceValidUntil(String date) => 'Gültig bis $date';
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
  @override String get newAbsenceInvalidDateRange => 'Das Enddatum darf nicht vor dem Startdatum liegen';
  @override String get newAbsenceSuccess => 'Abwesenheitsantrag erfolgreich eingereicht';
  @override String newAbsenceError(String message) => 'Fehler: $message';

  @override String get teamScheduleTitle => 'Teamschichtplan';
  @override String get teamScheduleComingSoon => 'Teamschichtplan – demnächst verfügbar';
  @override String get chatTitle => 'Chat';
  @override String get chatComingSoon => 'Chat – demnächst verfügbar';
  @override String get notificationsTitle => 'Benachrichtigungen';
  @override String get notificationsComingSoon => 'Benachrichtigungen – demnächst verfügbar';
  @override String get profileTitle => 'Profil';
  @override String get profileComingSoon => 'Profil – demnächst verfügbar';

  @override String validatorRequired(String label) => '$label ist erforderlich';
  @override String get validatorThisFieldRequired => 'Dieses Feld ist erforderlich';
  @override String get validatorEmail => 'Gültige E-Mail-Adresse eingeben';
  @override String get validatorEmailRequired => 'E-Mail-Adresse ist erforderlich';
  @override String get validatorPasswordRequired => 'Passwort ist erforderlich';
  @override String get validatorPasswordLength => 'Das Passwort muss mindestens 8 Zeichen lang sein';
  @override String validatorMinLength(String label, int min) => '$label muss mindestens $min Zeichen lang sein';
}