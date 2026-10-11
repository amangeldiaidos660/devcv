import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioClient {
  DioClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'https://example.com/api/',
          ),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
        ),
      ) {
    if (kDebugMode) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint(
              '${options.method} ${options.uri.origin}${options.uri.path}',
            );
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint('HTTP ${response.statusCode}');
            handler.next(response);
          },
          onError: (error, handler) {
            debugPrint('HTTP error: ${error.type.name}');
            handler.next(error);
          },
        ),
      );
    }
  }

  final Dio dio;
}
