import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/workflow.dart';
import '../lib/widgets/workflow_suggestion_widget.dart';

void main() {
  testWidgets('WorkflowSuggestionWidget displays correctly',
      (WidgetTester tester) async {
    final workflow = Workflow.defaultWorkflow();

    // Mock callback functions
    Future<String> onExecuteStep(String step) async {
      return 'Executed: $step';
    }

    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: WorkflowSuggestionWidget(
              workflow: workflow,
              onDismiss: () {},
              onExecuteStep: onExecuteStep,
            ),
          ),
        ),
      ),
    );

    // Verify the title is displayed
    expect(find.text('Quy trình làm việc được đề xuất'), findsOneWidget);

    // Verify the description is displayed
    expect(
        find.text(
            'Đây là quy trình được AI đề xuất dựa trên phân tích sự kiện hiện tại'),
        findsOneWidget);

    // Verify the steps are displayed
    for (final step in workflow.steps) {
      expect(find.text(step), findsOneWidget);
    }

    // Verify the action buttons are displayed
    expect(find.text('Thực hiện tất cả'), findsOneWidget);
    expect(find.text('Thực hiện'),
        findsWidgets); // Multiple "Execute" buttons for each step

    // Verify the close button is visible
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
