import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../lib/main.dart';

void main() {
  testWidgets('BotkubeApp builds without crashing',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BotkubeApp());

    // Verify that the app builds without throwing an exception.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
