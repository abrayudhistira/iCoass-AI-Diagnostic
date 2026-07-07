import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttergetx/presentation/controllers/auth_controller.dart';
import 'package:fluttergetx/presentation/bindings/auth_binding.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animasi untuk logo (fade + scale halus)
  late final AnimationController _logoAnimController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  // Warna brand diambil dari logo (gradient biru muda -> biru tua)
  static const Color _brandBlueLight = Color(0xFF4FC3F7);
  static const Color _brandBlueDark = Color(0xFF1565C0);

  static const Color _white = Color.fromARGB(255, 246, 246, 246);

  // Berapa lama splash screen ditampilkan sebelum pindah ke halaman berikutnya
  static const Duration _splashDuration = Duration(milliseconds: 4400);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _logoFade = CurvedAnimation(
      parent: _logoAnimController,
      curve: Curves.easeOut,
    );

    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimController, curve: Curves.easeOutBack),
    );

    // Langsung jadwalkan navigasi setelah delay, tanpa perlu menunggu video
    Future.delayed(_splashDuration, _navigateToNext);
  }

  void _navigateToNext() {
    if (!mounted) return;
    try {
      if (!Get.isRegistered<AuthController>()) {
        AuthBinding().dependencies();
      }
      Get.find<AuthController>().checkAuthStatus();
    } catch (e) {
      debugPrint("❌ Kegagalan Navigasi Subsistem Autentikasi: $e");
      Get.offAllNamed('/login');
    }
  }

  @override
  void dispose() {
    _logoAnimController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_white, _white],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _logoFade,
            child: ScaleTransition(
              scale: _logoScale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/icoass-logo.PNG',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.white,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.medical_services_rounded,
                              color: _brandBlueDark,
                              size: 56,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'iCoass',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color.fromARGB(255, 51, 144, 237),
                      letterSpacing: 0.5,
                    ),
                  ),
                  // const SizedBox(height: 6),
                  // Text(
                  //   'Kesehatan Gigi & Mulut Anda',
                  //   style: GoogleFonts.poppins(
                  //     fontSize: 12.5,
                  //     fontWeight: FontWeight.w400,
                  //     color: Colors.white.withOpacity(0.85),
                  //     letterSpacing: 0.3,
                  //   ),
                  // ),
                  const SizedBox(height: 28),
                  // const SizedBox(
                  //   width: 28,
                  //   height: 28,
                  //   child: CircularProgressIndicator(
                  //     strokeWidth: 2.5,
                  //     color: Colors.white,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}