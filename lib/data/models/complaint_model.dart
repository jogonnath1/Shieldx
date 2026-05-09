class ComplaintModel {
  final String id;
  final String? userId;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? nid;
  final String? profession;
  final String? presentAddress;
  final String? permanentAddress;
  final String? crimeCategory;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final DateTime? incidentDatetime;
  final String status;
  final String? assignedOfficerId;
  final List<String> evidenceUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isAnonymous;

  // Joined fields
  final String? assignedOfficerName;
  final String? userEmail;
  final String? userName;

  const ComplaintModel({
    required this.id,
    this.userId,
    this.firstName,
    this.lastName,
    this.phone,
    this.nid,
    this.profession,
    this.presentAddress,
    this.permanentAddress,
    this.crimeCategory,
    this.description,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.incidentDatetime,
    this.status = 'submitted',
    this.assignedOfficerId,
    this.evidenceUrls = const [],
    this.createdAt,
    this.updatedAt,
    this.assignedOfficerName,
    this.userEmail,
    this.userName,
    this.isAnonymous = false,
  });

  String get fullName {
    if (isAnonymous) return 'Anonymous User';
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? 'Unknown';
  }

  String get caseId => id.substring(0, 8).toUpperCase();

  factory ComplaintModel.fromMap(Map<String, dynamic> map) {
    List<String> urls = [];
    if (map['evidence_urls'] != null) {
      if (map['evidence_urls'] is List) {
        urls = List<String>.from(map['evidence_urls'] as List);
      }
    }
    return ComplaintModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      phone: map['phone'] as String?,
      nid: map['nid'] as String?,
      profession: map['profession'] as String?,
      presentAddress: map['present_address'] as String?,
      permanentAddress: map['permanent_address'] as String?,
      crimeCategory: map['crime_category'] as String?,
      description: map['description'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationAddress: map['location_address'] as String?,
      incidentDatetime: map['incident_datetime'] != null
          ? DateTime.parse(map['incident_datetime'] as String)
          : null,
      status: (map['status'] as String?) ?? 'submitted',
      assignedOfficerId: map['assigned_officer_id'] as String?,
      evidenceUrls: urls,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      assignedOfficerName: map['assigned_officer_name'] as String?,
      userEmail: map['user_email'] as String?,
      userName: map['user_name'] as String?,
      isAnonymous: (map['is_anonymous'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'nid': nid,
      'profession': profession,
      'present_address': presentAddress,
      'permanent_address': permanentAddress,
      'crime_category': crimeCategory,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'location_address': locationAddress,
      'incident_datetime': incidentDatetime?.toIso8601String(),
      'evidence_urls': evidenceUrls,
      'is_anonymous': isAnonymous,
    };
  }
}
