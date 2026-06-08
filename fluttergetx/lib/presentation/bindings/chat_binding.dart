import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/repositories/chat_repository.dart';
import '../controllers/chat_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    // Gunakan Dio yang sudah ada, atau buat baru jika tidak ditemukan
    final dio = Get.isRegistered<Dio>() ? Get.find<Dio>() : Get.put(Dio());
    
    // Repository
    Get.lazyPut<ChatRepository>(() => ChatRepositoryImpl(dio));
    
    // Controller
    Get.put(ChatController(Get.find<ChatRepository>()));
  }
}
