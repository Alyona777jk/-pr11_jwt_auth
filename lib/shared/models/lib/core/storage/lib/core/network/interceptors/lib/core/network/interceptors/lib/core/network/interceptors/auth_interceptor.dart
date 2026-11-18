import 'package:dio/dio.dart';
import '../../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  final Dio dio;
  final void Function()? onForceLogout;

  bool _isRefreshing = false;

  AuthInterceptor({
    required this.tokenStorage,
    required this.dio,
    this.onForceLogout,
  });

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Не додаємо токен на публічні ендпоінти
    final publicPaths = ['/login', '/register', '/refresh'];
    if (!publicPaths.any((path) => options.path.contains(path))) {
      final token = await tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/login') &&
        !err.requestOptions.path.contains('/refresh')) {
      if (_isRefreshing) {
        return handler.next(err);
      }

      _isRefreshing = true;
      try {
        final refreshToken = await tokenStorage.getRefreshToken();
        if (refreshToken == null) {
          onForceLogout?.call();
          return handler.next(err);
        }

        // Запит на оновлення токена
        final refreshResponse = await dio.post(
          '/refresh',
          data: {'refresh_token': refreshToken},
        );

        final newAccessToken = refreshResponse.data['access_token'];
        final newRefreshToken = refreshResponse.data['refresh_token'];

        await tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Повторюємо оригінальний запит (Retry) з новим токеном
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';

        final clonedResponse = await dio.fetch(opts);
        _isRefreshing = false;
        return handler.resolve(clonedResponse);
      } catch (e) {
        _isRefreshing = false;
        await tokenStorage.clearAll();
        onForceLogout?.call();
        return handler.next(err);
      }
    }
    handler.next(err);
  }
}