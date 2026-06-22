class StatusHistoryModel {
  final String id;
  final String? complaintId;
  final String? status;
  final String? note;
  final String? changedBy;
  final DateTime? changedAt;
  final String? changedByName;
  const StatusHistoryModel({
    required this.id,
    this.complaintId,
    this.status,
    this.note,
    this.changedBy,
    this.changedAt,
    this.changedByName,
  });
  factory StatusHistoryModel.fromMap(Map<String, dynamic> map) {
    return StatusHistoryModel(
      id: map['id'] as String,
      complaintId: map['complaint_id'] as String?,
      status: map['status'] as String?,
      note: map['note'] as String?,
      changedBy: map['changed_by'] as String?,
      changedAt: map['changed_at'] != null
          ? DateTime.parse(map['changed_at'] as String)
          : null,
      changedByName: map['changed_by_name'] as String?,
    );
  }
}
