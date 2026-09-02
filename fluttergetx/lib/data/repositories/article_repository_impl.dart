import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:fluttergetx/core/error/failures.dart';
import 'package:fluttergetx/domain/entities/article_entity.dart';
import 'package:fluttergetx/domain/repositories/article_repository.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  final Dio _dio;

  ArticleRepositoryImpl(this._dio);

  Failure _mapError(DioException e, String defaultMessage) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final code = data['code']?.toString();
      final message = data['message']?.toString() ?? defaultMessage;
      final details = data['details'] as Map<String, dynamic>?;

      if (statusCode == 429) {
        final resetHeader = e.response?.headers.value('RateLimit-Reset');
        int? retryAfter;
        if (resetHeader != null) {
          final resetTime = int.tryParse(resetHeader);
          if (resetTime != null) {
            retryAfter = (resetTime - DateTime.now().millisecondsSinceEpoch / 1000).ceil();
            retryAfter = retryAfter! > 0 ? retryAfter : 1;
          }
        }
        return RateLimitFailure(
          message: message,
          retryAfterSeconds: retryAfter,
          details: details,
          statusCode: statusCode,
        );
      }

      switch (code) {
        case 'ERR_VALIDATION':
          return ValidationFailure(
            message: message,
            field: details?['field']?.toString(),
            details: details,
            statusCode: statusCode,
          );
        case 'ERR_UNAUTHORIZED':
          return UnauthorizedFailure(
            message: message,
            details: details,
            statusCode: statusCode,
          );
        case 'ERR_FORBIDDEN':
          return ForbiddenFailure(
            message: message,
            details: details,
            statusCode: statusCode,
          );
        case 'ERR_NOT_FOUND':
          return NotFoundFailure(
            message: message,
            resource: details?['field']?.toString(),
            details: details,
            statusCode: statusCode,
          );
        case 'ERR_CONFLICT':
          return ConflictFailure(
            message: message,
            details: details,
            statusCode: statusCode,
          );
        case 'ERR_INTERNAL':
          return ServerFailure(
            message: message,
            details: details,
            statusCode: statusCode,
          );
        default:
          return ServerFailure(
            message: message,
            details: details,
            statusCode: statusCode,
          );
      }
    } else if (data is String) {
      if (data.contains('<!DOCTYPE') || data.contains('<html')) {
        if (statusCode == 404) {
          return NotFoundFailure(message: 'Endpoint API tidak ditemukan (404)');
        }
        if (statusCode == 500) {
          return ServerFailure(message: 'Kesalahan internal server (500)');
        }
        return ServerFailure(message: 'Server mengembalikan respon tidak valid (HTML)', statusCode: statusCode);
      }
      return ServerFailure(message: data, statusCode: statusCode);
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure();
      case DioExceptionType.connectionError:
        return NetworkFailure();
      case DioExceptionType.cancel:
        return UnknownFailure(message: 'Request dibatalkan');
      case DioExceptionType.badResponse:
        return ServerFailure(message: defaultMessage, statusCode: statusCode);
      case DioExceptionType.unknown:
      default:
        return UnknownFailure(message: '$defaultMessage (${e.type.name}): ${e.message}');
    }
  }

  @override
  Future<Either<Failure, List<ArticleEntity>>> getAll({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        'articles',
        queryParameters: {'page': page, 'limit': limit},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          final List<dynamic> list = body['data'] as List<dynamic>;
          return Right(list.map((e) => ArticleEntity.fromJson(e as Map<String, dynamic>)).toList());
        }
        final code = body['code']?.toString();
        final message = body['message']?.toString() ?? 'Failed to fetch articles';
        final details = body['details'] as Map<String, dynamic>?;
        return Left(_createFailureFromResponse(code, message, details, response.statusCode));
      }
      return Left(ServerFailure(message: 'Failed to fetch articles: ${response.statusCode}', statusCode: response.statusCode));
    } on DioException catch (e) {
      return Left(_mapError(e, 'Failed to fetch articles'));
    }
  }

  @override
  Future<Either<Failure, ArticleEntity>> getDetail(String id) async {
    try {
      final response = await _dio.get('articles/$id');
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          return Right(ArticleEntity.fromJson(body['data'] as Map<String, dynamic>));
        }
        final code = body['code']?.toString();
        final message = body['message']?.toString() ?? 'Failed to fetch article detail';
        final details = body['details'] as Map<String, dynamic>?;
        return Left(_createFailureFromResponse(code, message, details, response.statusCode));
      }
      return Left(ServerFailure(message: 'Failed to fetch article detail: ${response.statusCode}', statusCode: response.statusCode));
    } on DioException catch (e) {
      return Left(_mapError(e, 'Failed to fetch article detail'));
    }
  }

  @override
  Future<Either<Failure, ArticleEntity>> create(ArticleEntity article, {String? imagePath}) async {
    try {
      final formData = FormData.fromMap({
        'title': article.title,
        'content': article.content,
        if (imagePath != null && imagePath.isNotEmpty)
          'image': await MultipartFile.fromFile(imagePath, filename: imagePath.split(Platform.pathSeparator).last),
      });
      final response = await _dio.post('articles', data: formData);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          return Right(ArticleEntity.fromJson(body['data'] as Map<String, dynamic>));
        }
        final code = body['code']?.toString();
        final message = body['message']?.toString() ?? 'Failed to create article';
        final details = body['details'] as Map<String, dynamic>?;
        return Left(_createFailureFromResponse(code, message, details, response.statusCode));
      }
      return Left(ServerFailure(message: 'Failed to create article: ${response.statusCode}', statusCode: response.statusCode));
    } on DioException catch (e) {
      return Left(_mapError(e, 'Failed to create article'));
    }
  }

  @override
  Future<Either<Failure, ArticleEntity>> update(String id, ArticleEntity article, {String? imagePath}) async {
    try {
      final body = {
        'title': article.title,
        'content': article.content,
      };
      final response = await _dio.put('articles/$id', data: body);
      if (response.statusCode == 200) {
        final responseBody = response.data as Map<String, dynamic>;
        if (responseBody['success'] == true) {
          return Right(ArticleEntity.fromJson(responseBody['data'] as Map<String, dynamic>));
        }
        final code = responseBody['code']?.toString();
        final message = responseBody['message']?.toString() ?? 'Failed to update article';
        final details = responseBody['details'] as Map<String, dynamic>?;
        return Left(_createFailureFromResponse(code, message, details, response.statusCode));
      }
      return Left(ServerFailure(message: 'Failed to update article: ${response.statusCode}', statusCode: response.statusCode));
    } on DioException catch (e) {
      return Left(_mapError(e, 'Failed to update article'));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      final response = await _dio.delete('articles/$id');
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          return const Right(null);
        }
        final code = body['code']?.toString();
        final message = body['message']?.toString() ?? 'Failed to delete article';
        final details = body['details'] as Map<String, dynamic>?;
        return Left(_createFailureFromResponse(code, message, details, response.statusCode));
      }
      return Left(ServerFailure(message: 'Failed to delete article: ${response.statusCode}', statusCode: response.statusCode));
    } on DioException catch (e) {
      return Left(_mapError(e, 'Failed to delete article'));
    }
  }

  Failure _createFailureFromResponse(
    String? code,
    String message,
    Map<String, dynamic>? details,
    int? statusCode,
  ) {
    switch (code) {
      case 'ERR_VALIDATION':
        return ValidationFailure(
          message: message,
          field: details?['field']?.toString(),
          details: details,
          statusCode: statusCode,
        );
      case 'ERR_UNAUTHORIZED':
        return UnauthorizedFailure(
          message: message,
          details: details,
          statusCode: statusCode,
        );
      case 'ERR_FORBIDDEN':
        return ForbiddenFailure(
          message: message,
          details: details,
          statusCode: statusCode,
        );
      case 'ERR_NOT_FOUND':
        return NotFoundFailure(
          message: message,
          resource: details?['field']?.toString(),
          details: details,
          statusCode: statusCode,
        );
      case 'ERR_CONFLICT':
        return ConflictFailure(
          message: message,
          details: details,
          statusCode: statusCode,
        );
      case 'ERR_INTERNAL':
        return ServerFailure(
          message: message,
          details: details,
          statusCode: statusCode,
        );
      default:
        return ServerFailure(
          message: message,
          details: details,
          statusCode: statusCode,
        );
    }
  }
}