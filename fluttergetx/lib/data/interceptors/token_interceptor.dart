import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/core/error/retry_policy.dart';

/*
 * TokenInterceptor
 *
 * Responsibilities:
 * - Detect ERR_UNAUTHORIZED/TOKEN_EXPIRED responses and perform a single silent refresh using
 *   the refresh token in FlutterSecureStorage.
 * - Queue concurrent requests during refresh and retry them after success.
 * - On refresh failure, clear stored tokens and reject queued requests so the
 *   app can force re-authentication.
 * - Apply exponential backoff retry for rate limiting (429/ERR_VALIDATION with rate limit).
 *
 * Usage:
 * - Attach this interceptor to the single Dio instance used app-wide:
 *     final dio = Dio(BaseOptions(baseUrl: ...));
 *     dio.interceptors.add(TokenInterceptor(FlutterSecureStorage(), dio));
 * - Use relative endpoint paths (e.g. 'refresh-token') so Dio.options.baseUrl applies.
 */

class _Pending {
  final RequestOptions request;
  final Completer<Response> completer;
  _Pending(this.request) : completer = Completer<Response>();
}

class TokenInterceptor extends Interceptor {
  final FlutterSecureStorage storage;
  final Dio dio;
  bool _isRefreshing = false;
  final List<_Pending> _pending = [];

  // Retry policy for rate limiting
  static final RetryPolicy _rateLimitPolicy = RetryPolicy.rateLimit;

  TokenInterceptor(this.storage, this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Don't add token for auth endpoints
    if (options.path.contains('login') ||
        options.path.contains('register') ||
        options.path.contains('refresh-token') ||
        options.path.contains('logout')) {
      return handler.next(options);
    }

    final token = await storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final resp = err.response;

    // Check if we should retry with backoff (rate limit / network errors)
    if (_shouldRetryWithBackoff(err)) {
      try {
        final result = await _retryWithBackoff(err.requestOptions);
        return handler.resolve(result);
      } catch (e) {
        return handler.next(err); // If retry fails, propagate original error
      }
    }

    // Detect token expired/unauthorized according to backend contract
    // Backend returns ERR_UNAUTHORIZED (401) or TOKEN_EXPIRED code
    final isUnauthorized = _isUnauthorizedError(resp);

    if (isUnauthorized && !_isAuthEndpoint(err.requestOptions.path)) {
      final pending = _Pending(err.requestOptions);
      _pending.add(pending);

      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          final refreshToken = await storage.read(key: 'refresh_token');

          if (refreshToken == null || refreshToken.isEmpty) {
            await _clearTokens();
            _failAllPending(err);
            return handler.next(err);
          }

          // Use relative path so Dio.baseUrl is applied
          final refreshResp = await dio.post(
            'refresh-token',
            data: {'refreshToken': refreshToken},
            options: Options(
              headers: {'Accept': 'application/json'},
              // Don't attach auth interceptor again to avoid infinite loop
              extra: {'skipAuthInterceptor': true},
            ),
          );

          final dynamic data = refreshResp.data;

          if (data is Map && (data['success'] == true || data['status'] == 'success')) {
            // Accept both snake_case and camelCase tokens
            final String? newAccess =
                (data['accessToken'] as String?) ?? (data['access_token'] as String?);

            final String? newRefresh =
                (data['refreshToken'] as String?) ?? (data['refresh_token'] as String?);

            if (newAccess != null && newAccess.isNotEmpty) {
              await storage.write(key: 'access_token', value: newAccess);
              if (newRefresh != null && newRefresh.isNotEmpty) {
                await storage.write(key: 'refresh_token', value: newRefresh);
              }

              // Update default header for future requests
              dio.options.headers['Authorization'] = 'Bearer $newAccess';

              // Retry all pending requests with updated token
              for (final p in List<_Pending>.from(_pending)) {
                try {
                  final orig = p.request;

                  // Build Options for retry, copying necessary fields and replacing Authorization
                  final opts = Options(
                    method: orig.method,
                    headers: Map<String, dynamic>.from(orig.headers ?? {})
                      ..remove('authorization')
                      ..remove('Authorization')
                      ..addAll({'Authorization': 'Bearer $newAccess'}),
                    responseType: orig.responseType,
                    contentType: orig.contentType,
                    extra: {...orig.extra, 'skipAuthInterceptor': true},
                    followRedirects: orig.followRedirects,
                    validateStatus: orig.validateStatus,
                    receiveDataWhenStatusError: orig.receiveDataWhenStatusError,
                    sendTimeout: orig.sendTimeout,
                    receiveTimeout: orig.receiveTimeout,
                  );

                  final retryResp = await dio.request(
                    orig.path,
                    data: orig.data,
                    queryParameters: orig.queryParameters,
                    options: opts,
                    cancelToken: orig.cancelToken,
                    onSendProgress: orig.onSendProgress,
                    onReceiveProgress: orig.onReceiveProgress,
                  );

                  if (!p.completer.isCompleted) p.completer.complete(retryResp);
                } catch (e) {
                  if (!p.completer.isCompleted) p.completer.completeError(e);
                } finally {
                  _pending.remove(p);
                }
              }
            } else {
              // Missing token in refresh response
              await _clearTokens();
              _failAllPending(err);
            }
          } else {
            // Refresh rejected - invalid/expired refresh token
            await _clearTokens();
            _failAllPending(err);
          }
        } catch (e) {
          await _clearTokens();
          _failAllPending(e is DioException ? e : err);
        } finally {
          _isRefreshing = false;
        }
      }

