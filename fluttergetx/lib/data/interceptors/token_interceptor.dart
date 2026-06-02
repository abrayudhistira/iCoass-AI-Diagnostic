import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenInterceptor extends Interceptor {
  final FlutterSecureStorage storage;
  final Dio dio;
  bool _isRefreshing = false;
  List<Function()> _retryQueue = [];

  TokenInterceptor(this.storage, this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    // Deteksi token expired
    if (response?.statusCode == 403 &&
        response?.data is Map &&
        response?.data['code'] == 'TOKEN_EXPIRED') {
      final completer = Completer<Response>();
      _retryQueue.add(() async {
        try {
          final accessToken = await storage.read(key: 'access_token');
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $accessToken';
          final cloneReq = await dio.fetch(opts);
          completer.complete(cloneReq);
        } catch (e) {
          completer.completeError(e);
        }
      });

      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          final refreshToken = await storage.read(key: 'refresh_token');
          final refreshResp = await dio.post(
            '/refresh-token',
            data: {'refreshToken': refreshToken},
          );
          if (refreshResp.data['success'] == true) {
            await storage.write(
                key: 'access_token', value: refreshResp.data['accessToken']);
            // Retry semua request yang tertunda
            for (final retry in _retryQueue) {
              await retry();
            }
            _retryQueue.clear();
            _isRefreshing = false;
          } else {
            // Refresh gagal, logout
            await storage.delete(key: 'access_token');
            await storage.delete(key: 'refresh_token');
            _retryQueue.clear();
            _isRefreshing = false;
            return handler.reject(err);
          }
        } catch (e) {
          _retryQueue.clear();
          _isRefreshing = false;
          return handler.reject(err);
        }
      }
      // Tunggu sampai refresh selesai dan retry
      try {
        final resp = await completer.future;
        return handler.resolve(resp);
      } catch (e) {
        return handler.reject(err);
      }
    } else {
      return handler.next(err);
    }
  }
}