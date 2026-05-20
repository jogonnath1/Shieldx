class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'complaint', 'sos', 'system'
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: (json['type'] as String?) ?? 'system',
      relatedId: json['related_id'] as String?,
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  // Alias for consistency with the rest of the codebase
  factory NotificationModel.fromMap(Map<String, dynamic> map) =>
      NotificationModel.fromJson(map);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'related_id': relatedId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isSos => type == 'sos';
  bool get isComplaint => type == 'complaint';

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      relatedId: relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
