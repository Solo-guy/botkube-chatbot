import 'package:flutter/material.dart';
import '../models/workflow.dart';
import '../main.dart';
import '../utils/config.dart';
import '../api_service.dart';
import '../screens/workflows_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class WorkflowSuggestionWidget extends StatefulWidget {
  final Workflow workflow;
  final VoidCallback onDismiss;
  final Future<String> Function(String) onExecuteStep;

  const WorkflowSuggestionWidget({
    Key? key,
    required this.workflow,
    required this.onDismiss,
    required this.onExecuteStep,
  }) : super(key: key);

  @override
  _WorkflowSuggestionWidgetState createState() =>
      _WorkflowSuggestionWidgetState();
}

class _WorkflowSuggestionWidgetState extends State<WorkflowSuggestionWidget>
    with SingleTickerProviderStateMixin {
  // Track which steps have been executed
  Map<int, bool> executedSteps = {};
  Map<int, bool> loadingSteps = {};
  Map<int, String> stepResults = {};
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isSaving = false;
  bool _isExecutingAll = false;
  String? _saveError;
  final TextEditingController _workflowNameController = TextEditingController();
  String? _executionResult;
  String? _executionError;
  bool _isExecuting = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    // Set default workflow name
    _workflowNameController.text = widget.workflow.title;

    // Print debug info about workflow
    print('Workflow initialized with ${widget.workflow.steps.length} steps');
    for (int i = 0; i < widget.workflow.steps.length; i++) {
      print('Step ${i + 1}: ${widget.workflow.steps[i]}');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _workflowNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkflow({bool executeAfterSaving = false}) async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      // Get the token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? "";

      if (token.isEmpty) {
        setState(() {
          _saveError = "Bạn cần đăng nhập để lưu quy trình làm việc";
          _isSaving = false;
        });
        return;
      }

      // Validate workflow name
      if (_workflowNameController.text.trim().isEmpty) {
        setState(() {
          _saveError = "Vui lòng nhập tên cho quy trình làm việc";
          _isSaving = false;
        });
        return;
      }

      // Create a custom workflow
      final customWorkflow = Workflow.fromSuggested(
        widget.workflow.steps,
        customTitle: _workflowNameController.text,
        customDescription: "Quy trình làm việc được lưu từ đề xuất của AI",
      );

      // Log workflow for debugging
      print('Saving workflow: ${customWorkflow.title}');
      print('Workflow steps: ${customWorkflow.steps.length}');
      for (var i = 0; i < customWorkflow.steps.length; i++) {
        print('Step ${i + 1}: ${customWorkflow.steps[i]}');
      }

      // Try to save the workflow to server first
      final apiService = ApiService();
      final savedWorkflow =
          await apiService.saveWorkflow(customWorkflow, token);

      if (savedWorkflow != null) {
        _showSuccessNotification();
      } else {
        // Server save failed, save locally
        print('Server save failed. Saving workflow locally...');
        await _saveWorkflowLocally(customWorkflow);
        _showSuccessNotification(isLocal: true);
      }

      if (executeAfterSaving) {
        await _executeAllSteps();
      }
    } catch (e) {
      print('Error saving workflow: $e');

      // Try to save locally as a fallback
      try {
        final customWorkflow = Workflow.fromSuggested(
          widget.workflow.steps,
          customTitle: _workflowNameController.text,
          customDescription:
              "Quy trình làm việc được lưu từ đề xuất của AI (Lưu cục bộ)",
        );
        await _saveWorkflowLocally(customWorkflow);
        _showSuccessNotification(isLocal: true);

        if (executeAfterSaving) {
          await _executeAllSteps();
        }
      } catch (localError) {
        setState(() {
          _saveError = "Lỗi khi lưu quy trình: $localError";
        });
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Save workflow locally when server is unavailable
  Future<void> _saveWorkflowLocally(Workflow workflow) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing workflows
      final workflowsJson = prefs.getStringList('local_workflows') ?? [];
      final List<Workflow> workflows = workflowsJson
          .map((json) => Workflow.fromJson(jsonDecode(json)))
          .toList();

      // Check if workflow with same ID exists
      final existingIndex = workflows.indexWhere((w) => w.id == workflow.id);
      if (existingIndex >= 0) {
        workflows[existingIndex] = workflow;
      } else {
        workflows.add(workflow);
      }

      // Save updated list
      final updatedJson = workflows.map((w) => jsonEncode(w.toJson())).toList();

      await prefs.setStringList('local_workflows', updatedJson);
      print('Saved workflow locally: ${workflow.title}');
    } catch (e) {
      print('Error saving workflow locally: $e');
      throw e;
    }
  }

  // Show success notification after saving
  void _showSuccessNotification({bool isLocal = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isLocal
            ? 'Đã lưu quy trình làm việc cục bộ (không kết nối với máy chủ)'
            : 'Đã lưu quy trình làm việc thành công'),
        backgroundColor: isLocal ? Colors.orange : Colors.green,
        action: SnackBarAction(
          label: 'Xem quy trình',
          textColor: Colors.white,
          onPressed: () => _navigateToWorkflowsScreen(),
        ),
      ),
    );

    // Show a dialog asking if user wants to go to workflows screen
    _showWorkflowSavedDialog(isLocal: isLocal);
  }

  // Show dialog after saving a workflow
  void _showWorkflowSavedDialog({bool isLocal = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quy trình đã được lưu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Bạn có muốn chuyển đến trang Quy trình làm việc để xem và thực thi quy trình đã lưu không?'),
            if (isLocal)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(
                    'Lưu ý: Quy trình được lưu cục bộ do không thể kết nối với máy chủ. Quy trình sẽ không được đồng bộ giữa các thiết bị.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToWorkflowsScreen();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: Text('Đi đến Quy trình'),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog() {
    bool executeAfterSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Lưu quy trình làm việc'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _workflowNameController,
                decoration: InputDecoration(
                  labelText: 'Tên quy trình',
                  hintText: 'Nhập tên cho quy trình làm việc',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Quy trình này sẽ được lưu và có thể sử dụng lại sau.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 12),
              CheckboxListTile(
                title: Text(
                  'Tự động thực thi quy trình sau khi lưu',
                  style: TextStyle(fontSize: 14),
                ),
                value: executeAfterSaving,
                onChanged: (value) {
                  setState(() {
                    executeAfterSaving = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(executeAfterSaving);
                _saveWorkflow(executeAfterSaving: executeAfterSaving);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size to make responsive adjustments
    final screenSize = MediaQuery.of(context).size;
    final isMobile = AppConfig.isMobileDevice || screenSize.width < 600;

    // Print platform info for debugging
    print('Building WorkflowSuggestionWidget');
    print('Screen width: ${screenSize.width}, isMobile: $isMobile');
    print(
        'Platform: ${AppConfig.isWeb ? "Web" : "Native"}, Mobile Device: ${AppConfig.isMobileDevice}');
    print('Platform: Web, Mobile Device: ${AppConfig.isMobileDevice}');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: FadeTransition(
        opacity: _animation,
        child: ScaleTransition(
          scale: _animation,
          child: Material(
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with improved gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF004D40), // Darker green
                        Color(0xFF00796B), // Medium green
                      ],
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 20,
                      vertical: isMobile ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.workflow.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 16 : 18,
                                color: Colors.white,
                                letterSpacing: 0.2,
                                fontFamily: 'Roboto', // Ensure consistent font
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: widget.onDismiss,
                            tooltip: 'Đóng',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                            ),
                            padding: EdgeInsets.all(isMobile ? 4 : 8),
                            constraints: BoxConstraints(
                              minHeight: isMobile ? 32 : 48,
                              minWidth: isMobile ? 32 : 48,
                            ),
                          ),
                        ],
                      ),
                      if (widget.workflow.steps.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: isMobile ? 8 : 12),
                          child: Row(
                            children: [
                              // Execute All Button
                              ElevatedButton.icon(
                                onPressed:
                                    _isExecutingAll ? null : _executeAllSteps,
                                icon: _isExecutingAll
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white70),
                                        ),
                                      )
                                    : Icon(Icons.play_arrow,
                                        color: Colors.white,
                                        size: isMobile ? 18 : 24),
                                label: Text(
                                  'Thực hiện tất cả',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 13 : 14,
                                    fontFamily:
                                        'Roboto', // Ensure consistent font
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withOpacity(0.2),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 8 : 12,
                                      vertical: isMobile ? 6 : 8),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              // Save Workflow Button
                              ElevatedButton.icon(
                                onPressed: _isSaving ? null : _showSaveDialog,
                                icon: _isSaving
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white70),
                                        ),
                                      )
                                    : Icon(Icons.save_alt,
                                        color: Colors.white,
                                        size: isMobile ? 18 : 24),
                                label: Text(
                                  'Lưu quy trình',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 13 : 14,
                                    fontFamily:
                                        'Roboto', // Ensure consistent font
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.withOpacity(0.6),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 8 : 12,
                                      vertical: isMobile ? 6 : 8),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_saveError != null)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            _saveError!,
                            style: TextStyle(
                              color: Colors.red[300],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Description if available
                if (widget.workflow.description != null)
                  Container(
                    color: Color(0xFFF5F9F7), // Light mint background
                    padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : 20,
                        isMobile ? 8 : 12,
                        isMobile ? 16 : 20,
                        isMobile ? 8 : 12),
                    width: double.infinity,
                    child: Text(
                      widget.workflow.description!,
                      style: TextStyle(
                        color: Color(0xFF2E7D32), // Green text
                        fontSize: isMobile ? 13 : 14,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Roboto', // Ensure consistent font
                      ),
                    ),
                  ),
                // Workflow steps list with improved styling
                Flexible(
                  child: widget.workflow.steps.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Không có quy trình nào được đề xuất',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                                fontFamily: 'Roboto',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.white,
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: AlwaysScrollableScrollPhysics(),
                            itemCount: widget.workflow.steps.length,
                            itemBuilder: (context, index) {
                              final step = widget.workflow.steps[index];
                              final isExecuted = executedSteps[index] ?? false;
                              final isLoading = loadingSteps[index] ?? false;
                              final result = stepResults[index] ?? '';

                              // Special handling for ghost-related workflow steps
                              final isGhostRelated = _containsGhostTerm(step);

                              return Card(
                                margin:
                                    EdgeInsets.only(bottom: isMobile ? 8 : 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isExecuted
                                        ? Color(
                                            0xFF2E7D32) // Darker green for executed
                                        : isGhostRelated
                                            ? Colors.purple
                                                .shade300 // Purple for ghost
                                            : Colors.grey.shade300,
                                    width: isExecuted || isGhostRelated ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Step content
                                    Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text(
                                        step,
                                        style: TextStyle(
                                          fontWeight: isExecuted
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isExecuted
                                              ? Color(0xFF2E7D32)
                                              : isGhostRelated
                                                  ? Colors.purple.shade700
                                                  : Colors.black87,
                                          fontSize: 14,
                                          fontFamily:
                                              'Roboto', // Ensure consistent font for Vietnamese text
                                        ),
                                      ),
                                    ),

                                    // Step result if executed
                                    if (isExecuted && result.isNotEmpty)
                                      Container(
                                        width: double.infinity,
                                        padding:
                                            EdgeInsets.fromLTRB(12, 0, 12, 12),
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                          ),
                                          child: Text(
                                            result,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                              fontFamily:
                                                  'Roboto', // Ensure consistent font
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Button row
                                    Padding(
                                      padding:
                                          EdgeInsets.fromLTRB(12, 0, 12, 12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (isLoading)
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        Color(0xFF2E7D32)),
                                              ),
                                            )
                                          else
                                            ElevatedButton(
                                              onPressed: () =>
                                                  _executeStep(step),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isExecuted
                                                    ? Color(
                                                        0xFFE8F5E9) // Light green if already executed
                                                    : isGhostRelated
                                                        ? Colors.purple
                                                            .shade600 // Purple for ghost
                                                        : (stepResults[index] ??
                                                                    "")
                                                                .startsWith(
                                                                    "Lỗi:")
                                                            ? Colors
                                                                .red // Red for error
                                                            : Color(
                                                                0xFF2E7D32), // Dark green otherwise
                                                foregroundColor: isExecuted
                                                    ? Color(0xFF2E7D32)
                                                    : Colors.white,
                                                elevation: isExecuted ? 0 : 2,
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: Text(
                                                (stepResults[index] ?? "")
                                                        .startsWith("Lỗi:")
                                                    ? 'Thực hiện lại'
                                                    : isExecuted
                                                        ? 'Thực hiện lại'
                                                        : 'Thực hiện',
                                                style: TextStyle(
                                                  fontFamily:
                                                      'Roboto', // Ensure consistent font
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Execute a workflow step and show the result
  Future<void> _executeStep(String step) async {
    // Get the index of the step
    int index = widget.workflow.steps.indexOf(step);
    if (index == -1) {
      print('Step not found in workflow: $step');
      return;
    }

    setState(() {
      _isExecuting = true;
      loadingSteps[index] = true;
      _executionResult = null;
      _executionError = null;
    });

    try {
      final result = await widget.onExecuteStep(step);

      // Check if result indicates connectivity issues
      if (result.contains('không thể kết nối') ||
          result.contains('không thể thực thi')) {
        setState(() {
          _isExecuting = false;
          loadingSteps[index] = false;
          _executionError = null; // Don't treat as an error
          _executionResult =
              "Bạn đang làm việc ở chế độ ngoại tuyến. Các hướng dẫn vẫn có thể xem được nhưng không thể thực thi từ xa.";
          executedSteps[index] = true;
        });
      } else {
        setState(() {
          _isExecuting = false;
          loadingSteps[index] = false;
          _executionResult = result;
          _executionError = null;
          executedSteps[index] = true;
          stepResults[index] = result;
        });
      }
    } catch (e) {
      setState(() {
        _isExecuting = false;
        loadingSteps[index] = false;
        _executionError = e.toString();
        _executionResult = null;
      });
    }
  }

  // Run all steps in the workflow
  Future<void> _executeAllSteps() async {
    int successCount = 0;

    for (int i = 0; i < widget.workflow.steps.length; i++) {
      final step = widget.workflow.steps[i];

      // Skip already executed steps
      if (executedSteps[i] == true) {
        successCount++;
        continue;
      }

      try {
        // Scroll to the step
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            i * 80.0, // Approximate height of each step
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }

        await _executeStep(step);
        successCount++;

        // If step failed or we're offline, stop execution
        final stepResult = stepResults[i];
        if (stepResult != null &&
            (stepResult.contains('không thể kết nối') ||
                stepResult.contains('ngoại tuyến'))) {
          setState(() {
            _isExecutingAll = false;
          });
          break;
        }
      } catch (e) {
        print('Error executing step: $e');
        setState(() {
          _isExecutingAll = false;
        });
        break;
      }
    }

    setState(() {
      _isExecutingAll = false;
    });
  }

  // Save workflow with a title
  Future<void> _saveWorkflowWithTitle(String title) async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      // Create a new workflow from current steps
      final workflowToSave = Workflow.fromSuggested(
        widget.workflow.steps,
        customTitle: title.isEmpty ? 'Quy trình đã lưu' : title,
        customDescription: 'Quy trình được tạo từ đề xuất.',
      );

      // Get instance of chat provider
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.saveWorkflow(workflowToSave);

      setState(() {
        _isSaving = false;
        _workflowNameController.clear();
      });

      // Close the dialog
      Navigator.of(context).pop();

      // Show success message in a less intrusive way (small toast instead of banner)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu quy trình.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
        _saveError = 'Lỗi khi lưu: $e';
      });
    }
  }

  // Helper method to check if a step contains ghost-related terms
  bool _containsGhostTerm(String step) {
    final lowerStep = step.toLowerCase();
    final ghostTerms = [
      'ma',
      'quỷ',
      'tâm linh',
      'linh hồn',
      'hồn',
      'ám',
      'kinh dị',
      'rùng rợn',
      'chuyện ma',
      'bóng đêm',
      'mộ',
      'nghĩa địa',
      'ma quỷ',
      'siêu nhiên',
      'thiền'
    ];

    // Only treat as ghost-related if we find multiple terms or specific terms
    // This prevents false positives with the word "ma" which is common in Vietnamese
    if (lowerStep.contains('tâm linh') ||
        lowerStep.contains('ma quỷ') ||
        lowerStep.contains('linh hồn') ||
        lowerStep.contains('thiền định')) {
      return true;
    }

    int matchCount = 0;
    for (final term in ghostTerms) {
      if (lowerStep.contains(term)) {
        matchCount++;
        if (matchCount >= 2) return true;
      }
    }

    return false;
  }

  // Add a method to navigate to the workflows screen
  void _navigateToWorkflowsScreen() {
    // Close the workflow suggestion widget
    if (widget.onDismiss != null) {
      widget.onDismiss();
    }

    // Navigate to the workflows screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkflowsScreen(),
      ),
    );
  }
}
