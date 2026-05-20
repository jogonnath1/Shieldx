import 'profile_model.dart';

class EmergencyModel {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final String status; // 'active', 'resolved', 'cancelled'
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final ProfileModel? userProfile; // Optional populated user profile

  const EmergencyModel({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.userProfile,
  });

  factory EmergencyModel.fromMap(Map<String, dynamic> map, {ProfileModel? userProfile}) {
    return EmergencyModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      resolvedAt: map['resolved_at'] != null
          ? DateTime.parse(map['resolved_at'] as String)
          : null,
      resolvedBy: map['resolved_by'] as String?,
      userProfile: userProfile ?? (map['profiles'] != null ? ProfileModel.fromMap(map['profiles'] as Map<String, dynamic>) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
    };
  }

  EmergencyModel copyWith({
    String? id,
    String? userId,
    double? latitude,
    double? longitude,
    String? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolvedBy,
    ProfileModel? userProfile,
  }) {
    return EmergencyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}
