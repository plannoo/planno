import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../core/network/api_exceptions.dart';
import '../core/services/notification_service.dart';
import '../core/services/prefs_service.dart';
import '../models/user_model.dart';
import '../repositories/device_token_repository.dart';
import '../repositories/user_repository.dart';

enum AuthStatus { unauthenticated, loading, authenticated, error }

/// Manages authentication state and the currently signed-in [UserModel].
///
/// Consumed anywhere in the tree via `context.watch` or `context.read`.
class AuthProvider extends ChangeNotifier {
  // Set to true in main.dart to bypass login for UI testing.
  static bool bypassForTesting = false;

  AuthProvider({
    UserRepository? userRepository,
    DeviceTokenRepository? tokenRepository,
  })  : _userRepository = userRepository ?? ApiUserRepository(),
      _tokenRepo = tokenRepository {
    if (bypassForTesting) {
      _user = const UserModel(
        id: 'test-employee-001',
        email: 'employee@wrenta.com',
        firstName: 'Test',
        lastName: 'Employee',
        role: 'employee',
      );
      _status = AuthStatus.authenticated;
    }
  }

  final UserRepository _userRepository;
  final DeviceTokenRepository? _tokenRepo;

  AuthStatus _status       = AuthStatus.unauthenticated;
  UserModel? _user;
  String?    _errorMessage;

  AuthStatus get status       => _status;
  UserModel? get user         => _user;
  String?    get errorMessage => _errorMessage;
  bool       get isLoggedIn   => _status == AuthStatus.authenticated;

  // ── RBAC helpers ─────────────────────────────────────────────────────────
  /// Normalized role string (uppercase, empty when logged out).
  String     get _role        => (_user?.role ?? '').toUpperCase();
  /// True for ADMIN or MANAGER — can access team-wide admin pages.
  bool       get isAdmin      => _role == 'ADMIN' || _role == 'MANAGER';
  /// True for MANAGER only.
  bool       get isManager    => _role == 'MANAGER';
  /// True for ADMIN only — can access destructive org-level settings.
  bool       get isSuperAdmin => _role == 'ADMIN';

  // ── Boot-time refresh check ──────────────────────────────────────────────────

