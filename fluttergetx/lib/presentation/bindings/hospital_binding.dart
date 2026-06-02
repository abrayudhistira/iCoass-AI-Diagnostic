import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../data/repositories/hospital_repository_impl.dart';
import '../controllers/hospital_controller.dart';

class HospitalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HospitalRepositoryImpl(Get.find<Dio>())
    );
    Get.lazyPut(
      () => HospitalController(repository: Get.find<HospitalRepositoryImpl>()),
    );
  }
}
