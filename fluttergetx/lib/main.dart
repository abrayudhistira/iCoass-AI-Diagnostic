import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttergetx/data/interceptors/token_interceptor.dart';
import 'package:fluttergetx/presentation/bindings/article_binding.dart';
import 'package:fluttergetx/presentation/bindings/chat_binding.dart';
import 'package:fluttergetx/presentation/bindings/diagnosis_binding.dart';
import 'package:fluttergetx/presentation/bindings/hospital_binding.dart';
import 'package:fluttergetx/presentation/bindings/location_binding.dart';
import 'package:fluttergetx/presentation/pages/account-management/add_user_management.dart';
import 'package:fluttergetx/presentation/pages/account-management/user_management.dart';
import 'package:fluttergetx/presentation/pages/article/admin_article_page.dart';
import 'package:fluttergetx/presentation/pages/article/article_list_page.dart';
import 'package:fluttergetx/presentation/pages/chat/admin/admin_chat_detail_page.dart';
import 'package:fluttergetx/presentation/pages/chat/admin/chat_list_page.dart';
import 'package:fluttergetx/presentation/pages/chat/admin/queue_pages.dart';
import 'package:fluttergetx/presentation/pages/chat/patient/chat_detail_page.dart';
import 'package:fluttergetx/presentation/pages/chat/patient/chat_list_page.dart';
import 'package:fluttergetx/presentation/pages/diagnosis/diagnosis_core_page.dart';
import 'package:fluttergetx/presentation/pages/diagnosis/diagnosis_history_page.dart';
import 'package:fluttergetx/presentation/pages/auth/login_page.dart';
import 'package:fluttergetx/presentation/pages/auth/register_page.dart';
import 'package:fluttergetx/presentation/pages/article/article_detail_page.dart';
import 'package:fluttergetx/presentation/pages/hospital/admin_hospital_page.dart';
import 'package:fluttergetx/presentation/pages/hospital/patient_hospital_page.dart';
import 'package:fluttergetx/presentation/pages/profile/edit_profile_page.dart';
import 'package:fluttergetx/presentation/pages/profile/profile_page.dart';
import 'package:fluttergetx/presentation/pages/splash/splash_screen.dart';
import 'package:fluttergetx/presentation/pages/admin/admin_entry_page.dart';
import 'package:fluttergetx/presentation/pages/widget/custom_button_navigation.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // Pastikan abstraction layer engine Flutter telah terinisialisasi
  WidgetsFlutterBinding.ensureInitialized();

  // Eksekusi pemuatan berkas konfigurasi secara paralel untuk reduksi overhead
  await Future.wait([
    dotenv.load(fileName: ".env"),
    initializeDateFormatting('id_ID'),
  ]);

  String apiUrl = dotenv.env['API_URL'] ?? '';
  if (apiUrl.isNotEmpty && !apiUrl.endsWith('/')) {
    apiUrl += '/';
  }

  // Daftarkan HTTP Client (Dio) ke dalam Service Locator GetX secara permanen
  Get.put(
    Dio(
      BaseOptions(
        baseUrl: apiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
      ),
    )
    ..interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('🌐 [DIO] $obj'),
      ),
    ),
    permanent: true,
  );

  final dio = Get.find<Dio>();
  dio.interceptors.add(TokenInterceptor(const FlutterSecureStorage(), dio));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'iCoass App',
      debugShowCheckedModeBanner: false,
      // initialBinding dikosongkan untuk menghindari penumpukan instansiasi binding di main thread awal
      initialBinding: null,
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(
          name: '/home',
          page: () => const MainNavigationWrapper(),
          bindings: [
            ChatBinding(),
            DiagnosisBinding(),
            HospitalBinding(),
            ArticleBinding(),
            LocationBinding(),
          ],
        ),
        GetPage(
          name: '/admin-home',
          page: () => const AdminEntryPage(),
          binding: ArticleBinding(),
        ),
        GetPage(
          name: '/admin-hospital',
          page: () => const AdminHospitalPage(),
          binding: HospitalBinding(),
        ),
        GetPage(
          name: '/patient-hospital',
          page: () => const PatientHospitalPage(),
          binding: HospitalBinding(),
        ),
        GetPage(name: '/register', page: () => const RegisterPage()),
        GetPage(
          name: '/diagnosis-history',
          page: () => const DiagnosisHistoryPage(),
          binding: DiagnosisBinding(),
        ),
        GetPage(
          name: '/diagnosis-core',
          page: () => const DiagnosisCorePage(),
          binding: DiagnosisBinding(),
        ),
        GetPage(
          name: '/profile',
          page: () => const ProfilePage(),
        ),
        GetPage(
          name: '/edit-profile',
          page: () => const EditProfilePage(),
        ),
        GetPage(
          name: '/patient-management',
          page: () => const UserManagementPage(),
        ),
        GetPage(
          name: '/add-patient',
          page: () => const UserFormPage(),
        ),
        GetPage(
          name: '/chat-list',
          page: () => const PatientChatListPage(),
          binding: ChatBinding(),
        ),
        GetPage(
          name: '/chat-detail',
          page: () => ChatDetailPage(),
          binding: ChatBinding(),
        ),
        GetPage(
          name: '/admin-chat-queue',
          page: () => AdminQueuePage(),
          binding: ChatBinding(),
        ),
        GetPage(
          name: '/admin-chat-list',
          page: () => AdminChatListPage(),
          binding: ChatBinding(),
        ),
        GetPage(
          name: '/admin-chat-detail',
          page: () => AdminChatDetailPage(),
          binding: ChatBinding(),
        ),
        GetPage(
          name: '/article-detail',
          page: () => const ArticleDetailPage(),
          binding: ArticleBinding(),
        ),
        GetPage(
          name: '/article-list',
          page: () => const ArticleListPage(),
          binding: ArticleBinding(),
        ),
        GetPage(
          name: '/article-add',
          page: () => const AdminArticlePage(),
          binding: ArticleBinding(),
        ),
      ],
      locale: const Locale('id', 'ID'),
      fallbackLocale: const Locale('en', 'US'),
      home: const SplashScreen(),
    );
  }
}