import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

class MockAuthAdapter implements HttpClientAdapter {
  String _email = 'student@university.edu.ua';
  String _password = 'Password123';
  String _name = 'Олександр Коваленко';
  String _currentValidAccessToken = '';
  String _currentValidRefreshToken = 'refresh_token_initial_999';

  MockAuthAdapter() {
    _currentValidAccessToken = _generateFakeJwt(expiresInSeconds: 3600);
  }

  String _generateFakeJwt({int expiresInSeconds = 3600}) {
    final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
    final exp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + expiresInSeconds;
    final payload = base64Url.encode(utf8.encode(jsonEncode({
      'sub': '1',
      'email': _email,
      'exp': exp,
    })));
    return '$header.$payload.mock_signature_${DateTime.now().millisecond}';
  }

  void expireCurrentTokenForDemo() {
    _currentValidAccessToken = 'expired_token_trigger_401';
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final path = options.path;
    final method = options.method;
    final data = options.data is Map ? options.data as Map<String, dynamic> : {};

    if (path == '/register' && method == 'POST') {
      _email = data['email'] ?? _email;
      _password = data['password'] ?? _password;
      _name = data['name'] ?? _email.split('@').first;
      _currentValidAccessToken = _generateFakeJwt();
      _currentValidRefreshToken = 'refresh_${DateTime.now().millisecondsSinceEpoch}';

      return _jsonResponse(201, {
        'access_token': _currentValidAccessToken,
        'refresh_token': _currentValidRefreshToken,
        'user': {'id': '1', 'email': _email, 'name': _name},
      });
    }

    if (path == '/login' && method == 'POST') {
      final email = data['email'];
      final password = data['password'];
      if (email == _email && password == _password) {
        _currentValidAccessToken = _generateFakeJwt();
        _currentValidRefreshToken = 'refresh_${DateTime.now().millisecondsSinceEpoch}';
        return _jsonResponse(200, {
          'access_token': _currentValidAccessToken,
          'refresh_token': _currentValidRefreshToken,
          'user': {'id': '1', 'email': _email, 'name': _name},
        });
      }
      return _jsonResponse(400, {'message': 'Невірний email або пароль'});
    }

    if (path == '/refresh' && method == 'POST') {
      final refreshToken = data['refresh_token'];
      if (refreshToken == _currentValidRefreshToken) {
        _currentValidAccessToken = _generateFakeJwt();
        _currentValidRefreshToken = 'refresh_${DateTime.now().millisecondsSinceEpoch}';
        return _jsonResponse(200, {
          'access_token': _currentValidAccessToken,
          'refresh_token': _currentValidRefreshToken,
        });
      }
      return _jsonResponse(401, {'message': 'Refresh token недійсний'});
    }

    final authHeader = options.headers['Authorization']?.toString() ?? '';
    if (authHeader != 'Bearer $_currentValidAccessToken') {
      return _jsonResponse(401, {'message': 'Token expired or invalid'});
    }

    if (path == '/user' && method == 'GET') {
      return _jsonResponse(200, {
        'id': '1',
        'email': _email,
        'name': _name,
        'role': 'Mobile Developer',
      });
    }

    if (path == '/user' && method == 'PUT') {
      _name = data['name'] ?? _name;
      _email = data['email'] ?? _email;
      return _jsonResponse(200, {
        'id': '1',
        'email': _email,
        'name': _name,
        'role': 'Mobile Developer',
      });
    }

    if (path == '/user/change-password' && method == 'POST') {
      if (data['old_password'] != _password) {
        return _jsonResponse(400, {'message': 'Старий пароль введено невірно'});
      }
      _password = data['new_password'];
      return _jsonResponse(200, {'message': 'Пароль успішно змінено'});
    }

    return _jsonResponse(404, {'message': 'Endpoint not found'});
  }

  ResponseBody _jsonResponse(int statusCode, Map<String, dynamic> body) {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
