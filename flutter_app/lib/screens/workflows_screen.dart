import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/workflow.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/workflow_suggestion_widget.dart';

class WorkflowsScreen extends StatefulWidget {
  const WorkflowsScreen({Key? key}) : super(key: key);

  @override
  _WorkflowsScreenState createState() => _WorkflowsScreenState();
}

class _WorkflowsScreenState extends State<WorkflowsScreen> {
  final ApiService _apiService = ApiService();
  List<Workflow> _workflows = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, bool> _executingWorkflows = {};
  Map<String, List<Map<String, String>>> _executionResults = {};
  Map<String, bool> _autoExecuteWorkflows = {};
  bool _isConnected = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadWorkflows();
    _loadAutoExecuteSettings();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final isConnected = await _apiService.checkServerConnection();
    setState(() {
      _isConnected = isConnected;
    });
  }

  Future<void> _loadWorkflows() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update connection status first
      await _checkConnection();

      // Let the provider handle loading
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      // Force reload (this will load from local storage if server is not available)
      await chatProvider.loadWorkflows();
    } catch (e) {
      print('Error loading workflows: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAutoExecuteSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoExecuteList =
          prefs.getStringList('auto_execute_workflows') ?? [];

      setState(() {
        _autoExecuteWorkflows = {for (var id in autoExecuteList) id: true};
      });

      // Auto-execute workflows if configured
      if (autoExecuteList.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _autoExecuteConfiguredWorkflows(autoExecuteList);
        });
      }
    } catch (e) {
      print('Error loading auto-execute settings: $e');
    }
  }

  Future<void> _autoExecuteConfiguredWorkflows(List<String> workflowIds) async {
    for (final id in workflowIds) {
      final workflow = _workflows.firstWhere(
        (w) => w.id == id,
        orElse: () => Workflow.empty(),
      );

      if (workflow.id.isNotEmpty) {
        // Ask user if they want to execute auto-workflows
        final shouldExecute = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Tự động thực thi quy trình'),
            content: Text(
                'Bạn có muốn thực thi quy trình "${workflow.title}" đã được cấu hình tự động không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Không'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: Text('Thực thi'),
              ),
            ],
          ),
        );

        if (shouldExecute == true) {
          await _executeWorkflow(workflow);
        }
      }
    }
  }

  Future<void> _toggleAutoExecute(String workflowId, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoExecuteList =
          prefs.getStringList('auto_execute_workflows') ?? [];

      if (value && !autoExecuteList.contains(workflowId)) {
        autoExecuteList.add(workflowId);
      } else if (!value && autoExecuteList.contains(workflowId)) {
        autoExecuteList.remove(workflowId);
      }

      await prefs.setStringList('auto_execute_workflows', autoExecuteList);

      setState(() {
        _autoExecuteWorkflows[workflowId] = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value
              ? 'Quy trình sẽ được thực thi tự động'
              : 'Đã tắt tự động thực thi'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error toggling auto-execute: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi cấu hình tự động thực thi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final savedWorkflows = chatProvider.savedWorkflows;

    // Check server connection state to determine if we're working offline
    bool isOffline = !_isConnected;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quy trình hướng dẫn'),
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: _isLoading ? null : () => _loadWorkflows(),
          ),
        ],
      ),
      // Replace the banner with a more subtle status indicator in the app bar
      body: Column(
        children: [
          // Show a small status indicator instead of a full banner
          if (isOffline)
            Container(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: Colors.amber.withOpacity(0.2),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.amber[800]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đang hiển thị quy trình cục bộ do không thể kết nối với máy chủ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _buildWorkflowList(savedWorkflows),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateWorkflowDialog,
        tooltip: 'Tạo quy trình mới',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildWorkflowList(List<Workflow> workflows) {
    if (_isLoading && workflows.isEmpty) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (workflows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có quy trình nào được lưu',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showCreateWorkflowDialog,
              child: Text('Tạo quy trình mới'),
            ),
          ],
        ),
      );
    }

    // Group workflows by custom vs built-in
    final customWorkflows = workflows.where((w) => w.isCustom).toList();
    final builtInWorkflows = workflows.where((w) => !w.isCustom).toList();

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Custom workflows section
        if (customWorkflows.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Quy trình tùy chỉnh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...customWorkflows.map((workflow) => _buildWorkflowCard(workflow)),
          SizedBox(height: 16),
        ],

        // Built-in workflows section
        if (builtInWorkflows.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Quy trình có sẵn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...builtInWorkflows.map((workflow) => _buildWorkflowCard(workflow)),
        ],
      ],
    );
  }

  void _showCreateWorkflowDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final stepController = TextEditingController();
    List<String> steps = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Tạo quy trình mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên quy trình',
                    hintText: 'Nhập tên quy trình',
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả (tùy chọn)',
                    hintText: 'Nhập mô tả ngắn gọn',
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                Text('Các bước:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ...steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text('${index + 1}. '),
                        Expanded(child: Text(step)),
                        IconButton(
                          icon: Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              steps.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: stepController,
                        decoration: InputDecoration(
                          labelText: 'Thêm bước mới',
                          hintText: 'Nhập bước',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: Colors.green),
                      onPressed: () {
                        if (stepController.text.isNotEmpty) {
                          setState(() {
                            steps.add(stepController.text);
                            stepController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Tạo'),
              onPressed: () {
                if (nameController.text.isNotEmpty && steps.isNotEmpty) {
                  final newWorkflow = Workflow(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    title: nameController.text,
                    description: descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
                    steps: steps,
                    isCustom: true,
                  );

                  Navigator.of(context).pop();
                  _saveWorkflow(newWorkflow);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowCard(Workflow workflow) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color:
              workflow.isCustom ? Colors.blue.shade200 : Colors.green.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    workflow.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (workflow.isCustom)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteWorkflow(workflow.id),
                    tooltip: 'Xóa quy trình',
                  ),
              ],
            ),
            if (workflow.description != null)
              Padding(
                padding: EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  workflow.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            Divider(),
            Text(
              'Các bước (${workflow.steps.length}):',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            ...workflow.steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(step),
                    ),
                  ],
                ),
              );
            }).toList(),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.play_arrow),
                  label: Text('Thực thi'),
                  onPressed: () => _executeWorkflow(workflow),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveWorkflow(Workflow workflow) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    setState(() {
      _isSaving = true;
    });

    try {
      await chatProvider.saveWorkflow(workflow);

      // Show a subtle success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu quy trình'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Show error with a more subtle message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lưu quy trình: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _deleteWorkflow(String workflowId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa quy trình này?'),
        actions: [
          TextButton(
            child: Text('Hủy'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(context).pop();

              final chatProvider =
                  Provider.of<ChatProvider>(context, listen: false);
              await chatProvider.deleteWorkflow(workflowId);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa quy trình'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _executeWorkflow(Workflow workflow) async {
    // Navigate to the workflow execution screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkflowExecutionScreen(workflow: workflow),
      ),
    );
  }
}

