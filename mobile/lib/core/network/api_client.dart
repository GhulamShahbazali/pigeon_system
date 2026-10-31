import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../config/env/app_env.dart';
import '../local_storage/secure_storage_service.dart';
import '../result/result.dart';

class ApiClient {
  late final Dio _dio;
  final SecureStorageService _storage;

  ApiClient({required SecureStorageService storage, Dio? dio})
      : _storage = storage {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: AppEnv.baseUrl,
            // Generous timeouts: the free Render instance can cold-start (~30–50s)
            // on the first request after it has been idle.
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError && _canFallback()) {
        _switchBaseUrl();
        try {
          final res = await _dio.get(path, queryParameters: queryParameters);
          return _handleResponse<T>(res, fromJson);
        } catch (_) {}
      }
      return _handleError<T>(e);
    } catch (e) {
      return FailureResult(message: e.toString());
    }
  }

  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
  }) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError && _canFallback()) {
        _switchBaseUrl();
        try {
          final res = await _dio.post(path, data: data, queryParameters: queryParameters);
          return _handleResponse<T>(res, fromJson);
        } catch (_) {}
      }
      return _handleError<T>(e);
    } catch (e) {
      return FailureResult(message: e.toString());
    }
  }

  /// Upload a single file as multipart/form-data (e.g. chat voice/image/video).
  /// Returns the parsed `{data}` envelope via [fromJson].
  Future<Result<T>> upload<T>(
    String path, {
    required String filePath,
    String field = 'file',
    Map<String, dynamic>? fields,
    T Function(dynamic data)? fromJson,
  }) async {
    try {
      final form = FormData.fromMap({
        ...?fields,
        field: await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(
        path,
        data: form,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return FailureResult(message: e.toString());
    }
  }

  // Only toggle localhost↔LAN-IP for LOCAL dev. On the live backend there is no
  // localhost to fall back to, so never rewrite the base URL.
  bool _canFallback() => !kIsWeb && !AppEnv.useLiveBackend;

  void _switchBaseUrl() {
    final current = _dio.options.baseUrl;
    if (current.contains('127.0.0.1') || current.contains('localhost')) {
      _dio.options.baseUrl = 'http://${AppEnv.machineIp}:3000/v1';
    } else {
      _dio.options.baseUrl = 'http://127.0.0.1:3000/v1';
    }
  }

  Future<Result<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
  }) async {
    try {
      final response = await _dio.patch(path, data: data, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError && _canFallback()) {
        _switchBaseUrl();
        try {
          final res = await _dio.patch(path, data: data, queryParameters: queryParameters);
          return _handleResponse<T>(res, fromJson);
        } catch (_) {}
      }
      return _handleError<T>(e);
    } catch (e) {
      return FailureResult(message: e.toString());
    }
  }

  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(path, data: data, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return FailureResult(message: e.toString());
    }
  }

  Result<T> _handleResponse<T>(Response response, T Function(dynamic data)? fromJson) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      final payload = body['data'];
      if (fromJson != null) {
        return Success(fromJson(payload));
      }
      return Success(payload as T);
    }

    if (fromJson != null) {
      return Success(fromJson(body));
    }
    return Success(body as T);
  }

  Result<T> _handleError<T>(DioException e) {
    String message = 'Something went wrong';
    String? code;

    if (e.response != null && e.response?.data is Map<String, dynamic>) {
      final err = e.response!.data['error'];
      if (err is Map<String, dynamic>) {
        message = err['message']?.toString() ?? message;
        code = err['code']?.toString();
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Please check your internet.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Cannot connect to backend server.';
    }

    return FailureResult<T>(
      message: message,
      code: code,
      statusCode: e.response?.statusCode,
    );
  }
}
