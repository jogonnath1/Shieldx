class ActivityLogModel {
  final String id;
  final String? userId;
  final String? userEmail;
  final String? userName;
  final String role;
  final String actionType;
  final Map<String, dynamic> details;
  final int durationSeconds;
  final String? sessionId;
  final DateTime createdAt;

  const ActivityLogModel({
    required this.id,
    this.userId,
    this.userEmail,
    this.userName,
    required this.role,
    required this.actionType,
    this.details = const {},
    this.durationSeconds = 0,
    this.sessionId,
    required this.createdAt,
  });

  factory ActivityLogModel.fromMap(Map<String, dynamic> map) {
    return ActivityLogModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      userEmail: map['user_email'] as String?,
      userName: map['user_name'] as String?,
      role: map['role'] as String? ?? 'user',
      actionType: map['action_type'] as String,
      details: map['details'] != null
          ? Map<String, dynamic>.from(map['details'] as Map)
          : const {},
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      sessionId: map['session_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_email': userEmail,
      'user_name': userName,
      'role': role,
      'action_type': actionType,
      'details': details,
      'duration_seconds': durationSeconds,
      'session_id': sessionId,
    };
  }

  // Getters for UI display
  String get actionDescription {
    switch (actionType) {
      case 'app_open':
        return 'Opened the app';
      case 'app_close':
        if (durationSeconds > 0) {
          final minutes = (durationSeconds / 60).toStringAsFixed(1);
          return 'Closed the app (used for $minutes mins)';
        }
        return 'Closed the app';
      case 'login':
        return 'Signed in successfully';
      case 'logout':
        return 'Signed out';
      case 'report_submit':
        final cat = details['category'] ?? 'crime';
        return 'Submitted a $cat report';
      case 'report_edit':
        return 'Edited crime report';
      case 'report_delete':
        return 'Deleted crime report';
      case 'profile_update':
        final fields = details['changed_fields'] as List?;
        if (fields != null && fields.isNotEmpty) {
          return 'Updated profile (${fields.join(', ')})';
        }
        return 'Updated profile';
      case 'suspicious_login':
        return 'Suspicious login: ${details['reason'] ?? 'Failed credentials'}';
      default:
        return 'Performed action: $actionType';
    }
  }
}
