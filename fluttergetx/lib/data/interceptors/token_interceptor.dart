import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


/*
 * TokenInterceptor
 *
 * Responsibilities:
 * - Detect TOKEN_EXPIRED responses and perform a single silent refresh using
 *   the refresh token in FlutterSecureStorage.
 * - Queue concurrent requests during refresh and retry them after success.
 * - On refresh failure, clear stored tokens and reject queued requests so the
 *   app can force re-authentication.
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

  TokenInterceptor(this.storage, this.dio);

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final resp = err.response;

    // Detect token expired according to backend contract
    if (resp?.statusCode == 403 &&
        resp?.data is Map &&
        (resp?.data['code'] == 'TOKEN_EXPIRED' || resp?.data['error'] == 'TOKEN_EXPIRED')) {
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
            options: Options(headers: {'Accept': 'application/json'}),
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
                    extra: orig.extra,
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
            // Refresh rejected
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

  Future<void> _clearTokens() async {
    try {
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'refresh_token');
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
