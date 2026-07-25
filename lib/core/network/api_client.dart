import 'dart:async';
import 'package:dio/dio.dart';
import '../config/env.dart';
import 'api_exceptions.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (err, handler) {
        final statusCode = err.response?.statusCode;
        if (statusCode == 401) {
          _unauthorizedController.add(null);
        }
        final message = _errorMessage(err);
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            error: ApiException(message, statusCode: statusCode),
          ),
        );
      },
    ));
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  String? _token;

  final _unauthorizedController = StreamController<void>.broadcast();
  Stream<void> get onUnauthorized => _unauthorizedController.stream;

  Dio get dio => _dio;

  void setToken(String? token) => _token = token;
  void clearToken() => _token = null;

  String _errorMessage(DioException err) {
    final data = err.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;
    if (statusCode == 404 && path.contains('send-email-otp')) {
      return 'Email OTP is not available on this server. Run Backend with npm run dev, or redeploy Render with email auth.';
    }
    if (data is String && data.contains('Cannot POST')) {
      return 'API route not found: $path';
    }
    return err.message ?? 'Unknown error';
  }
}
