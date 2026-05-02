class AnalyzeResult {
  const AnalyzeResult({
    required this.movementStatus,
    required this.confidenceScore,
  });

  final String movementStatus;
  final double confidenceScore;

  factory AnalyzeResult.fromJson(Map<String, dynamic> json) {
    final movementStatus = json['movement_status'];
    final confidenceScore = json['confidence_score'];

    if (movementStatus is! String) {
      throw const FormatException('Invalid movement_status value in response.');
    }

    if (confidenceScore is! num) {
      throw const FormatException('Invalid confidence_score value in response.');
    }

    return AnalyzeResult(
      movementStatus: movementStatus,
      confidenceScore: confidenceScore.toDouble(),
    );
  }
}