      // Wait for the retry result for the current request
      try {
        final result = await pending.completer.future;
        return handler.resolve(result);
      } catch (e) {
        return handler.reject(err);
      }
    }

    return handler.next(err);
  }

  /// Check if error is unauthorized (401 with ERR_UNAUTHORIZED code or TOKEN_EXPIRED)
  bool _isUnauthorizedError(Response? resp) {
    if (resp?.statusCode != 401 && resp?.statusCode != 403) return false;
    if (resp?.data is! Map) return false;

    final data = resp?.data as Map;
    final code = data['code']?.toString();
    final error = data['error']?.toString();

    // Backend returns ERR_UNAUTHORIZED or TOKEN_EXPIRED
    return code == 'ERR_UNAUTHORIZED' ||
           code == 'TOKEN_EXPIRED' ||
           error == 'TOKEN_EXPIRED';
  }

  /// Check if path is an auth endpoint that shouldn't trigger token refresh
  bool _isAuthEndpoint(String path) {
    return path.contains('login') ||
           path.contains('register') ||
           path.contains('refresh-token') ||
           path.contains('logout');
  }

  /// Check if we should retry with exponential backoff
  bool _shouldRetryWithBackoff(DioException err) {
    final resp = err.response;
    if (resp == null) {
      // Network errors - retry
      return err.type == DioExceptionType.connectionTimeout ||
             err.type == DioExceptionType.sendTimeout ||
             err.type == DioExceptionType.receiveTimeout ||
             err.type == DioExceptionType.connectionError;
    }

    // Rate limit: 429 status or ERR_VALIDATION with rate limit message
    if (resp.statusCode == 429) return true;

    if (resp.data is Map) {
      final data = resp.data as Map;
      final code = data['code']?.toString();
      final message = data['message']?.toString() ?? '';

      // Backend uses ERR_VALIDATION for rate limiting with specific messages
      if (code == 'ERR_VALIDATION' &&
          (message.contains('Terlalu banyak') ||
           message.contains('rate limit') ||
           message.contains('coba lagi'))) {
        return true;
      }
    }

    return false;
  }

  /// Retry a request with exponential backoff
  Future<Response> _retryWithBackoff(RequestOptions options) async {
    return await withRetry<Response>(
      action: () async {
        final opts = Options(
          method: options.method,
          headers: Map<String, dynamic>.from(options.headers ?? {}),
          responseType: options.responseType,
          contentType: options.contentType,
          extra: options.extra,
          followRedirects: options.followRedirects,
          validateStatus: options.validateStatus,
          receiveDataWhenStatusError: options.receiveDataWhenStatusError,
          sendTimeout: options.sendTimeout,
          receiveTimeout: options.receiveTimeout,
        );

        return await dio.request(
          options.path,
          data: options.data,
          queryParameters: options.queryParameters,
          options: opts,
          cancelToken: options.cancelToken,
          onSendProgress: options.onSendProgress,
          onReceiveProgress: options.onReceiveProgress,
        );
      },
      policy: _rateLimitPolicy,
      retryableFailures: const {
        RateLimitFailure,
        NetworkFailure,
        TimeoutFailure,
      },
      onRetry: (attempt, failure) {
        if (kDebugMode) {
        debugPrint(
          '🔄 [TOKEN_INTERCEPTOR RETRY] Attempt ${attempt + 1}/${_rateLimitPolicy.maxRetries} '
          'due to: ${failure.code} - ${failure.message}',
        );
      }
      },
    );
  }

  Future<void> _clearTokens() async {
    try {
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'refresh_token');
      dio.options.headers.remove('Authorization');
    } catch (_) {}
  }

  void _failAllPending(Object cause) {
    for (final p in List<_Pending>.from(_pending)) {
      if (!p.completer.isCompleted) {
        p.completer.completeError(DioException(requestOptions: p.request, error: cause));
      }
      _pending.remove(p);
    }
  }
}