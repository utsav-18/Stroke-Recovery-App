class ExerciseSession {
  const ExerciseSession({
    required this.id,
    required this.patientId,
    required this.exerciseType,
    required this.startedAt,
    required this.completedAt,
    this.movementStatus,
    this.confidenceScore,
    this.emotion,
  });

  final int id;
  final int patientId;
  final String exerciseType;
  final DateTime startedAt;
  final DateTime completedAt;
  final String? movementStatus;
  final double? confidenceScore;
  final String? emotion;

  factory ExerciseSession.fromJson(Map<String, dynamic> json) {
    final startedAt = DateTime.tryParse(json['started_at'] as String? ?? '') ?? DateTime.now();
    final completedAt = DateTime.tryParse(json['completed_at'] as String? ?? '') ?? startedAt;

    final analysis = json['analysis'] as Map<String, dynamic>?;

    return ExerciseSession(
      id: json['id'] as int? ?? 0,
      patientId: json['patient_id'] as int? ?? 0,
      exerciseType: json['exercise_type'] as String? ?? 'Exercise',
      startedAt: startedAt,
      completedAt: completedAt,
      movementStatus: analysis?['movement_status'] as String? ?? json['movement_status'] as String?,
      confidenceScore: (analysis?['confidence_score'] as num?)?.toDouble() ?? (json['confidence_score'] as num?)?.toDouble(),
      emotion: analysis?['emotion'] as String? ?? json['emotion'] as String?,
    );
  }
}
