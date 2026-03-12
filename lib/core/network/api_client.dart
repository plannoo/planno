import 'package:dio/dio.dart';

import '../services/prefs_service.dart';
import 'api_config.dart';
import 'api_exceptions.dart';

/// Singleton Dio-based HTTP client for the Aplano API.
///
/// Features:
///  • Attaches `Authorization: Bearer <token>` to every request.
///  • On 401 attempts a single token refresh, then retries the original request.
///  • Maps Dio errors to typed [ApiException] subclasses so callers never
///    need to import Dio.
///
/// Usage:
/// ```dart
/// final client = ApiClient.instance;
/// final data   = await client.get('/api/users/me');
/// ```
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl:        ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout:    ApiConfig.sendTimeout,
        headers: const {
          'Content-Type': 'application/json',
          'Accept':       'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_dio),
      LogInterceptor(
        requestBody:  true,
        responseBody: true,
        logPrint: (o) => print('[ApiClient] $o'), // ignore: avoid_print
      ),
    ]);
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  // ── Public helpers ──────────────────────────────────────────────────────────

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _request(
        () => _dio.get(path,
            queryParameters: queryParameters, options: options),
      );

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _request(
        () => _dio.post(path,
            data: data, queryParameters: queryParameters, options: options),
      );

  Future<dynamic> put(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _request(() => _dio.put(path, data: data, options: options));

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _request(() => _dio.patch(path, data: data, options: options));

  Future<dynamic> delete(
    String path, {
    Options? options,
  }) =>
      _request(() => _dio.delete(path, options: options));

  // ── Internal ────────────────────────────────────────────────────────────────

  Future<dynamic> _request(Future<Response> Function() call) async {
    try {
      final response = await call();
      return response.data;
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  static ApiException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const RequestTimeoutException();

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        return _mapHttpError(e.response);

      case DioExceptionType.cancel:
        return const UnknownException('Request was cancelled.');

      default:
        return UnknownException(e.message ?? 'Unknown error.');
    }
  }

  static ApiException _mapHttpError(Response? response) {
    if (response == null) return const UnknownException();

    final body    = response.data;
    final message = _extractMessage(body);

    switch (response.statusCode) {
      case 401:
        return const UnauthorizedException();
      case 403:
        return const ForbiddenException();
      case 404:
        return NotFoundException(message);
      case 422:
        final fieldErrors = _extractFieldErrors(body);
        return ValidationException(message, fieldErrors: fieldErrors);
      default:
            final statusCode = response.statusCode ?? 0;
        if (statusCode >= 500) {
          return ServerException(message, statusCode: statusCode);
        }
        // Consider adding ClientException for 4xx errors
        return ServerException(message, statusCode: statusCode);
     }
  }

  static String _extractMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      return (body['message'] ?? body['error'] ?? 'Server error').toString();
    }
    return 'Server error';
  }

  static Map<String, List<String>> _extractFieldErrors(dynamic body) {
    if (body is Map<String, dynamic> && body['errors'] is Map) {
      final raw = body['errors'] as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(
            k,
            v is List ? v.map((e) => e.toString()).toList() : [v.toString()],
          ));
    }
    return {};
  }
}

// ── Auth interceptor ──────────────────────────────────────────────────────────

/// Attaches the JWT Bearer token to every outgoing request.
/// On a 401 response, attempts a single token refresh then retries.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuthInterceptor'] == true) {
      handler.next(options);
      return;
    }
    final token = await PrefsService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only attempt refresh on 401, and not on the refresh endpoint itself
    final is401         = err.response?.statusCode == 401;
    final isRefreshPath = err.requestOptions.path == ApiConfig.refreshToken;

    if (is401 && !isRefreshPath && !_isRefreshing) {
      _isRefreshing = true;
      try {
        await _doRefresh();
        // Retry the original request with the new token
        final token = await PrefsService.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        final retried = await _dio.fetch(err.requestOptions);
        handler.resolve(retried);
        return;
      } catch (_) {
        // Refresh failed — propagate as UnauthorizedException
        await PrefsService.clearTokens();
        handler.reject(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }

  Future<void> _doRefresh() async {
    final refreshToken = await PrefsService.getRefreshToken();
    if (refreshToken == null) throw const UnauthorizedException();

    final response = await _dio.post(
      ApiConfig.refreshToken,
      data: {'refresh_token': refreshToken},
      // Skip this interceptor for the refresh call itself
      options: Options(extra: {'skipAuthInterceptor': true}),
    );

    final data = response.data as Map<String, dynamic>;
    await PrefsService.saveTokens(
      accessToken:  data['access_token'] as String,
      refreshToken: data['refresh_token'] as String? ??
          (await PrefsService.getRefreshToken())!,
    );
  }
}