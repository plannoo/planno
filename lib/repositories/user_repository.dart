import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../core/network/api_exceptions.dart';
import '../models/user_model.dart';

// ── Interface ─────────────────────────────────────────────────────────────────

abstract interface class UserRepository {
  /// Fetches the currently authenticated user's profile.
  /// Throws an [ApiException] on failure.
  Future<UserModel> getMe();

  /// Updates the current user's profile.
  /// [fields] should contain only the fields to update (PATCH semantics).
  /// Throws an [ApiException] on failure.
  Future<UserModel> updateProfile(Map<String, dynamic> fields);

  /// Changes the current user's password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Returns the current user's 4-digit clock-in PIN.
  Future<String> getClockPin();

  /// Generates and returns a new 4-digit clock-in PIN.
  Future<String> regenerateClockPin();
}

// ── Real implementation ───────────────────────────────────────────────────────

class ApiUserRepository implements UserRepository {
   ApiUserRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  @override
  Future<UserModel> getMe() async {
    try {
      final res  = await _client.get(ApiConfig.me) as Map<String, dynamic>;
      final data = (res['data'] ?? res) as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ParseException('Failed to parse user profile: $e');
    }
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> fields) async {
    try {
      final res  = await _client.patch(
        ApiConfig.updateProfile,
        data: fields,
      ) as Map<String, dynamic>;
      final data = (res['data'] ?? res) as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ParseException('Failed to parse updated profile: $e');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _client.post(ApiConfig.changePassword, data: {
        'currentPassword': currentPassword,
        'newPassword':     newPassword,
      });
    } on ApiException { rethrow; }
    catch (e) { throw UnknownException('Failed to change password: $e'); }
  }

  @override
  Future<String> getClockPin() async {
    try {
      final res = await _client.get(ApiConfig.clockPin) as Map<String, dynamic>;
      final data = (res['data'] ?? res) as Map<String, dynamic>;
      return data['pin'] as String;
    } on ApiException { rethrow; }
    catch (e) { throw UnknownException('Failed to get clock PIN: $e'); }
  }

  @override
  Future<String> regenerateClockPin() async {
    try {
      final res = await _client.post(ApiConfig.regeneratePin) as Map<String, dynamic>;
      final data = (res['data'] ?? res) as Map<String, dynamic>;
      return data['pin'] as String;
    } on ApiException { rethrow; }
    catch (e) { throw UnknownException('Failed to regenerate clock PIN: $e'); }
  }
}

// ── Stub implementation (used until the real API is ready) ────────────────────

class StubUserRepository implements UserRepository {
  @override
  Future<UserModel> getMe() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const UserModel(
      id: 'u-001',
      email: 'alex.johnson@aplano.io',
      firstName: 'Alex',
      lastName: 'Johnson',
      role: 'employee',
      phone: '+49 170 0000000',
      assignedLocationIds: ['loc-1'],
    );
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> fields) async {
    await Future.delayed(const Duration(milliseconds: 300));
    throw UnimplementedError('updateProfile is not yet implemented.');
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<String> getClockPin() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return '0003';
  }

  @override
  Future<String> regenerateClockPin() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return String.fromCharCodes(
      List.generate(4, (_) => 48 + (DateTime.now().millisecondsSinceEpoch % 9) + 1),
    );
  }
}