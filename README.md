# Практична робота 11 (Частина 2): Розширені можливості мережевої взаємодії

**Дисципліна:** Програмування для мобільних платформ  
**Варіант 1:** Система авторизації з JWT  
**Стек технологій:** Flutter, Dart, `dio`, `flutter_secure_storage`, `jwt_decoder`, `provider`.

---

## Реалізований функціонал

### 1. Налаштування Dio та Interceptors
* **`AuthInterceptor`** — автоматично додає заголовок `Authorization: Bearer <access_token>` до всіх захищених запитів; при отриманні статусу `401 Unauthorized` перехоплює помилку, виконує запит `POST /refresh` для оновлення пари токенів та автоматично повторює вихідний запит (**Retry**).
* **`LoggingInterceptor`** — логує HTTP-методи, URI, заголовки, тіло запитів, статус-коди відповідей та помилки.
* **`ErrorInterceptor`** — централізована обробка помилок `DioException` (таймаути, втрата мережі, HTTP-статуси 400, 401, 403, 404, 500+).

### 2. Авторизація з JWT та безпека
* **Реєстрація (`POST /register`)** — форма з полями `name`, `email`, `password`, `confirm password`, валідація формату пошти та довжини пароля (мінімум 8 символів).
* **Логін (`POST /login`)** — вхід із опцією **Remember me** для автоматичного входу після перезапуску застосунку.
* **Безпечне сховище** — збереження `access_token` та `refresh_token` у зашифрованому сховищі через `flutter_secure_storage`.
* **Валідація терміну дії JWT** — перевірка валідності токена при ініціалізації за допомогою `JwtDecoder.isExpired`.
* **Auto-logout** — автоматичний вихід із системи після 2 хвилин неактивності користувача.

### 3. Захищені маршрути
* `GET /user` — отримання профілю поточного користувача.
* `PUT /user` — оновлення імені та email.
* `POST /user/change-password` — зміна пароля із перевіркою старого пароля.
* **Logout** — очищення токенів із `flutter_secure_storage`, скидання стану та редірект на екран авторизації.

---

## Структура проєкту

```text
lib/
├── main.dart
├── core/
│   ├── network/
│   │   ├── dio_client.dart
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart
│   │       ├── logging_interceptor.dart
│   │       └── error_interceptor.dart
│   └── storage/
│       └── token_storage.dart
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       ├── providers/auth_provider.dart
│   │       └── screens/
│   │           ├── login_screen.dart
│   │           └── register_screen.dart
│   └── main_feature/
│       └── presentation/
│           └── screens/profile_screen.dart
└── shared/
    ├── models/user_model.dart
    └── services/mock_auth_adapter.dart
Тестові облікові дані та запуск
Встановіть залежності та запустіть застосунок:

Bash
flutter pub get
flutter run
Дані за замовчуванням для входу:

Email: student@university.edu.ua

Пароль: Password123

Для перевірки життєвого циклу токена на екрані профілю доступна кнопка «Симулювати 401 -> Refresh Token -> Retry».
