class MessageModel {
  final String id;
  final String? complaintId;
  final String? senderId;
  final String? senderRole;
  final String? content;
  final bool isRead;
  final DateTime? sentAt;

  // Joined
  final String? senderName;

  const MessageModel({
    required this.id,
    this.complaintId,
    this.senderId,
    this.senderRole,
    this.content,
    this.isRead = false,
    this.sentAt,
    this.senderName,
  });

  bool get isAdmin => senderRole == 'admin';

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as String,
      complaintId: map['complaint_id'] as String?,
      senderId: map['sender_id'] as String?,
      senderRole: map['sender_role'] as String?,
      content: map['content'] as String?,
      isRead: (map['is_read'] as bool?) ?? false,
      sentAt: map['sent_at'] != null
          ? DateTime.parse(map['sent_at'] as String)
          : null,
      senderName: map['sender_name'] as String?,
    );
  }
}
