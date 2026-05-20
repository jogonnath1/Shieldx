class ProfileModel {
  final String id;
  final String? name;
  final String? phone;
  final String? email;
  final String? nid;
  final String? profession;
  final String? presentAddress;
  final String? permanentAddress;
  final String role;
  final bool isVerified;
  final String? fcmToken;
  final DateTime? createdAt;

  const ProfileModel({
    required this.id,
    this.name,
    this.phone,
    this.email,
    this.nid,
    this.profession,
    this.presentAddress,
    this.permanentAddress,
    this.role = 'user',
    this.isVerified = false,
    this.fcmToken,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  String get displayName => name ?? email ?? 'User';

  String get initials {
    if (name != null && name!.trim().isNotEmpty) {
      final trimmedName = name!.trim();
      final parts = trimmedName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      if (parts.isNotEmpty) {
        return parts[0][0].toUpperCase();
      }
    }
    if (email != null && email!.trim().isNotEmpty) {
      return email!.trim()[0].toUpperCase();
    }
    return 'U';
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      name: map['name'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      nid: map['nid'] as String?,
      profession: map['profession'] as String?,
      presentAddress: map['present_address'] as String?,
      permanentAddress: map['permanent_address'] as String?,
      role: (map['role'] as String?) ?? 'user',
      isVerified: (map['is_verified'] as bool?) ?? false,
      fcmToken: map['fcm_token'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'nid': nid,
      'profession': profession,
      'present_address': presentAddress,
      'permanent_address': permanentAddress,
      'role': role,
      'is_verified': isVerified,
      'fcm_token': fcmToken,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? nid,
    String? profession,
    String? presentAddress,
    String? permanentAddress,
    String? role,
    bool? isVerified,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      nid: nid ?? this.nid,
      profession: profession ?? this.profession,
      presentAddress: presentAddress ?? this.presentAddress,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
