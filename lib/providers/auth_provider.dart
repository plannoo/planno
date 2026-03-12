import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/services/prefs_service.dart';
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';

enum AuthStatus { unauthenticated, loading, authenticated, error }

/// Manages authentication state and the currently signed-in [UserModel].
///
/// Consumed anywhere in the tree via:
///   context.watch<AuthProvider>()
///   context.read<AuthProvider>()
class AuthProvider extends ChangeNotifier {
  AuthProvider({UserRepository? userRepository})
      : _userRepository = userRepository ?? ApiUserRepository();

  final UserRepository _userRepository;

  AuthStatus _status       = AuthStatus.unauthenticated;
  UserModel? _user;
  String?    _errorMessage;

  AuthStatus get status       => _status;
  UserModel? get user         => _user;
  String?    get errorMessage => _errorMessage;
  bool       get isLoggedIn   => _status == AuthStatus.authenticated;

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
        data: {'refresh_token': refreshToken},
      ) as Map<String, dynamic>;

      await PrefsService.saveTokens(
        accessToken:  response['access_token']  as String,
        refreshToken: response['refresh_token'] as String? ?? refreshToken,
      );

      // Load the user profile with the fresh access token.
      _user = await _userRepository.getMe();
      _setStatus(AuthStatus.authenticated);
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

      final accessToken  = body['access_token']  as String;
      final refreshToken = body['refresh_token'] as String;

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

  // ── Sign out ──────────────────────────────────────────────────────────────────

  // TODO: implement logout — call DELETE /api/auth/logout, then clearTokens()
  Future<void> signOut() async {
    _user = null;
    await PrefsService.logout();
    _setStatus(AuthStatus.unauthenticated);
    await PrefsService.clearTokens();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _setStatus(AuthStatus s) {
    _status = s;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}