import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import '../../shared/services/mock_auth_adapter.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class DioClient {
  late final Dio dio;
  final TokenStorage tokenStorage;
  final MockAuthAdapter mockAdapter = MockAuthAdapter();

  DioClient({
    required this.tokenStorage,
    void Function()? onForceLogout,
  }) {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.mock-auth.local/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.httpClientAdapter = mockAdapter;

    dio.interceptors.addAll([
      AuthInterceptor(
        tokenStorage: tokenStorage,
        dio: dio,
        onForceLogout: onForceLogout,
      ),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);
  }
}
