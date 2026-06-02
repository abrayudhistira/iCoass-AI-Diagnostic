import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Gunakan put agar instance langsung dibuat
    Get.put<AuthRepository>(AuthRepositoryImpl(Get.find<Dio>()), permanent: true);
    Get.put(AuthController(Get.find<AuthRepository>()), permanent: true);
  }
}