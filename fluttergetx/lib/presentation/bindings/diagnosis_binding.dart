import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:fluttergetx/domain/repositories/diagnosis_repository.dart';
import 'package:fluttergetx/domain/usecases/diagnosis/fetch_diagnosis_usecase.dart';
import 'package:fluttergetx/domain/usecases/diagnosis/fetch_diagnosis_history_usecase.dart';
import 'package:fluttergetx/data/repositories/diagnosis_repository_impl.dart';
import 'package:fluttergetx/presentation/controllers/diagnosis_controller.dart';

class DiagnosisBinding extends Bindings {
  @override
  void dependencies() {
    // Repository
    Get.lazyPut<DiagnosisRepository>(
      () => DiagnosisRepositoryImpl(Get.find<Dio>()),
    );

    // UseCases
    Get.lazyPut<FetchDiagnosisUseCase>(() => FetchDiagnosisUseCase(Get.find<DiagnosisRepository>()));
    Get.lazyPut<FetchDiagnosisHistoryUseCase>(() => FetchDiagnosisHistoryUseCase(Get.find<DiagnosisRepository>()));

    // Controller
    Get.lazyPut(
      () => DiagnosisController(
        fetchDiagnosisUseCase: Get.find<FetchDiagnosisUseCase>(),
        fetchDiagnosisHistoryUseCase: Get.find<FetchDiagnosisHistoryUseCase>(),
      ),
    );
  }
}