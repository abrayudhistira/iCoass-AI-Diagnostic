import 'package:get/get.dart';
import 'package:fluttergetx/data/repositories/hospital_repository_impl.dart';
import 'package:fluttergetx/domain/repositories/hospital_repository.dart';
import 'package:fluttergetx/domain/usecases/hospital/get_hospitals_usecase.dart';
import 'package:fluttergetx/domain/usecases/hospital/create_hospital_usecase.dart';
import 'package:fluttergetx/domain/usecases/hospital/update_hospital_usecase.dart';
import 'package:fluttergetx/domain/usecases/hospital/delete_hospital_usecase.dart';
import 'package:fluttergetx/presentation/controllers/hospital_controller.dart';

class HospitalBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Repository
    Get.lazyPut<HospitalRepository>(() => HospitalRepositoryImpl(Get.find()));

    // 2. UseCases
    Get.lazyPut(() => GetHospitalsUseCase(Get.find<HospitalRepository>()));
    Get.lazyPut(() => CreateHospitalUseCase(Get.find<HospitalRepository>()));
    Get.lazyPut(() => UpdateHospitalUseCase(Get.find<HospitalRepository>()));
    Get.lazyPut(() => DeleteHospitalUseCase(Get.find<HospitalRepository>()));

    // 3. Controller with injected UseCases
    Get.lazyPut<HospitalController>(
      () => HospitalController(
        getHospitals: Get.find<GetHospitalsUseCase>(),
        createHospitalUseCase: Get.find<CreateHospitalUseCase>(),
        updateHospitalUseCase: Get.find<UpdateHospitalUseCase>(),
        deleteHospitalUseCase: Get.find<DeleteHospitalUseCase>(),
      ),
    );
  }
}