  /// Called once from [main] before the widget tree renders.
  ///
  /// If a valid refresh token exists the method silently fetches a new access
  /// token and loads the user profile, restoring the session without requiring
  /// the user to log in again.
  Future<void> tryRestoreSession() async {
    final loggedIn = await PrefsService.isLoggedIn();
    if (!loggedIn) return; // Nothing stored → stay unauthenticated

    _setStatus(AuthStatus.loading);
    try {
      // Attempt a token refresh to validate the stored session.
      final refreshToken = await PrefsService.getRefreshToken();
      if (refreshToken == null) throw const UnauthorizedException();

      final response = await ApiClient.instance.post(
        ApiConfig.refreshToken,
        data: {'refreshToken': refreshToken},
      ) as Map<String, dynamic>;

      await PrefsService.saveTokens(
        accessToken:  response['accessToken']  as String,
        refreshToken: response['refreshToken'] as String? ?? refreshToken,
      );

      // Load the user profile with the fresh access token.
      _user = await _userRepository.getMe();
      _setStatus(AuthStatus.authenticated);
      _registerPushToken();
    } on UnauthorizedException {
      // Stored session is no longer valid — clear and show login.
      await PrefsService.clearTokens();
      _setStatus(AuthStatus.unauthenticated);
    } on NetworkException {
      // Offline — keep the stored session as-is but stay unauthenticated
      // so the user is prompted to sign in when connectivity returns.
      
      _setStatus(AuthStatus.unauthenticated);
    } catch (e) {
      debugPrint('tryRestoreSession failed: $e');
      await PrefsService.clearTokens();
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  // ── Register ────────────────────────────────────────────────────────────────

  Future<void> register({
    required String orgName,
    required String orgSlug,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _clearError();
    _setStatus(AuthStatus.loading);
    try {
      final body = await ApiClient.instance.post(
        ApiConfig.register,
        data: {
          'orgName':   orgName,
          'orgSlug':   orgSlug,
          'email':     email,
          'password':  password,
          'firstName': firstName,
          'lastName':  lastName,
        },
      ) as Map<String, dynamic>;

      final accessToken  = body['accessToken']  as String;
      final refreshToken = body['refreshToken'] as String;

      await PrefsService.saveTokens(
        accessToken:  accessToken,
        refreshToken: refreshToken,
      );
      await PrefsService.saveLoginSession(
        email: email,
        name: '$firstName $lastName',
      );

      _user = await _userRepository.getMe();
      _setStatus(AuthStatus.authenticated);
      _registerPushToken();
    } on ValidationException catch (e) {
      _errorMessage = e.message;
      _setStatus(AuthStatus.error);
    } on UnauthorizedException {
      _errorMessage = 'Registration failed. Please try again.';
      _setStatus(AuthStatus.error);
    } on NetworkException {
      _errorMessage = 'No internet connection. Please check your network.';
      _setStatus(AuthStatus.error);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setStatus(AuthStatus.error);
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      _setStatus(AuthStatus.error);
    }
  }

  // ── Sign in ──────────────────────────────────────────────────────────────────

  /// Authenticates via `POST /api/auth/login` and stores the returned tokens.
  ///
  /// On success [status] becomes [AuthStatus.authenticated] and [user] is
  /// populated with the profile returned by `GET /api/users/me`.
  /// On failure [status] becomes [AuthStatus.error] and [errorMessage] is set.
  Future<void> signIn({
    required String email,
    required String password,
    bool rememberEmail = false,
  }) async {
    _clearError();
    _setStatus(AuthStatus.loading);
    try {
      // 1. Exchange credentials for tokens.
      final body = await ApiClient.instance.post(
        ApiConfig.login,
        data: {'email': email, 'password': password},
      ) as Map<String, dynamic>;

      final accessToken  = body['accessToken']  as String;
      final refreshToken = body['refreshToken'] as String;

      // 2. Persist tokens and session metadata.
      await PrefsService.saveTokens(
        accessToken:  accessToken,
        refreshToken: refreshToken,
      );
      await PrefsService.saveLoginSession(
        email: email,
        rememberEmail: rememberEmail,
      );

      // 3. Fetch the full user profile now that we have a valid token.
      _user = await _userRepository.getMe();

      // 4. Persist name for offline display.
      await PrefsService.saveLoginSession(
        email: email,
        name: _user!.fullName,
        rememberEmail: rememberEmail,
      );

      _setStatus(AuthStatus.authenticated);
      _registerPushToken();
    } on ValidationException catch (e) {
      _errorMessage = e.message;
      _setStatus(AuthStatus.error);
    } on UnauthorizedException {
      _errorMessage = 'Incorrect email or password.';
      _setStatus(AuthStatus.error);
    } on NetworkException {
      _errorMessage = 'No internet connection. Please check your network.';
      _setStatus(AuthStatus.error);
    } on RequestTimeoutException {
      _errorMessage = 'Request timed out. Please try again.';
      _setStatus(AuthStatus.error);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setStatus(AuthStatus.error);
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      _setStatus(AuthStatus.error);
    }
  }

  // ── Refresh user ─────────────────────────────────────────────────────────────

  Future<void> refreshUser() async {
    try {
      _user = await _userRepository.getMe();
      notifyListeners();
    } catch (_) {}
  }

  // ── Sign out ──────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    // Deregister FCM token so push notifications stop after logout
    if (_tokenRepo != null) {
      await NotificationService.instance.onLogout(_tokenRepo);
    }

    try {
      final refreshToken = await PrefsService.getRefreshToken();
      if (refreshToken != null) {
        await ApiClient.instance.post(
          ApiConfig.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Best-effort: proceed with local logout even if server call fails
    }

    await PrefsService.logout();
    _user = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Register the FCM push token now that we're authenticated. Fire-and-forget;
  /// failures are non-fatal (the app still works without push).
  void _registerPushToken() {
    NotificationService.instance.onLogin();
  }

  void _setStatus(AuthStatus s) {
    _status = s;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}