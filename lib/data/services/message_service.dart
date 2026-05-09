import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';
import '../../core/constants/app_constants.dart';

class MessageService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<MessageModel>> getMessages(String complaintId) async {
    final response = await _client
        .from(AppConstants.messagesTable)
        .select()
        .eq('complaint_id', complaintId)
        .order('sent_at', ascending: true);
    return (response as List).map((e) => MessageModel.fromMap(e)).toList();
  }

  Future<void> sendMessage({
    required String complaintId,
    required String senderId,
    required String senderRole,
    required String content,
  }) async {
    await _client.from(AppConstants.messagesTable).insert({
      'complaint_id': complaintId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'content': content,
    });
  }

  Future<void> markAsRead(String complaintId, String currentUserId) async {
    await _client
        .from(AppConstants.messagesTable)
        .update({'is_read': true})
        .eq('complaint_id', complaintId)
        .neq('sender_id', currentUserId);
  }

  Stream<List<MessageModel>> watchMessages(String complaintId) {
    return _client
        .from(AppConstants.messagesTable)
        .stream(primaryKey: ['id'])
        .eq('complaint_id', complaintId)
        .order('sent_at', ascending: true)
        .map((data) => data.map((e) => MessageModel.fromMap(e)).toList());
  }

  Future<int> getUnreadCount(String complaintId, String currentUserId) async {
    final response = await _client
        .from(AppConstants.messagesTable)
        .select()
        .eq('complaint_id', complaintId)
        .eq('is_read', false)
        .neq('sender_id', currentUserId);
    return (response as List).length;
  }
}
