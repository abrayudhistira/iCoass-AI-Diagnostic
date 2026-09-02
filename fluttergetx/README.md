# iCoass - Flutter GetX Application

> Aplikasi mobile iCoass (Internet Consultation Assistant) dibangun dengan **Clean Architecture** + **GetX** untuk manajemen state dan dependency injection.

---

## 📋 Overview

iCoass adalah aplikasi konsultasi gigi online yang menghubungkan pasien dengan koas melalui:
- **AI Diagnosis** - Diagnosa awal berbasis gejala menggunakan Naive Bayes
- **Chat Konsultasi** - Real-time chat dengan koas (Socket.io)
- **Artikel Kesehatan** - Konten edukasi kesehatan gigi
- **Rumah Sakit Gigi** - Pencarian RSGM terdekat dengan geolocation

---

## 🏗️ Arsitektur

```
lib/
├── core/                    # Core utilities & cross-cutting concerns
│   ├── constants/           # App constants (colors, API endpoints)
│   ├── error/               # Error handling (Failures, RetryPolicy)
│   ├── interceptors/        # Dio interceptors (TokenInterceptor)
│   └── utils/               # Helper utilities
│
├── data/                    # Data layer (implementation)
│   ├── models/              # DTOs/Models (JSON serialization)
│   ├── repositories/        # Repository implementations
│   ├── services/            # External services (AuthService, GeminiService)
│   └── interceptors/        # HTTP interceptors
│
├── domain/                  # Domain layer (business logic)
│   ├── entities/            # Pure Dart entities
│   ├── repositories/        # Repository interfaces (contracts)
│   └── usecases/            # Use cases (single responsibility)
│
└── presentation/            # Presentation layer (UI)
    ├── bindings/            # GetX bindings (DI setup)
    ├── controllers/         # GetX controllers (state management)
    ├── pages/               # Screens/Pages
    └── widgets/             # Reusable UI components
```

### Clean Architecture Principles
- **Dependency Rule**: Inner layers don't know about outer layers
- **Use Cases**: Single responsibility, testable business logic
- **Repositories**: Abstract contracts in domain, implementations in data
- **Entities**: Pure Dart classes, no framework dependencies

---

## 🔐 Error Handling System

Mengikuti spesifikasi backend `error-code.md` dengan 6 kode error standar:

| Kode | HTTP | Kelas Failure | Deskripsi |
|------|------|---------------|-----------|
| `ERR_VALIDATION` | 400 | `ValidationFailure` | Input tidak valid, field kosong, format salah |
| `ERR_UNAUTHORIZED` | 401 | `UnauthorizedFailure` | Token invalid/expired/tidak ada |
| `ERR_FORBIDDEN` | 403 | `ForbiddenFailure` | Akses ditolak (role mismatch) |
| `ERR_NOT_FOUND` | 404 | `NotFoundFailure` | Resource tidak ditemukan |
| `ERR_CONFLICT` | 409 | `ConflictFailure` | Duplikasi data (email/username) |
| `ERR_INTERNAL` | 500 | `ServerFailure` | Kesalahan server tak terduga |

### Rate Limiting (429)
- Backend mengembalikan `ERR_VALIDATION` dengan message "Terlalu banyak..."
- Ditangani via `RateLimitFailure` dengan `retryAfterSeconds`
- Exponential backoff + jitter via `RetryPolicy`

### Token Auto-Refresh
- `TokenInterceptor` mendeteksi 401/ERR_UNAUTHORIZED
- Silent refresh menggunakan refresh token
- Request queueing selama refresh berlangsung
- Clear tokens & force logout jika refresh gagal

### Penggunaan di Controller
```dart
final result = await useCase(params);

result.fold(
  (failure) {
    final msg = _handleFailure(failure); // Switch on failure.code
    AppSnackbar.error(msg);
  },
  (data) {
    // Success handling
  },
);
```

---

## 🔄 State Management (GetX)

### Controller Pattern
```dart
class FeatureController extends GetxController {
  final FeatureUseCase _useCase;
  
  var isLoading = false.obs;
  var items = <ItemEntity>[].obs;
  
  FeatureController(this._useCase);
  
  Future<void> fetchItems() async {
    isLoading.value = true;
    final result = await _useCase();
    result.fold(
      (failure) => _handleError(failure),
      (data) => items.assignAll(data),
    );
    isLoading.value = false;
  }
}
```

### Dependency Injection
```dart
// bindings/feature_binding.dart
class FeatureBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FeatureRepository>(() => FeatureRepositoryImpl(Get.find<Dio>()));
    Get.lazyPut<FeatureUseCase>(() => FeatureUseCase(Get.find<FeatureRepository>()));
    Get.lazyPut(() => FeatureController(Get.find<FeatureUseCase>()));
  }
}
```

---

## 🌐 Network Layer (Dio)

### Base Configuration
```dart
final dio = Dio(BaseOptions(
  baseUrl: dotenv.env['API_BASE_URL']!,
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),
  headers: {'Accept': 'application/json'},
));
```

### Interceptors Chain
1. **TokenInterceptor** - Auth header, token refresh, rate limit retry
2. **LoggingInterceptor** (debug) - Request/response logging

---

## 📱 Fitur Utama

### 1. Authentication
- Login/Register dengan validasi field-level
- Secure token storage (FlutterSecureStorage)
- Auto-refresh token pada 401
- Role-based navigation (Admin/Patient)

### 2. AI Diagnosis (Naive Bayes)
- Input gejala → Probabilitas penyakit
- Integrasi Gemini AI untuk penjelasan medis
- Riwayat diagnosis lokal + server sync

### 3. Chat Konsultasi
- Socket.io real-time messaging
- Queue system (antrian pasien)
- Admin takeover chat
- Message history pagination

