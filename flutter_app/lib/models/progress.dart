class ProgressSummary {
  const ProgressSummary({
    required this.patientId,
    required this.totalSessions,
    required this.averageConfidence,
    required this.latestMovementStatus,
    required this.confidenceTrend,
    required this.movementHistory,
    required this.emotionHistory,
  });

  final int patientId;
  final int totalSessions;
  final double averageConfidence;
  final String latestMovementStatus;
  final List<double> confidenceTrend;
  final List<MovementTrendPoint> movementHistory;
  final List<EmotionTrendPoint> emotionHistory;

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    final trend = (json['confidence_trend'] as List<dynamic>? ?? const [])
        .map((entry) => (entry as num).toDouble())
        .toList();

    final movementHistory = ((json['movement_history'] as List<dynamic>? ?? const []))
        .map((entry) => MovementTrendPoint.fromJson(entry as Map<String, dynamic>))
        .toList();

    final emotionHistory = ((json['emotion_history'] as List<dynamic>? ?? const []))
        .map((entry) => EmotionTrendPoint.fromJson(entry as Map<String, dynamic>))
        .toList();

    return ProgressSummary(
      patientId: json['patient_id'] as int? ?? 0,
      totalSessions: json['total_sessions'] as int? ?? 0,
      averageConfidence: (json['average_confidence'] as num?)?.toDouble() ?? 0.0,
      latestMovementStatus: json['latest_movement_status'] as String? ?? 'Not Improved',
      confidenceTrend: trend,
      movementHistory: movementHistory,
      emotionHistory: emotionHistory,
    );
  }
}

class MovementTrendPoint {
  const MovementTrendPoint({required this.date, required this.status});

  final String date;
  final String status;

  factory MovementTrendPoint.fromJson(Map<String, dynamic> json) {
    return MovementTrendPoint(
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'Not Improved',
    );
  }
}

class EmotionTrendPoint {
  const EmotionTrendPoint({required this.date, required this.emotion});

  final String date;
  final String emotion;

  factory EmotionTrendPoint.fromJson(Map<String, dynamic> json) {
    return EmotionTrendPoint(
      date: json['date'] as String? ?? '',
      emotion: json['emotion'] as String? ?? 'No Face Detected',
    );
  }
}
