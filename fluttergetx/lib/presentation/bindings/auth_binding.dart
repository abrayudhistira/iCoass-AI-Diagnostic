import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:fluttergetx/data/services/auth_service.dart';
import 'package:fluttergetx/data/repositories/auth_repository_impl.dart';
import 'package:fluttergetx/domain/repositories/auth_repository.dart';
import 'package:fluttergetx/domain/usecases/auth/delete_user_usecase.dart';
import 'package:fluttergetx/domain/usecases/auth/get_all_users_usecase.dart';
import 'package:fluttergetx/domain/usecases/auth/get_user_detail_usecase.dart';
import 'package:fluttergetx/domain/usecases/auth/login_usecase.dart';
import 'package:fluttergetx/domain/usecases/auth/logout_usecase.dart';
import 'package:fluttergetx/domain/usecases/auth/register_usecase.dart';
import 'package:fluttergetx/domain/usecases/auth/update_profile_usecase.dart';
import 'package:fluttergetx/domain/usecases/auth/update_user_usecase.dart';
import 'package:fluttergetx/presentation/controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Repository
    Get.put<AuthRepository>(
      AuthRepositoryImpl(Get.find<Dio>(), Get.find<AuthService>()),
      permanent: true,
    );

    // UseCases
    Get.put(LoginUseCase(Get.find<AuthRepository>()), permanent: true);
    Get.put(LogoutUseCase(Get.find<AuthRepository>()), permanent: true);
    Get.put(RegisterUseCase(Get.find<AuthRepository>()), permanent: true);
    Get.put(GetUserDetailUseCase(Get.find<AuthRepository>()), permanent: true);
    Get.put(GetAllUsersUseCase(Get.find<AuthRepository>()), permanent: true);
    Get.put(DeleteUserUseCase(Get.find<AuthRepository>()), permanent: true);
    Get.put(UpdateProfileUseCase(Get.find<AuthRepository>()), permanent: true);
    Get.put(UpdateUserUseCase(Get.find<AuthRepository>()), permanent: true);

    // Controller
    Get.put(
      AuthController(
        loginUseCase: Get.find<LoginUseCase>(),
        logoutUseCase: Get.find<LogoutUseCase>(),
        registerUseCase: Get.find<RegisterUseCase>(),
        getUserDetailUseCase: Get.find<GetUserDetailUseCase>(),
        getAllUsersUseCase: Get.find<GetAllUsersUseCase>(),
        deleteUserUseCase: Get.find<DeleteUserUseCase>(),
        updateProfileUseCase: Get.find<UpdateProfileUseCase>(),
        updateUserUseCase: Get.find<UpdateUserUseCase>(),
      ),
      permanent: true,
    );
  }
}
