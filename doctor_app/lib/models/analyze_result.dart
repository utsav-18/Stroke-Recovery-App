class AnalyzeResult {
  const AnalyzeResult({
    required this.movementStatus,
    required this.confidenceScore,
    required this.emotion,
  });

  final String movementStatus;
  final double confidenceScore;
  final String emotion;

  factory AnalyzeResult.fromJson(Map<String, dynamic> json) {
    final movementStatus = json['movement_status'];
    final confidenceScore = json['confidence_score'];
    final emotion = json['emotion'];

    if (movementStatus is! String) {
      throw const FormatException('Invalid movement_status value in response.');
    }

    if (confidenceScore is! num) {
      throw const FormatException('Invalid confidence_score value in response.');
    }

    final parsedEmotion = emotion is String ? emotion : 'No Face Detected';

    return AnalyzeResult(
      movementStatus: movementStatus,
      confidenceScore: confidenceScore.toDouble(),
      emotion: parsedEmotion,
    );
  }
}
