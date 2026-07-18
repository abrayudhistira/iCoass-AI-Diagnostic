import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:fluttergetx/data/services/auth_service.dart';
import 'package:fluttergetx/data/repositories/chat_repository_impl.dart';
import 'package:fluttergetx/domain/repositories/chat_repository.dart';
import 'package:fluttergetx/domain/usecases/chat/request_new_chat_usecase.dart';
import 'package:fluttergetx/domain/usecases/chat/get_chat_rooms_usecase.dart';
import 'package:fluttergetx/domain/usecases/chat/get_messages_usecase.dart';
import 'package:fluttergetx/domain/usecases/chat/get_queues_usecase.dart';
import 'package:fluttergetx/domain/usecases/chat/close_chat_usecase.dart';
import 'package:fluttergetx/domain/usecases/chat/accept_chat_usecase.dart';
import 'package:fluttergetx/domain/usecases/chat/send_message_usecase.dart';
import 'package:fluttergetx/presentation/controllers/chat_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    final dio = Get.isRegistered<Dio>() ? Get.find<Dio>() : Get.put(Dio());
    final authService = Get.find<AuthService>();

    // Repository
    Get.lazyPut<ChatRepository>(() => ChatRepositoryImpl(dio, authService));

    // UseCases
    Get.lazyPut(() => RequestNewChatUseCase(Get.find<ChatRepository>()));
    Get.lazyPut(() => GetChatRoomsUseCase(Get.find<ChatRepository>()));
    Get.lazyPut(() => GetMessagesUseCase(Get.find<ChatRepository>()));
    Get.lazyPut(() => GetQueuesUseCase(Get.find<ChatRepository>()));
    Get.lazyPut(() => CloseChatUseCase(Get.find<ChatRepository>()));
    Get.lazyPut(() => AcceptChatUseCase(Get.find<ChatRepository>()));
    Get.lazyPut(() => SendMessageUseCase(Get.find<ChatRepository>()));

    // Controller
    Get.put(ChatController(
      repository: Get.find<ChatRepository>(),
      requestNewChatUseCase: Get.find<RequestNewChatUseCase>(),
      getChatRoomsUseCase: Get.find<GetChatRoomsUseCase>(),
      getMessagesUseCase: Get.find<GetMessagesUseCase>(),
      getQueuesUseCase: Get.find<GetQueuesUseCase>(),
      closeChatUseCase: Get.find<CloseChatUseCase>(),
      acceptChatUseCase: Get.find<AcceptChatUseCase>(),
      sendMessageUseCase: Get.find<SendMessageUseCase>(),
    ));
  }
}
