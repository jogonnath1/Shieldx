import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/message_service.dart';
import 'auth_provider.dart';

final messageServiceProvider = Provider<MessageService>((ref) => MessageService());

final unreadMessagesCountProvider = StreamProvider.family<int, String>((ref, complaintId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(0);
  }
  
  final messageService = ref.watch(messageServiceProvider);
  return messageService.watchMessages(complaintId).map((messages) {
    return messages.where((m) => !m.isRead && m.senderId != user.id).length;
  });
});
