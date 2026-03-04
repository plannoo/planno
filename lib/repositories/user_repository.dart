import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_exceptions.dart';
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
}

// ── Real implementation ───────────────────────────────────────────────────────

class ApiUserRepository implements UserRepository {
   ApiUserRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  @override
  Future<UserModel> getMe() async {
    try {
      final data = await _client.get(ApiConfig.me) as Map<String, dynamic>;
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
      final data = await _client.patch(
        ApiConfig.updateProfile,
        data: fields,
      ) as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ParseException('Failed to parse updated profile: $e');
    }
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
    // TODO: wire to real API
    await Future.delayed(const Duration(milliseconds: 300));
    throw UnimplementedError('updateProfile is not yet implemented.');
  }
}