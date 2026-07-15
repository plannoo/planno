import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show kReleaseMode, kIsWeb, debugPrint;

import '../services/prefs_service.dart';
import 'api_config.dart';
import 'api_exceptions.dart';

/// Singleton Dio-based HTTP client for the Wrenta API.
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
        headers: {
          'Content-Type':    'application/json',
          'Accept':          'application/json',
          'Accept-Language': 'en',
        },
      ),
    );

    // Certificate pinning — only on native (non-web) platforms
    if (!kIsWeb && _pinnedHashes.isNotEmpty) {
      final adapter = _dio.httpClientAdapter;
      if (adapter is IOHttpClientAdapter) {
        adapter.createHttpClient = () {
          final client = HttpClient();
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) {
            final digest = sha256.convert(utf8.encode(cert.pem));
            final hex = digest.toString();
            final matched = _pinnedHashes.any((pin) => hex.contains(pin));
            if (!matched) {
              debugPrint('[ApiClient] Certificate pin mismatch for $host');
            }
            return matched;
          };
          return client;
        };
      }
    }

    final interceptors = <Interceptor>[
      _AuthInterceptor(_dio),
    ];

    if (!kReleaseMode) {
      interceptors.add(
        LogInterceptor(
          requestBody:  true,
          responseBody: true,
          logPrint: (o) => debugPrint('[ApiClient] $o'),
        ),
      );
    }

    _dio.interceptors.addAll(interceptors);
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  /// SHA-256 hashes of pinned server certificate public keys.
  ///
  /// Generate with:
  /// ```bash
  /// openssl s_client -connect api.wrenta.io:443 -showcerts </dev/null 2>/dev/null |
  ///   openssl x509 -pubkey -noout |
  ///   openssl pkey -pubin -outform DER |
  ///   openssl dgst -sha256
  /// ```
  /// Replace the values below with the actual hashes for your deployment.
  ///
  /// In dev/staging, set the `API_CERT_PINS` environment variable as a
  /// comma-separated list of hex-encoded SHA-256 hashes:
  ///   --dart-define=API_CERT_PINS=abc123...,def456...
  static final List<String> _pinnedHashes = (() {
    const encoded = String.fromEnvironment('API_CERT_PINS');
    if (encoded.isEmpty) return <String>[];
    return encoded.split(',').map((s) => s.trim()).toList();
  })();

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
    dynamic data,
    Options? options,
  }) =>
      _request(() => _dio.delete(path, data: data, options: options));

  /// POST with exponential backoff + jitter on network/timeout errors.
  /// Use for high-contention endpoints (e.g. 500 users clocking in at 08:00).
  Future<dynamic> postWithRetry(
    String path, {
    dynamic data,
    int maxAttempts = 3,
  }) async {
    final rng = Random();
    for (var i = 0; i < maxAttempts; i++) {
      try {
        return await post(path, data: data);
      } on NetworkException {
        if (i == maxAttempts - 1) rethrow;
        await Future.delayed(Duration(seconds: (1 << i) + rng.nextInt(3)));
      } on RequestTimeoutException {
        if (i == maxAttempts - 1) rethrow;
        await Future.delayed(Duration(seconds: (1 << i) + rng.nextInt(3)));
      }
    }
  }

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
      final message = body['message'] ?? body['error'];
      if (message != null) return message.toString();

      final details = body['details'];
      if (details is List && details.isNotEmpty) {
        final first = details.first;
        if (first is Map<String, dynamic>) {
          return first['message']?.toString() ?? 'Server error';
        }
      }

      return 'Server error';
    }
    return 'Server error';
  }

  static Map<String, List<String>> _extractFieldErrors(dynamic body) {
    if (body is! Map<String, dynamic>) return {};

    if (body['errors'] is Map) {
      final raw = body['errors'] as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(
            k,
            v is List ? v.map((e) => e.toString()).toList() : [v.toString()],
          ));
    }

    if (body['details'] is List) {
      final raw = body['details'] as List;
      final result = <String, List<String>>{};
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          final field = item['field']?.toString() ?? '';
          final message = item['message']?.toString() ?? '';
          result.putIfAbsent(field, () => []).add(message);
        }
      }
      return result;
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

  /// A single in-flight refresh shared by all concurrent 401s.
  ///
  /// Without this, when several requests fire at once (e.g. the clock page
  /// loading work-location + session + activities together) and the access
  /// token has just expired, only the first request would refresh while the
  /// others bubbled the 401 straight up as UnauthorizedException. Now every
  /// concurrent 401 awaits the same refresh and then retries.
  Future<bool>? _refreshFuture;

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
    final is401         = err.response?.statusCode == 401;
    final isRefreshPath = err.requestOptions.path == ApiConfig.refreshToken;
    // Don't loop forever if the retried request also 401s.
    final alreadyRetried = err.requestOptions.extra['retriedAfterRefresh'] == true;

    if (!is401 || isRefreshPath || alreadyRetried) {
      handler.next(err);
      return;
    }

    // Join the in-flight refresh, or start one. All concurrent 401s share it.
    final refreshed = await (_refreshFuture ??= _runRefresh());

    if (!refreshed) {
      handler.reject(err);
      return;
    }

    try {
      // Retry the original request once with the new token.
      final token = await PrefsService.getAccessToken();
      err.requestOptions.headers['Authorization'] = 'Bearer $token';
      err.requestOptions.extra['retriedAfterRefresh'] = true;
      final retried = await _dio.fetch(err.requestOptions);
      handler.resolve(retried);
    } on DioException catch (e) {
      handler.reject(e);
    }
  }

  /// Performs the refresh exactly once; resets the shared future when done so
  /// a later expiry can refresh again. Returns true on success.
  Future<bool> _runRefresh() async {
    try {
      await _doRefresh();
      return true;
    } catch (_) {
      await PrefsService.clearTokens();
      return false;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<void> _doRefresh() async {
    final refreshToken = await PrefsService.getRefreshToken();
    if (refreshToken == null) throw const UnauthorizedException();

    final response = await _dio.post(
      ApiConfig.refreshToken,
      data: {'refreshToken': refreshToken},
      // Skip this interceptor for the refresh call itself
      options: Options(extra: {'skipAuthInterceptor': true}),
    );

    final data = response.data as Map<String, dynamic>;
    await PrefsService.saveTokens(
      accessToken:  data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String? ??
          (await PrefsService.getRefreshToken())!,
    );
  }
}