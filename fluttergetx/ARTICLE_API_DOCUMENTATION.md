# Analisis Arsitektur iCoass-getX

## ✅ YANG SUDAH BAIK

### 1. Struktur Direktori Clean Architecture
```
lib/
├── core/           # Shared utilities, constants, interceptors
├── data/           # Models, repository implementations, services
├── domain/         # Entities, repository interfaces, usecases
└── presentation/  # Controllers, bindings, pages, widgets
```
**Status:** ✅ Sesuai Clean Architecture

### 2. Pemisahan Layer
- **Domain Layer:** Entities, Repository interfaces, UseCases
- **Data Layer:** Models (extends Entity), Repository implementations, Services
- **Presentation Layer:** Controllers (GetX), Bindings, Pages, Widgets

### 3. GetX Usage
- Controllers menggunakan `GetxController` dengan `obs` reactive state
- Bindings untuk dependency injection
- Routes menggunakan `GetMaterialApp` dengan `getPages`

---

## ❌ ISSUES YANG PERLU DIBENARKAN

### ISSUE 1: Duplikasi Import di `chat_repository_impl.dart`
```dart
// Line 1-3: duplikat
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';
```
**Fix:** Hapus duplikasi import di baris 7-10

### ISSUE 2: Duplicate `@override` di `chat_repository_impl.dart`
```dart
// Line 200-201
@override
@override  // ← DUPLIKAT
Future<Either<Failure, void>> requestChat(int userId) async {
```
**Fix:** Hapus salah satu `@override`

### ISSUE 3: `GeminiService` di `data/services/` tapi diakses langsung di Controller
```
data/services/gemini_service.dart
    ↓ langsung di-import
presentation/controllers/diagnosis_controller.dart
```
**Masalah:** Melanggar SoC - controller mengakses data layer langsung
**Fix:** Pindahkan ke `domain/usecases/` atau buat `ExplanationRepository`

### ISSUE 4: Missing UseCases untuk Diagnosis
- `DiagnosisController` langsung memanggil `repository.fetchDiagnosis()`
- Tidak ada `FetchDiagnosisUseCase` seperti `RequestNewChatUseCase`
**Fix:** Buat `FetchDiagnosisUseCase` di `domain/usecases/diagnosis/`

### ISSUE 5: Missing UseCases untuk Auth
- `AuthController` langsung memanggil `repository.login()`, `repository.register()`, dll
- Tidak ada UseCase untuk operasi auth
**Fix:** Buat `LoginUseCase`, `RegisterUseCase`, `LogoutUseCase`

### ISSUE 6: `AuthService` di `core/services/` tapi seharusnya di `data/services/`
```
core/services/auth_service.dart  ← Lokasi salah
```
**Masalah:** AuthService adalah implementation detail (FlutterSecureStorage)
**Fix:** Pindahkan ke `data/services/auth_service.dart`

### ISSUE 7: `AuthInterceptor` di `core/interceptors/` tapi mengakses `AuthService`
```
core/interceptors/auth_interceptor.dart
    ↓ imports
core/services/auth_service.dart
```
**Masalah:** Interceptor adalah infrastructure, harus di `data/interceptors/`
**Fix:** Pindahkan ke `data/interceptors/auth_interceptor.dart`

### ISSUE 8: Inconsistent Binding Pattern
- `AuthBinding` menggunakan `Get.put(..., permanent: true)`
- `DiagnosisBinding` menggunakan `Get.lazyPut(...)`
- `ChatBinding` menggunakan mixed pattern
**Fix:** Standarisasi pattern (rekomendasikan `Get.lazyPut` untuk semua)

### ISSUE 9: Missing Error Handling dengan `Either<Failure, T>`
- `DiagnosisRepositoryImpl` throw exception langsung, tidak return `Either`
- `AuthRepositoryImpl` throw exception langsung, tidak return `Either`
**Fix:** Gunakan `Either<Failure, T>` pattern seperti di `ChatRepository`

### ISSUE 10: `UserEntity` tidak extends `Equatable`
- `ChatRoomEntity`, `MessageEntity`, `DiagnosisResult` sudah pakai `Equatable`
- `UserEntity` tidak konsisten
**Fix:** Extends `Equatable` untuk `UserEntity`

### ISSUE 11: Missing Repository Interface untuk Article & Hospital
- Cek apakah ada `domain/repositories/article_repository.dart` dan `hospital_repository.dart`
- Jika ada, pastikan ada UseCase untuk operasi CRUD

---

## 📋 PLAN PENYESUAIAN

### Priority 1 (Critical - Arsitektur)
1. [ ] Pindahkan `core/services/auth_service.dart` → `data/services/`
2. [ ] Pindahkan `core/interceptors/auth_interceptor.dart` → `data/interceptors/`
3. [ ] Buat `FetchDiagnosisUseCase` di `domain/usecases/diagnosis/`
4. [ ] Buat `LoginUseCase`, `RegisterUseCase`, `LogoutUseCase` di `domain/usecases/auth/`
5. [ ] Update `DiagnosisController` untuk gunakan UseCase
6. [ ] Update `AuthController` untuk gunakan UseCase

### Priority 2 (Code Quality)
7. [ ] Fix duplikasi import di `chat_repository_impl.dart`
8. [ ] Hapus duplicate `@override` di `chat_repository_impl.dart`
9. [ ] Extends `Equatable` untuk `UserEntity`
10. [ ] Standarisasi semua Binding gunakan `Get.lazyPut`

### Priority 3 (Optional - Enhancement)
11. [ ] Implementasi `Either<Failure, T>` untuk semua repository
12. [ ] Buat `GetExplanationUseCase` untuk Gemini service
13. [ ] Konsistensi naming: `*_binding.dart` vs `*_binding.dart` (sudah OK)

---

Mau saya jelaskan lebih detail untuk salah satu issue, atau langsung **toggle to Act mode** untuk mulai implementasi?