class WorkflowExecutionScreen extends StatefulWidget {
  final Workflow workflow;

  const WorkflowExecutionScreen({Key? key, required this.workflow})
      : super(key: key);

  @override
  _WorkflowExecutionScreenState createState() =>
      _WorkflowExecutionScreenState();
}

class _WorkflowExecutionScreenState extends State<WorkflowExecutionScreen> {
  final ApiService _apiService = ApiService();
  bool _isExecuting = false;
  int _currentStep = 0;
  Map<int, String> _results = {};
  Map<int, bool> _executedSteps = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thực thi quy trình'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.workflow.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (widget.workflow.description != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                widget.workflow.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          Divider(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: widget.workflow.steps.length,
              itemBuilder: (context, index) {
                final step = widget.workflow.steps[index];
                final isExecuted = _executedSteps[index] == true;
                final result = _results[index];

                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: isExecuted
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : index == _currentStep && _isExecuting
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.circle_outlined, color: Colors.grey),
                    title: Text(
                      '${index + 1}. $step',
                      style: TextStyle(
                        fontWeight: index == _currentStep
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: result != null ? Text(result) : null,
                    trailing: !isExecuted && !_isExecuting
                        ? IconButton(
                            icon: Icon(Icons.play_arrow, color: Colors.green),
                            onPressed: () => _executeStep(index),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: Icon(_isExecuting ? Icons.stop : Icons.play_arrow),
                label: Text(_isExecuting ? 'Dừng lại' : 'Thực thi tất cả'),
                onPressed: _isExecuting ? _stopExecution : _executeAllSteps,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isExecuting ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executeStep(int index) async {
    setState(() {
      _isExecuting = true;
      _currentStep = index;
    });

    try {
      final step = widget.workflow.steps[index];
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final result = await _apiService.executeWorkflowStep(step, token);

      setState(() {
        _results[index] = result;
        _executedSteps[index] = true;
      });
    } catch (e) {
      setState(() {
        _results[index] = 'Lỗi: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  Future<void> _executeAllSteps() async {
    setState(() {
      _isExecuting = true;
      _currentStep = 0;
    });

    for (int i = 0; i < widget.workflow.steps.length; i++) {
      // Check if we should stop execution
      if (!_isExecuting) break;

      setState(() {
        _currentStep = i;
      });

      await _executeStep(i);

      // Check if the step failed
      if (_results[i]?.contains('Lỗi') == true) {
        break;
      }
    }

    setState(() {
      _isExecuting = false;
    });
  }

  void _stopExecution() {
    setState(() {
      _isExecuting = false;
    });
  }
}
