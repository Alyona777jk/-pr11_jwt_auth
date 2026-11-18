import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/interceptors/error_interceptor.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../shared/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final TokenStorage _tokenStorage = TokenStorage();
  late final DioClient _dioClient;

  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _statusLog;
  Timer? _inactivityTimer;

  static const Duration inactivityDuration = Duration(minutes: 2);

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get statusLog => _statusLog;

  AuthProvider() {
    _dioClient = DioClient(
      tokenStorage: _tokenStorage,
      onForceLogout: () => logout(reason: 'Сесія закінчилась (401)'),
    );
    _initAuth();
  }

  Future<void> _initAuth() async {
    final rememberMe = await _tokenStorage.getRememberMe();
    final refreshToken = await _tokenStorage.getRefreshToken();

    if (rememberMe && refreshToken != null) {
      try {
        final isExpired = await _tokenStorage.isAccessTokenExpired();
        if (isExpired) {
          _statusLog = 'Access token прострочений, оновлюємо через refresh...';
        }
        await fetchProfile();
        resetInactivityTimer();
      } catch (_) {
        await _tokenStorage.clearAll();
      }
    } else {
      await _tokenStorage.clearAll();
    }

    _isInitialized = true;
    notifyListeners();
  }

  void resetInactivityTimer() {
    if (!isAuthenticated) return;
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityDuration, () {
      logout(reason: 'Автоматичний вихід через неактивність');
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final response = await _dioClient.dio.post('/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      await _tokenStorage.saveTokens(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
        rememberMe: true,
      );

      _user = UserModel.fromJson(response.data['user']);
      _statusLog = 'Реєстрація успішна! Токени збережено в SecureStorage.';
      resetInactivityTimer();
    } on DioException catch (e) {
      throw (e.error is AppException) ? e.error as AppException : AppException('Помилка реєстрації');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    _setLoading(true);
    try {
      final response = await _dioClient.dio.post('/login', data: {
        'email': email,
        'password': password,
      });

      await _tokenStorage.saveTokens(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
        rememberMe: rememberMe,
      );

      _user = UserModel.fromJson(response.data['user']);
      _statusLog = 'Вхід виконано. Remember me: $rememberMe';
      resetInactivityTimer();
    } on DioException catch (e) {
      throw (e.error is AppException) ? e.error as AppException : AppException('Помилка входу');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchProfile() async {
    _setLoading(true);
    try {
      final response = await _dioClient.dio.get('/user');
      _user = UserModel.fromJson(response.data);
      _statusLog = 'Профіль успішно завантажено (GET /user)';
    } on DioException catch (e) {
      throw (e.error is AppException) ? e.error as AppException : AppException('Помилка завантаження профілю');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({required String name, required String email}) async {
    _setLoading(true);
    try {
      final response = await _dioClient.dio.put('/user', data: {
        'name': name,
        'email': email,
      });
      _user = UserModel.fromJson(response.data);
      _statusLog = 'Профіль оновлено (PUT /user)';
    } on DioException catch (e) {
      throw (e.error is AppException) ? e.error as AppException : AppException('Помилка оновлення профілю');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await _dioClient.dio.post('/user/change-password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      _statusLog = 'Пароль успішно змінено!';
    } on DioException catch (e) {
      throw (e.error is AppException) ? e.error as AppException : AppException('Помилка зміни пароля');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> simulateExpiredTokenAndRetry() async {
    _dioClient.mockAdapter.expireCurrentTokenForDemo();
    _statusLog = 'Токен зіпсовано! Відправляємо GET /user -> очікуємо 401 -> Refresh -> Retry...';
    notifyListeners();
    await fetchProfile();
    _statusLog = 'Успіх! Перехоплено 401, оновлено токен та повторено запит GET /user.';
    notifyListeners();
  }

  Future<void> logout({String? reason}) async {
    _inactivityTimer?.cancel();
    await _tokenStorage.clearAll();
    _user = null;
    _statusLog = reason ?? 'Ви вийшли з акаунту. Кеш та токени очищено.';
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
