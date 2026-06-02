import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttergetx/data/interceptors/token_interceptor.dart';
import 'package:fluttergetx/presentation/bindings/auth_binding.dart';
import 'package:fluttergetx/presentation/bindings/chat_binding.dart';
import 'package:fluttergetx/presentation/bindings/diagnosis_binding.dart';
import 'package:fluttergetx/presentation/bindings/hospital_binding.dart';
import 'package:fluttergetx/presentation/pages/account-management/add_user_management.dart';
import 'package:fluttergetx/presentation/pages/account-management/user_management.dart';
import 'package:fluttergetx/presentation/pages/chat/admin/admin_chat_detail_page.dart';
import 'package:fluttergetx/presentation/pages/chat/admin/chat_list_page.dart';
import 'package:fluttergetx/presentation/pages/chat/admin/queue_pages.dart';
import 'package:fluttergetx/presentation/pages/chat/patient/chat_detail_page.dart';
import 'package:fluttergetx/presentation/pages/chat/patient/chat_list_page.dart';
import 'package:fluttergetx/presentation/pages/diagnosis/diagnosis_core_page.dart';
import 'package:fluttergetx/presentation/pages/diagnosis/diagnosis_history_page.dart';
import 'package:fluttergetx/presentation/pages/home/admin_home_page.dart';
import 'package:fluttergetx/presentation/pages/auth/login_page.dart';
import 'package:fluttergetx/presentation/pages/auth/register_page.dart';
import 'package:fluttergetx/presentation/pages/home/home_page.dart';
import 'package:fluttergetx/presentation/controllers/auth_controller.dart';
import 'package:fluttergetx/presentation/pages/hospital/admin_hospital_page.dart';
import 'package:fluttergetx/presentation/pages/hospital/patient_hospital_page.dart';
import 'package:fluttergetx/presentation/pages/profile/edit_profile_page.dart';
import 'package:fluttergetx/presentation/pages/profile/profile_page.dart';
import 'package:fluttergetx/presentation/pages/widget/custom_button_navigation.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lottie/lottie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Inisialisasi locale untuk format tanggal penelitian
  await initializeDateFormatting('id_ID');

  Get.put(
    Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_URL'] ?? '',
        connectTimeout: const Duration(seconds: 30), // Ditingkatkan ke 30 detik
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'Accept': 'application/json',
        },
      ),
    )..interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('🌐 [DIO] $obj'),
      )),
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
      // PERBAIKAN 1: Gunakan initialBinding agar GetX mengelola AuthController sejak awal
      initialBinding: AuthBinding(),
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/home', page: () => const MainNavigationWrapper()),
        GetPage(name: '/admin-home', page: () => const AdminHomePage()),
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
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/edit-profile',
          page: () => const EditProfilePage(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/patient-management',
          page: () => const UserManagementPage(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/add-patient',
          page: () => const UserFormPage(),
          binding: AuthBinding(),
        ),
        // [IMPORTANT] ini punya patient
        GetPage(
          name: '/chat-list',
          page: () => const PatientChatListPage(),
          binding: ChatBinding(),
        ),
        // [IMPORTANT] ini punya patient
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
      ],
      locale: const Locale('id', 'ID'),
      fallbackLocale: const Locale('en', 'US'),
      home: const InitialAuthChecker(),
    );
  }
}

class InitialAuthChecker extends StatefulWidget {
  const InitialAuthChecker({super.key});

  @override
  State<InitialAuthChecker> createState() => _InitialAuthCheckerState();
}

class _InitialAuthCheckerState extends State<InitialAuthChecker> {
  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  // PERBAIKAN 2: Gunakan fungsi async formal untuk validasi sesi
  Future<void> _checkStatus() async {
    // Memberikan waktu buffer bagi engine Flutter dan Lottie untuk render
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Pastikan AuthController sudah ter-inject melalui initialBinding
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().checkAuthStatus();
      } else {
        // Fallback jika binding gagal (Safety net)
        AuthBinding().dependencies();
        Get.find<AuthController>().checkAuthStatus();
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/lottie/loading_animation.json',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const CircularProgressIndicator(color: Colors.blueGrey);
              },
            ),
            const SizedBox(height: 24),
            const Text(
              "Pengecekan Keamanan...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
