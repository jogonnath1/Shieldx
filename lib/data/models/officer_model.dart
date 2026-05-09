class OfficerModel {
  final String id;
  final String? userId;
  final String? name;
  final String? rank;
  final String? station;
  final String? contact;
  final bool isActive;
  final DateTime? createdAt;

  const OfficerModel({
    required this.id,
    this.userId,
    this.name,
    this.rank,
    this.station,
    this.contact,
    this.isActive = true,
    this.createdAt,
  });

  factory OfficerModel.fromMap(Map<String, dynamic> map) {
    return OfficerModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      name: map['name'] as String?,
      rank: map['rank'] as String?,
      station: map['station'] as String?,
      contact: map['contact'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'rank': rank,
      'station': station,
      'contact': contact,
      'is_active': isActive,
    };
  }
}
