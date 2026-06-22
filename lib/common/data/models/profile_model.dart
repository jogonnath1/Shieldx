class ProfileModel {
  final String id;
  final String? name;
  final String? phone;
  final String? email;
  final String? nid;
  final String? profession;
  final String? presentAddress;
  final String? permanentAddress;
  final String? avatarUrl;
  final String role;
  final bool isVerified;
  final bool isBlocked;
  final bool _isMainAdmin;
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
    this.avatarUrl,
    this.role = 'user',
    this.isVerified = false,
    this.isBlocked = false,
    bool isMainAdmin = false,
    this.fcmToken,
    this.createdAt,
  }) : _isMainAdmin = isMainAdmin;
  bool get isAdmin => role == 'admin';
  bool get isMainAdmin => _isMainAdmin || email == 'raj0195923@gmail.com';
  String get displayName => name ?? email ?? 'User';
  String get initials {
    if (name != null && name!.trim().isNotEmpty) {
      final trimmedName = name!.trim();
      final parts =
          trimmedName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
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
      avatarUrl: map['avatar_url'] as String?,
      role: (map['role'] as String?) ?? 'user',
      isVerified: (map['is_verified'] as bool?) ?? false,
      isBlocked: (map['is_blocked'] as bool?) ?? false,
      isMainAdmin: (map['is_main_admin'] as bool?) ?? false,
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
      'avatar_url': avatarUrl,
      'role': role,
      'is_verified': isVerified,
      'is_blocked': isBlocked,
      'is_main_admin': _isMainAdmin,
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
    String? avatarUrl,
    String? role,
    bool? isVerified,
    bool? isBlocked,
    bool? isMainAdmin,
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
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      isMainAdmin: isMainAdmin ?? _isMainAdmin,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
