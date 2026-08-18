import 'package:flutter/material.dart';

import '../models/analyze_result.dart';

class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({super.key, required this.result});

  final AnalyzeResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Result')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ResultCard(
              title: 'Movement',
              value: result.movementStatus,
              color: _statusColor(result.movementStatus),
            ),
            const SizedBox(height: 16),
            _ResultCard(
              title: 'Confidence',
              value: '${(result.confidenceScore * 100).toStringAsFixed(1)}%',
              color: const Color(0xFF60A5FA),
            ),
            const SizedBox(height: 16),
            _ResultCard(
              title: 'Emotion',
              value: result.emotion,
              color: const Color(0xFF61E4C5),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('improved')) return const Color(0xFF22C55E);
    if (normalized.contains('improving')) return const Color(0xFFEAB308);
    return const Color(0xFFEF4444);
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.title, required this.value, required this.color});

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF24314A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF9FB1CA))),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
