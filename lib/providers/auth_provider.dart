import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

enum AuthStatus { unauthenticated, loading, authenticated, error }

/// Manages authentication state and the currently signed-in [UserModel].
///
/// Consumed anywhere in the tree via:
///   context.watch<AuthProvider>()
///   context.read<AuthProvider>()
class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unauthenticated;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status       => _status;
  UserModel? get user         => _user;
  String?    get errorMessage => _errorMessage;
  bool       get isLoggedIn   => _status == AuthStatus.authenticated;

  /// Sign in with email and password.
  /// Replace the body with a real API call.
  Future<void> signIn({required String email, required String password}) async {
    _setStatus(AuthStatus.loading);
    try {
      // TODO: replace with real auth service
      await Future.delayed(const Duration(milliseconds: 800));
      _user = UserModel(
        id: 'u-001',
        firstName: 'Alex',
        lastName: 'Johnson',
        email: email,
        role: 'employee',
      );
      _setStatus(AuthStatus.authenticated);
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(AuthStatus.error);
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    _user = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  void _setStatus(AuthStatus s) {
    _status = s;
    notifyListeners();
  }
}