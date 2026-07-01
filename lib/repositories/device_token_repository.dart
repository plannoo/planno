import '../core/network/api_client.dart';
import '../core/network/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Abstract interface — makes the service testable via mocks
// ─────────────────────────────────────────────────────────────────────────────
abstract class DeviceTokenRepository {
  Future<void> registerToken({required String token, required String platform});
  Future<void> removeToken({required String token});
  Future<void> removeAllTokens();
}

// ─────────────────────────────────────────────────────────────────────────────
// HTTP implementation
// ─────────────────────────────────────────────────────────────────────────────
class DeviceTokenRepositoryImpl implements DeviceTokenRepository {
  const DeviceTokenRepositoryImpl({required ApiClient apiClient})
      : _api = apiClient;

  final ApiClient _api;

  @override
  Future<void> registerToken({
    required String token,
    required String platform,
  }) async {
    await _api.post(
      ApiConfig.deviceTokens,
      data: {'token': token, 'platform': platform},
    );
  }

  @override
  Future<void> removeToken({required String token}) async {
    await _api.delete(ApiConfig.deviceTokens,
        data: {'token': token});
  }

  @override
  Future<void> removeAllTokens() async {
    await _api.delete(ApiConfig.deviceTokensAll);
  }
}
