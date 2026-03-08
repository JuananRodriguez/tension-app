class Reading {
  final int? id;
  final int userId;
  final int systolic;
  final int diastolic;
  final int? pulse;
  final String? notes;
  final String? createdAt;

  Reading({
    this.id,
    required this.userId,
    required this.systolic,
    required this.diastolic,
    this.pulse,
    this.notes,
    this.createdAt,
  });

  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
      id: json['id'],
      userId: json['user_id'],
      systolic: json['systolic'],
      diastolic: json['diastolic'],
      pulse: json['pulse'],
      notes: json['notes'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'notes': notes,
    };
  }
}