### 4. Artikel (CMS)
- CRUD artikel (Admin)
- List + Detail view (Patient)
- Image upload support

### 5. Rumah Sakit Gigi
- Geolocation-based search
- Radius filter (5-60 KM)
- Google Maps integration
- Admin CRUD management

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.41+, Dart 3.11+ |
| State Management | GetX 4.7+ |
| Architecture | Clean Architecture |
| HTTP Client | Dio 5.9+ |
| Functional | Dartz 0.10+ (Either) |
| Storage | FlutterSecureStorage 10+ |
| Real-time | Socket.io Client 3.1+ |
| Maps | Google Maps Flutter 2.17+ |
| Location | Geolocator 14+ |
| AI | Google Generative AI (Gemini) |
| Charts | fl_chart |
| DI | GetX Bindings |
| Linting | Flutter Lints 6.0+ |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.41+
- Dart SDK 3.11+
- Android Studio / VS Code
- Backend API running (see backend repo)

### Installation
```bash
# Clone & install dependencies
git clone <repo-url>
cd fluttergetx
flutter pub get

# Generate app icons
flutter pub run flutter_launcher_icons:main

# Run development
flutter run --debug

# Build release APK
flutter build apk --release
```

### Environment Variables
Create `.env` file:
```env
API_BASE_URL=https://api.icoass.com
GEMINI_API_KEY=your_gemini_key
GOOGLE_MAPS_API_KEY=your_maps_key
```

---

## 📦 Build & Release

### Debug APK
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### App Bundle (Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## 🧪 Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Analyze code
flutter analyze
```

---

## 📁 Project Structure Detail

### Core Layer
```
core/
├── constants/
│   ├── colors.dart           # App color palette
│   ├── api_endpoints.dart    # API endpoint constants
│   └── symptoms.dart         # Diagnosis symptom codes
├── error/
│   ├── failures.dart         # Typed Failure hierarchy
│   └── retry_policy.dart     # Exponential backoff config
└── interceptors/
    └── token_interceptor.dart # Auth, refresh, rate limit
```

### Data Layer
```
data/
├── models/
│   ├── user_model.dart       # User DTO with fromJson/toJson
│   ├── article_model.dart
│   ├── hospital_model.dart
│   ├── chat_model.dart
│   └── diagnosis_model.dart
├── repositories/
│   ├── auth_repository_impl.dart
│   ├── article_repository_impl.dart
│   ├── hospital_repository_impl.dart
│   ├── diagnosis_repository_impl.dart
│   └── chat_repository_impl.dart
├── services/
│   ├── auth_service.dart     # Secure storage wrapper
│   └── gemini_service.dart   # AI explanation service
└── interceptors/
    └── (moved to core/interceptors)
```

### Domain Layer
```
domain/
├── entities/
│   ├── user_entity.dart
│   ├── article_entity.dart
│   ├── hospital_entity.dart
│   ├── chat_entity.dart
│   └── diagnosis_entity.dart
├── repositories/
│   ├── auth_repository.dart
│   ├── article_repository.dart
│   ├── hospital_repository.dart
│   ├── diagnosis_repository.dart
│   └── chat_repository.dart
└── usecases/
    ├── auth/
    │   ├── login_usecase.dart
    │   ├── register_usecase.dart
    │   ├── logout_usecase.dart
    │   ├── get_user_detail_usecase.dart
    │   ├── get_all_users_usecase.dart
    │   ├── delete_user_usecase.dart
    │   ├── update_profile_usecase.dart
    │   └── update_user_usecase.dart
    ├── article/
    ├── hospital/
    ├── diagnosis/
    └── chat/
```

### Presentation Layer
```
presentation/
├── bindings/
│   ├── auth_binding.dart
│   ├── article_binding.dart
│   ├── hospital_binding.dart
│   ├── diagnosis_binding.dart
│   ├── chat_binding.dart
│   └── location_binding.dart
├── controllers/
│   ├── auth_controller.dart
│   ├── article_controller.dart
│   ├── hospital_controller.dart
│   ├── diagnosis_controller.dart
│   ├── chat_controller.dart
│   └── location_controller.dart
├── pages/
│   ├── auth/
│   │   ├── login_page.dart
│   │   └── register_page.dart
│   ├── article/
│   ├── hospital/
│   ├── diagnosis/
│   ├── chat/
│   │   ├── admin/
│   │   └── patient/
│   ├── profile/
│   └── admin/
└── widgets/
    ├── common_snackbar.dart
    ├── custom_app_bar.dart
    └── loading_indicator.dart
```

---

## 🔒 Security

- **Token Storage**: FlutterSecureStorage (encrypted)
- **HTTPS Only**: Dio baseUrl menggunakan HTTPS
- **Token Refresh**: Automatic silent refresh
- **Logout**: Server-side token revocation + local clear
- **Input Validation**: Client + server side

---

## 📊 Monitoring & Debugging

### Logging
```dart
// Dio request/response logging (debug mode)
dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
  logPrint: (obj) => debugPrint(obj.toString()),
));
```

### Error Tracking
- All errors flow through `_handleFailure()` in controllers
- Structured error codes enable analytics
- Rate limit headers captured for retry logic

---

## 🤝 Contributing

1. Follow Clean Architecture layers
2. Use Either<Failure, T> for all repository/use case returns
3. Map backend error codes to typed Failures
4. Write unit tests for use cases
5. Run `flutter analyze` before commit

---

## 📄 License

PKMKC iCoass 2026

---

## 🔗 Related Repositories

- **Backend API**: `iCoass-Backend-V2` (Node.js/Express + Socket.io)
- **Python AI Service**: `NaiveBayesiCoass` (Naive Bayes diagnosis)

---

*Generated with ❤️ for iCoass Skripsi Project*