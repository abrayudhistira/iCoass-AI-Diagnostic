import 'package:dio/dio.dart';
import 'package:fluttergetx/domain/repositories/diagnosis_repository.dart';
import 'package:get/get.dart';
import '../../data/repositories/diagnosis_repository_impl.dart';
import '../controllers/diagnosis_controller.dart';

class DiagnosisBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DiagnosisRepository>(
      () => DiagnosisRepositoryImpl(Get.find<Dio>()),
    );
    Get.lazyPut(
      () => DiagnosisController(repository: Get.find<DiagnosisRepository>()),
    );
  }
}
