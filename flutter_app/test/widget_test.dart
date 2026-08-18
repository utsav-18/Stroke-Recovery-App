import 'package:flutter_test/flutter_test.dart';

import 'package:stroke_recovery_monitoring/main.dart';

void main() {
  testWidgets('App launches with the RehabTrack login title', (tester) async {
    await tester.pumpWidget(const StrokeRecoveryApp());
    await tester.pumpAndSettle();

    expect(find.text('RehabTrack'), findsOneWidget);
  });
}
