import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'constants.dart';
import 'storage_service.dart';

/// Thin, centralized HTTP client. All network calls in the app go through
/// this class (never raw http calls inside widgets — see services/ layer),
/// so auth headers, base URL, timeouts, and error normalization live in
/// exactly one place.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: _resolveBaseUrl(),
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException e, handler) {
        handler.next(e);
      },
    ));
  }

  static String _resolveBaseUrl() {
    // Android emulators need the special 10.0.2.2 alias to reach the host.
    if (!kIsWeb && Platform.isAndroid) {
      return AppConstants.apiBaseUrlAndroidEmulator;
    }
    return AppConstants.apiBaseUrlDefault;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final resp = await dio.get(path, queryParameters: query);
      return resp.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final resp = await dio.post(path, data: data);
      return resp.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final resp = await dio.patch(path, data: data);
      return resp.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return ApiException(
        'Could not reach the StockVision server. Make sure the backend is running.',
      );
    }
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'Something went wrong. Please try again.';
    if (data is Map && data['detail'] != null) {
      message = data['detail'].toString();
    }
    if (status == 401) {
      message = 'Your session has expired. Please log in again.';
    }
    return ApiException(message, statusCode: status);
  }
}
