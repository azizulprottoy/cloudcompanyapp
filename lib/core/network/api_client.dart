import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData;

import '../auth/session_service.dart';
import '../storage/secure_storage_service.dart';
import '../utils/app_constants.dart';

/// Single Dio instance for the whole app (same shape as Kaj Ache's client).
class ApiClient {
  ApiClient._();

  static Dio? _dio;

  static Dio get instance => _dio ??= _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.addAll([
      _AuthInterceptor(),
      if (kDebugMode) _LogInterceptor(),
    ]);
    return dio;
  }

  /// Drops the in-memory token so the next request re-reads secure storage.
  static void clearCachedToken() => _AuthInterceptor.invalidate();
}

class _AuthInterceptor extends Interceptor {
  static String? _token;
  static bool _loaded = false;

  static void invalidate() {
    _token = null;
    _loaded = false;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_loaded) {
      _token = await Get.find<SecureStorageService>().getToken();
      _loaded = true;
    }
    final token = _token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // A 401 on login means wrong credentials; anywhere else it means the
    // session ended, so sign out once and send the user to the login page.
    final isAuthCall = err.requestOptions.extra['isAuthCall'] == true;
    final hadToken = err.requestOptions.headers['Authorization'] != null;
    if (err.response?.statusCode == 401 && !isAuthCall && hadToken) {
      SessionService.to.expire();
    }
    handler.next(err);
  }
}

class _LogInterceptor extends Interceptor {
  String _short(dynamic data) {
    if (data == null) return '';
    String text;
    try {
      text = data is String ? data : jsonEncode(data);
    } catch (_) {
      text = data.toString();
    }
    return text.length > 600 ? '${text.substring(0, 600)}…' : text;
  }

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    debugPrint(
      '→ ${o.method} ${o.uri} ${o.data is FormData ? '[multipart]' : _short(o.data)}',
    );
    h.next(o);
  }

  @override
  void onResponse(Response r, ResponseInterceptorHandler h) {
    debugPrint('← ${r.statusCode} ${r.requestOptions.uri} ${_short(r.data)}');
    h.next(r);
  }

  @override
  void onError(DioException e, ErrorInterceptorHandler h) {
    debugPrint(
      '✕ ${e.response?.statusCode ?? e.type.name} ${e.requestOptions.uri} ${_short(e.response?.data)}',
    );
    h.next(e);
  }
}
