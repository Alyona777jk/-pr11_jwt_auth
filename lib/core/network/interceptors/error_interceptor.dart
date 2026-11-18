import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String userMessage;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        userMessage = 'Час очікування з’єднання вичерпано. Перевірте інтернет.';
        break;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        final serverMsg = err.response?.data is Map
            ? err.response?.data['message']
            : null;
        if (status == 400) {
          userMessage = serverMsg ?? 'Некоректний запит (400)';
        } else if (status == 401) {
          userMessage = serverMsg ?? 'Сесія закінчилась. Потрібна авторизація (401)';
        } else if (status == 403) {
          userMessage = 'Доступ заборонено (403)';
        } else if (status == 404) {
          userMessage = 'Ресурс не знайдено (404)';
        } else if (status != null && status >= 500) {
          userMessage = 'Помилка сервера ($status). Спробуйте пізніше.';
        } else {
          userMessage = serverMsg ?? 'Помилка сервера ($status)';
        }
        break;
      case DioExceptionType.connectionError:
        userMessage = 'Відсутнє підключення до мережі.';
        break;
      default:
        userMessage = 'Невідома мережева помилка.';
    }

    final customErr = err.copyWith(
      error: AppException(userMessage, err.response?.statusCode),
    );
    handler.next(customErr);
  }
}
