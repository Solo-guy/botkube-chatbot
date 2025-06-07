import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../lib/widgets/chat_widget.dart';

void main() {
  testWidgets('ChatScreen builds without crashing',
      (WidgetTester tester) async {
    // Build the ChatScreen widget and trigger a frame.
    await tester.pumpWidget(
      const MaterialApp(
        home: ChatScreen(),
      ),
    );

    // Verify that the ChatScreen builds without throwing an exception.
    expect(find.byType(ChatScreen), findsOneWidget);
  });
}
