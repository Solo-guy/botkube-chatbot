import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' show min;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../api_service.dart';
import '../models/event.dart';
import '../models/chat_message.dart';
import '../models/history.dart';
import '../models/workflow.dart';
import '../utils/config.dart';
import 'dart:async';

/// ChatProvider tập trung quản lý tất cả trạng thái và logic liên quan đến chat
class ChatProvider with ChangeNotifier {
  // Lưu trữ tin nhắn chat
  List<String> _messages = []; // Legacy string messages
  List<ChatMessage> _chatMessages = []; // Modern chat messages
  List<double> _costHistory = [];
  List<String> _workflow = []; // Current active workflow steps
  List<String> _currentWorkflow = []; // Current workflow steps
  List<Workflow> _savedWorkflows = []; // List of saved custom workflows

  // Constant key for SharedPreferences
  static const String SAVED_WORKFLOWS_KEY = 'saved_workflows';

  // Trạng thái
  bool _isLoading = false;
  String? _token;
  WebSocketChannel? _channel;
  String _selectedModel = 'grok'; // Mặc định sử dụng Grok
  bool _historyWasCleared = false; // Track if history was cleared

  // Danh sách các model AI có sẵn
  final List<String> _availableModels = ['grok', 'openai', 'gemini', 'claude'];

  // API Service
  final ApiService _apiService = ApiService();

  // Getters
  List<String> get messages => _messages;
  List<ChatMessage> get chatMessages => _chatMessages;
  List<double> get costHistory => _costHistory;
  List<String> get workflow => _workflow;
  List<String> get currentWorkflow => _currentWorkflow;
  List<Workflow> get savedWorkflows => _savedWorkflows;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String get selectedModel => _selectedModel;
  List<String> get availableModels => _availableModels;

  // Setter cho model được chọn
  set selectedModel(String model) {
    if (_availableModels.contains(model)) {
      _selectedModel = model;
      notifyListeners();
    }
  }

  ChatProvider() {
    _initializeWebSocket();
    _loadToken();
    _loadSavedWorkflows(); // Load saved workflows during initialization
  }

  void _initializeWebSocket() {
    final url = AppConfig.wsUrl;
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _channel!.stream.listen((data) {
      final jsonData =
          utf8.decode(data is List<int> ? data : utf8.encode(data));
      final event = Event.fromJson(jsonDecode(jsonData));
      addMessage('Sự kiện: ${event.type} ${event.resource} ${event.name}');
    }, onError: (error) {
      addMessage('Lỗi WebSocket: $error');
    });
  }

  // Load saved workflows from SharedPreferences
  Future<void> _loadSavedWorkflows() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedWorkflowsJson = prefs.getStringList(SAVED_WORKFLOWS_KEY) ?? [];

      print("Loading saved workflows from SharedPreferences");
      print("Found ${savedWorkflowsJson.length} saved workflow JSON entries");

      if (savedWorkflowsJson.isEmpty) {
        print("No saved workflows found in SharedPreferences");
      } else {
        // Debug: Print a sample of the first workflow JSON
        if (savedWorkflowsJson.isNotEmpty) {
          final sampleJson = savedWorkflowsJson[0];
          print(
              "Sample workflow JSON: ${sampleJson.substring(0, min(100, sampleJson.length))}...");
        }
      }

      // Clear existing custom workflows (keep built-ins)
      _savedWorkflows.removeWhere((workflow) => workflow.isCustom);

      // Parse the JSON data
      List<Workflow> loadedWorkflows = [];
      for (int i = 0; i < savedWorkflowsJson.length; i++) {
        try {
          final jsonString = savedWorkflowsJson[i];
          final jsonMap = jsonDecode(jsonString);
          final workflow = Workflow.fromJson(jsonMap);
          print(
              "Loaded workflow: ${workflow.title} (ID: ${workflow.id}, Steps: ${workflow.steps.length})");
          loadedWorkflows.add(workflow);
        } catch (e) {
          print("Error parsing workflow at index $i: $e");
        }
      }

      // Add the parsed workflows to the list
      _savedWorkflows.addAll(loadedWorkflows);

      // Add built-in workflows if they're not already in the list
      _addBuiltInWorkflowsIfNeeded();

      print("Total workflows after loading: ${_savedWorkflows.length}");
      print(
          "Custom workflows: ${_savedWorkflows.where((w) => w.isCustom).length}");
      print(
          "Built-in workflows: ${_savedWorkflows.where((w) => !w.isCustom).length}");

      notifyListeners();
    } catch (e) {
      print('Error loading saved workflows: $e');
      // Ensure built-in workflows are available even if loading fails
      _addBuiltInWorkflowsIfNeeded();
      notifyListeners();
    }
  }

  // Add built-in workflows to saved workflows list if they're not already there
  void _addBuiltInWorkflowsIfNeeded() {
    final builtInWorkflows = [
      Workflow.kubernetesDebugging(),
      Workflow.healthChecks(),
    ];

    for (var workflow in builtInWorkflows) {
      if (!_savedWorkflows.any((w) => w.id == workflow.id)) {
        _savedWorkflows.add(workflow);
      }
    }
  }

  // Save workflows to SharedPreferences
  Future<void> _saveWorkflowsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Filter out built-in workflows before saving
      final customWorkflows =
          _savedWorkflows.where((workflow) => workflow.isCustom).toList();

      print(
          "Saving ${customWorkflows.length} custom workflows to SharedPreferences");

      final workflowsJson = customWorkflows
          .map((workflow) => jsonEncode(workflow.toJson()))
          .toList();

      print("JSON entries to save: ${workflowsJson.length}");

      // Debug: Print the first workflow JSON if available
      if (workflowsJson.isNotEmpty) {
        print(
            "First workflow JSON sample: ${workflowsJson[0].substring(0, min(100, workflowsJson[0].length))}...");
      }

      await prefs.setStringList(SAVED_WORKFLOWS_KEY, workflowsJson);

      // Verify data was saved
      final savedList = prefs.getStringList(SAVED_WORKFLOWS_KEY) ?? [];
      print(
          "Verification: ${savedList.length} workflows saved to SharedPreferences");
    } catch (e) {
      print('Error saving workflows to SharedPreferences: $e');
    }
  }

  // Add a new workflow to saved workflows
  Future<void> saveWorkflow(Workflow workflow) async {
    print(
        "Adding workflow to saved workflows: ${workflow.title} (ID: ${workflow.id})");
    print("Current saved workflows count: ${_savedWorkflows.length}");

    // If this is a custom workflow with the same ID as an existing one, replace it
    final existingIndex =
        _savedWorkflows.indexWhere((w) => w.id == workflow.id);

    if (existingIndex >= 0) {
      print("Replacing existing workflow at index $existingIndex");
      _savedWorkflows[existingIndex] = workflow;
    } else {
      print("Adding new workflow");
      _savedWorkflows.add(workflow);
    }

    print("Saved workflows count after adding: ${_savedWorkflows.length}");
    await _saveWorkflowsToPrefs();

    // Verify the workflow was actually saved
    print("Verifying workflow was saved correctly...");
    final savedIndex = _savedWorkflows.indexWhere((w) => w.id == workflow.id);
    if (savedIndex >= 0) {
      print("Workflow found at index $savedIndex");
    } else {
      print("ERROR: Workflow not found after saving!");
    }

    notifyListeners();
  }

  // Delete a workflow by ID
  Future<void> deleteWorkflow(String workflowId) async {
    print("Attempting to delete workflow with ID: $workflowId");
    print("Current saved workflows count: ${_savedWorkflows.length}");

    try {
      // Log all workflow IDs to help with debugging
      print("All workflow IDs: ${_savedWorkflows.map((w) => w.id).join(', ')}");

      // Only allow deleting custom workflows
      final workflow = _savedWorkflows.firstWhere(
        (w) => w.id == workflowId,
        orElse: () {
          print("ERROR: Workflow with ID $workflowId not found!");
          return Workflow(id: '', title: '', steps: []);
        },
      );

      if (workflow.id.isEmpty) {
        print("Cannot delete: Workflow ID not found");
        return; // Early return if workflow not found
      }

      if (workflow.isCustom) {
        print("Deleting custom workflow: ${workflow.title}");
        final countBefore = _savedWorkflows.length;
        _savedWorkflows.removeWhere((w) => w.id == workflowId);
        final countAfter = _savedWorkflows.length;

        // Verify workflow was removed
        if (countBefore == countAfter) {
          print("ERROR: Workflow was not removed from list! Count unchanged.");
        } else {
          print(
              "Workflow successfully removed. Count before: $countBefore, after: $countAfter");
        }

        await _saveWorkflowsToPrefs();
        notifyListeners();
      } else {
        print("Cannot delete built-in workflow: $workflowId");
      }

      // Verify
      if (_savedWorkflows.any((w) => w.id == workflowId && workflow.isCustom)) {
        print("ERROR: Workflow still exists after deletion!");
      } else {
        print("Deletion verification successful");
      }
    } catch (e) {
      print("Error during workflow deletion: $e");
    }
  }

  // Update an existing workflow
  Future<void> updateWorkflow(Workflow updatedWorkflow) async {
    final index = _savedWorkflows.indexWhere((w) => w.id == updatedWorkflow.id);

    if (index >= 0) {
      _savedWorkflows[index] = updatedWorkflow;
      await _saveWorkflowsToPrefs();
      notifyListeners();
    }
  }

  // Save current suggested workflow with a title and description
  Future<void> saveCurrentWorkflow({String? title, String? description}) async {
    if (_workflow.isNotEmpty) {
      print("Saving workflow with ${_workflow.length} steps");
      final newWorkflow = Workflow.fromSuggested(
        _workflow,
        customTitle: title,
        customDescription: description,
      );

      print("Created new workflow with ID: ${newWorkflow.id}");
      await saveWorkflow(newWorkflow);

      // Force reload saved workflows to verify they're saved
      await _loadSavedWorkflows();
    } else {
      print("Cannot save workflow: No steps available");
    }
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token') ?? '';
    print(
        'Token đã được tải: ${_token!.isNotEmpty ? 'Có token' : 'Không có token'}');
    notifyListeners();
  }

  Future<void> reloadToken() async {
    await _loadToken();
    print('Token đã được làm mới');
  }

  Future<void> login(String username) async {
    _token = await _apiService.login(username);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', _token ?? '');
    notifyListeners();
  }

  // Lưu tin nhắn và phản hồi
  Future<void> sendChatMessage(String message, String response) async {
    if (_token == null || _token!.isEmpty) {
      addMessage('Lỗi: Chưa đăng nhập. Vui lòng đăng nhập trước.');
      return;
    }

    try {
      // Gửi tin nhắn đến API
      await _apiService.sendChatMessage(message, response);

      // Tải lại lịch sử sau khi gửi tin nhắn
      await loadHistory();
    } catch (e) {
      print('Lỗi khi gửi tin nhắn: $e');
    }
  }

  // Phân tích sự kiện
  Future<void> analyzeEvent(Event event) async {
    if (_token == null || _token!.isEmpty) {
      addMessage('Lỗi: Chưa đăng nhập. Vui lòng đăng nhập trước.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Hiển thị thông báo đang phân tích với model nào
      addMessage(
          "Đang phân tích sự kiện với ${_selectedModel.toUpperCase()}...");

      final response = await _apiService.analyzeEvent(event, _token!,
          model: _selectedModel // Sử dụng model đã chọn
          );

      // Thay thông báo "đang phân tích" bằng kết quả thực tế
      _messages.removeLast();

      // Kiểm tra nếu có lỗi trong phản hồi
      if (response.containsKey('error') && response['error'] != null) {
        // Hiển thị thông báo lỗi nhưng vẫn sử dụng phân tích nếu có
        addMessage(
            "${_selectedModel.toUpperCase()} (Lỗi): ${response['analysis']}");
        addMessage("Chi tiết lỗi: ${response['error']}");
      } else {
        // Phản hồi bình thường không có lỗi
        addMessage("${_selectedModel.toUpperCase()}: ${response['analysis']}");
      }

      // Đặt workflow mới và thông báo sự thay đổi
      if (response.containsKey('workflow') && response['workflow'] != null) {
        setWorkflow(List<String>.from(response['workflow']));
      } else {
        // Nếu không có workflow, đặt một workflow mặc định
        setWorkflow([
          "Kiểm tra log và trạng thái của pod.",
          "Xem xét tài nguyên được cấp phát cho pod.",
          "Giám sát pod để phát hiện sự cố."
        ]);
      }

      _costHistory.add(0.01);
    } catch (e) {
      // Nếu đã có thông báo "đang phân tích", xóa nó
      if (_messages.isNotEmpty &&
          _messages.last.contains("Đang phân tích sự kiện với")) {
        _messages.removeLast();
      }

      // Biên tập lỗi để hiển thị thân thiện hơn
      String errorMessage = e.toString();
      if (errorMessage.contains("Exception:")) {
        errorMessage = errorMessage.replaceAll("Exception:", "");
      }

      addMessage('${_selectedModel.toUpperCase()} - Lỗi: $errorMessage');

      // Thử đề xuất một số bước khắc phục
      setWorkflow([
        "Thử lại sau vài phút.",
        "Chọn model AI khác (OpenAI, Gemini, Claude, Grok).",
        "Kiểm tra kết nối mạng và cấu hình server."
      ]);

      print('Lỗi chi tiết khi phân tích sự kiện: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tải và hiển thị lịch sử chat
  Future<void> loadHistory() async {
    if (_token == null || _token!.isEmpty) {
      addMessage('Lỗi: Chưa đăng nhập. Vui lòng đăng nhập trước.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Clear existing messages to prevent duplicates when reloading
      _messages.clear();

      // Add a timestamp to the request to avoid browser caching
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final history =
          await _apiService.getHistory(_token!, timestamp: currentTimestamp);
      print('Đã tải lịch sử thành công: ${history.length} mục');

      // Check if we already have messages to avoid duplicates
      if (_messages.isEmpty) {
        // Add each history entry to the message list
        for (var entry in history) {
          _messages.add('User: ${entry.message}');
          if (entry.response.isNotEmpty) {
            _messages.add('AI: ${entry.response}');
          }
        }
      }
    } catch (e) {
      addMessage('Lỗi khi lấy lịch sử chat: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Xóa lịch sử
  Future<bool> deleteHistoryEntry(String messageId) async {
    if (_token == null || _token!.isEmpty) {
      addMessage('Lỗi: Chưa đăng nhập. Vui lòng đăng nhập trước.');
      return false;
    }

    try {
      final result = await _apiService.deleteHistoryEntry(messageId, _token!);
      if (result['success'] == true) {
        // Nếu xóa thành công, tải lại lịch sử
        await loadHistory();
        return true;
      }
      return false;
    } catch (e) {
      addMessage('Lỗi khi xóa lịch sử: $e');
      return false;
    }
  }

  // Xóa tất cả lịch sử chat (server và local)
  Future<bool> clearAllHistory() async {
    if (_token == null || _token!.isEmpty) {
      addMessage('Lỗi: Chưa đăng nhập. Vui lòng đăng nhập trước.');
      return false;
    }

    try {
      // Xóa lịch sử trên server
      final result = await _apiService.deleteAllHistory(_token!);

      if (result['success'] == true) {
        // Xóa tin nhắn hiện tại trong bộ nhớ
        clearMessages();

        // Xóa tin nhắn chat hiện đại
        _chatMessages.clear();

        // Đặt cờ hiệu để thông báo việc xóa lịch sử
        _historyWasCleared = true;

        // Xóa lịch sử chat trong SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('local_chat_history');

        // Thông báo cho tất cả người nghe biết thay đổi
        notifyListeners();

        print('Đã xóa tất cả lịch sử chat (server và local)');
        return true;
      }
      return false;
    } catch (e) {
      print('Lỗi khi xóa tất cả lịch sử: $e');
      return false;
    }
  }

  // Kiểm tra xem lịch sử có bị xóa gần đây không
  bool checkAndResetHistoryCleared() {
    if (_historyWasCleared) {
      _historyWasCleared = false;
      return true;
    }
    return false;
  }

  void addMessage(String message) {
    _messages.add(message);
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  void clearWorkflow() {
    _currentWorkflow = [];
    _workflow = [];
    notifyListeners();
  }

  // Update setWorkflow to handle both List<String> and Workflow objects
  void setWorkflow(dynamic workflowInput) {
    if (workflowInput is List<String>) {
      _workflow = List<String>.from(workflowInput);
      _currentWorkflow = List<String>.from(workflowInput);
    } else if (workflowInput is Workflow) {
      _workflow = List<String>.from(workflowInput.steps);
      _currentWorkflow = List<String>.from(workflowInput.steps);
    }
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setToken(String value) {
    _token = value;
    notifyListeners();
  }

  double getTotalCost() {
    return _costHistory.fold(0, (sum, cost) => sum + cost);
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  // Handle offline and 404 errors with appropriate fallback responses
  Map<String, dynamic> _createFallbackResponse(
      String message, bool isKubernetes) {
    // Check for supernatural/spiritual keywords for specific fallback content
    bool isSpiritualQuery = message.toLowerCase().contains('ma') ||
        message.toLowerCase().contains('quỷ') ||
        message.toLowerCase().contains('tâm linh');

    String fallbackContent = "";
    List<String> fallbackWorkflow = [];

    if (isKubernetes) {
      fallbackContent = _getKubernetesFallbackResponse(message);
      fallbackWorkflow = [
        "Kiểm tra kết nối mạng với máy chủ.",
        "Đảm bảo server đang chạy và có thể truy cập được.",
        "Thử lại sau khi đã kết nối với mạng."
      ];
    } else if (isSpiritualQuery) {
      fallbackContent =
          "Về chủ đề liên quan đến ma quỷ hoặc tâm linh, có nhiều quan điểm văn hóa và tín ngưỡng khác nhau. Một số người tin vào sự tồn tại của thế giới tâm linh, trong khi những người khác coi đó là hiện tượng tâm lý hoặc văn hóa. Nếu bạn quan tâm đến chủ đề này, tôi khuyên bạn nên tìm hiểu từ nhiều nguồn đáng tin cậy và tham khảo ý kiến từ các chuyên gia về tâm lý hoặc văn hóa.";
      fallbackWorkflow = [
        "Tìm hiểu các tài liệu về tâm linh hoặc triết học.",
        "Tham khảo ý kiến từ chuyên gia về tâm lý hoặc tâm linh.",
        "Khám phá các phương pháp thiền định để cải thiện sức khỏe tinh thần."
      ];
    } else {
      fallbackContent = _getGeneralFallbackResponse(message);
      fallbackWorkflow = _generateContextualWorkflow(message, fallbackContent);
    }

    return {
      'success': true,
      'is_fallback': true,
      'response': fallbackContent,
      'workflow': fallbackWorkflow,
      'error': null
    };
  }

  /// Process user message with fallback handling and adaptive timeout
  Future<void> processUserMessage(String message) async {
    if (_token == null || _token!.isEmpty) {
      addMessage('Lỗi: Chưa đăng nhập. Vui lòng đăng nhập trước.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    // Clear any existing workflow to prevent it from being displayed too early
    clearWorkflow();

    // Immediately display the user message
    addMessage('User: $message');

    try {
      // First determine if this is a Kubernetes-related query
      final isKubernetes = _isKubernetesRelated(message);

      // Enhanced ghost/spiritual query detection
      bool isSpiritualQuery = false;
      final lowerMessage = message.toLowerCase();

      // Check for ghost-related terms
      const List<String> ghostRelatedWords = [
        'ma',
        'quỷ',
        'tâm linh',
        'linh hồn',
        'hồn',
        'ám',
        'kinh dị',
        'rùng rợn',
        'kể chuyện ma',
        'chuyện ma',
        'bóng đêm',
        'mộ',
        'nghĩa địa',
        'ma quỷ',
        'siêu nhiên'
      ];

      // Count matches and check for exact phrases
      int ghostTermCount = 0;
      for (final term in ghostRelatedWords) {
        if (lowerMessage.contains(term)) {
          ghostTermCount++;
          // Strong indicators get priority
          if (term == 'chuyện ma' ||
              term == 'kể chuyện ma' ||
              term == 'ma quỷ' ||
              term == 'linh hồn') {
            isSpiritualQuery = true;
            break;
          }
        }
      }

      // Multiple matches also indicate spiritual content
      if (ghostTermCount >= 2) {
        isSpiritualQuery = true;
      }

      print('Processing message: "$message"');
      print('Is Kubernetes query: $isKubernetes');
      print('Is spiritual query: $isSpiritualQuery');
      print('Ghost term count: $ghostTermCount');

      Map<String, dynamic> result;

      if (isKubernetes) {
        // Handle as Kubernetes command
        addMessage('Đang xử lý lệnh Kubernetes...');
        result = await _apiService.processKubernetesEvent(message, _token!,
            model: _selectedModel, saveToHistory: true);

        // Log the response structure for debugging
        print('Kubernetes response structure: ${result.keys.join(', ')}');

        // Remove the processing message
        if (_messages.isNotEmpty &&
            _messages.last == 'Đang xử lý lệnh Kubernetes...') {
          _messages.removeLast();
          notifyListeners();
        }
      } else {
        // Handle as natural language query
        addMessage('Đang xử lý câu hỏi...');

        // For supernatural queries where the backend might fail, include direct handling
        if (isSpiritualQuery) {
          print('Using enhanced handling for supernatural query');
          // Still try API but be prepared for failure
          result = await _apiService.processNaturalLanguage(message, _token!,
              model: _selectedModel, saveToHistory: true);

          // If API returns 404 or other error, the _apiService should already generate
          // an appropriate response for supernatural content
        } else {
          // Normal query processing
          result = await _apiService.processNaturalLanguage(message, _token!,
              model: _selectedModel, saveToHistory: true);
        }

        // Log the response structure for debugging
        print('Natural language response structure: ${result.keys.join(', ')}');

        // Remove the processing message
        if (_messages.isNotEmpty && _messages.last == 'Đang xử lý câu hỏi...') {
          _messages.removeLast();
          notifyListeners();
        }
      }

      // Unified response handling regardless of query type
      if (result['success'] == true) {
        // First ensure we have a valid response text
        String responseText = '';

        // Try multiple fields that may contain the response text
        if (result.containsKey('response') && result['response'] != null) {
          responseText = result['response'].toString();
        } else if (result.containsKey('analysis') &&
            result['analysis'] != null) {
          responseText = result['analysis'].toString();
        } else {
          responseText = 'Không có phản hồi từ máy chủ';
        }

        // Get the workflow steps if they exist
        List<String> workflowSteps = [];
        if (result.containsKey('workflow') &&
            result['workflow'] != null &&
            result['workflow'] is List) {
          workflowSteps = List<String>.from(result['workflow']);
        }

        // Add the AI response message
        addMessage('${_selectedModel.toUpperCase()}: $responseText');

        // For special handling of supernatural/spiritual queries (Vietnamese "ma")
        if (isSpiritualQuery) {
          print('Applying spiritual query workflow');
          workflowSteps = [
            "Tìm hiểu các tài liệu về tâm linh hoặc triết học.",
            "Tham khảo ý kiến từ chuyên gia về tâm lý hoặc tâm linh.",
            "Khám phá các phương pháp thiền định để cải thiện sức khỏe tinh thần."
          ];
        }
        // If we didn't get a useful workflow, generate a contextual one
        else if (workflowSteps.isEmpty ||
            _isDefaultKubernetesWorkflow(workflowSteps)) {
          print('Generating contextual workflow');
          workflowSteps = _generateContextualWorkflow(message, responseText);
        }

        // Directly set the workflow - no delays
        if (workflowSteps.isNotEmpty) {
          print('Setting workflow with ${workflowSteps.length} steps');
          setWorkflow(workflowSteps);
        }
      } else {
        // Handle error with detailed message
        String errorMsg = '';

        // Try to get error message with fallbacks
        if (result.containsKey('error') && result['error'] != null) {
          errorMsg = result['error'].toString();
        } else if (result.containsKey('response') &&
            result['response'] != null) {
          errorMsg = result['response'].toString();
        } else {
          errorMsg = 'Lỗi không xác định';
        }

        // For supernatural queries, ensure appropriate fallback
        if (isSpiritualQuery &&
            (errorMsg.contains('404') ||
                errorMsg.contains('Endpoint not found'))) {
          // Provide specialized ghost story response even on errors
          final ghostResponse =
              "Về chủ đề liên quan đến ma quỷ hoặc tâm linh, có nhiều quan điểm văn hóa và tín ngưỡng khác nhau. Một số người tin vào sự tồn tại của thế giới tâm linh, trong khi những người khác coi đó là hiện tượng tâm lý hoặc văn hóa. Nếu bạn quan tâm đến chủ đề này, tôi khuyên bạn nên tìm hiểu từ nhiều nguồn đáng tin cậy và tham khảo ý kiến từ các chuyên gia về tâm lý hoặc văn hóa.";

          addMessage('${_selectedModel.toUpperCase()}: $ghostResponse');

          setWorkflow([
            "Tìm hiểu các tài liệu về tâm linh hoặc triết học.",
            "Tham khảo ý kiến từ chuyên gia về tâm lý hoặc tâm linh.",
            "Khám phá các phương pháp thiền định để cải thiện sức khỏe tinh thần."
          ]);
        }
        // Check for 404 errors specifically and handle with fallback content
        else if (errorMsg.contains('404')) {
          // Create a tailored fallback response
          var fallbackResult = _createFallbackResponse(message, isKubernetes);

          // Show fallback message with AI model name
          addMessage(
              '${_selectedModel.toUpperCase()}: ${fallbackResult['response']}');

          // Set workflow from fallback
          if (fallbackResult['workflow'] != null &&
              fallbackResult['workflow'] is List) {
            setWorkflow(fallbackResult['workflow'] as List<dynamic>);
          }
        } else {
          addMessage('Lỗi: $errorMsg');

          // Generate a fallback workflow even for errors
          final contextualWorkflow =
              _generateContextualWorkflow(message, errorMsg);
          setWorkflow(contextualWorkflow);
        }
      }
    } catch (e) {
      print('Error processing message: $e');
      String errorMsg = e.toString();

      // Provide a more user-friendly error message
      if (errorMsg.contains('SocketException') ||
          errorMsg.contains('Connection refused')) {
        addMessage(
            'Lỗi kết nối: Không thể kết nối với máy chủ. Vui lòng kiểm tra kết nối mạng của bạn.');
      } else if (errorMsg.contains('TimeoutException')) {
        addMessage(
            'Lỗi thời gian chờ: Máy chủ mất quá nhiều thời gian để phản hồi. Vui lòng thử lại sau.');
      } else {
        addMessage('Lỗi khi xử lý yêu cầu: $e');
      }

      // If there's an error, try to generate a contextual workflow anyway
      final contextualWorkflow = _generateContextualWorkflow(message, "");
      setWorkflow(contextualWorkflow);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Provides fallback responses for Kubernetes queries when offline
  String _getKubernetesFallbackResponse(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('pod') || lowerMessage.contains('pods')) {
      return 'Pods là đơn vị cơ bản nhất trong Kubernetes. Pod có thể chứa một hoặc nhiều container và cung cấp môi trường chạy ứng dụng. Để kiểm tra pods, bạn có thể dùng lệnh: kubectl get pods';
    } else if (lowerMessage.contains('deployment') ||
        lowerMessage.contains('deploy')) {
      return 'Deployments quản lý việc triển khai các ứng dụng trong Kubernetes, bao gồm số lượng replicas và cập nhật. Để kiểm tra deployments, dùng lệnh: kubectl get deployments';
    } else if (lowerMessage.contains('service') ||
        lowerMessage.contains('svc')) {
      return 'Services trong Kubernetes cung cấp một điểm truy cập ổn định cho các ứng dụng chạy trong các pods. Để kiểm tra services, dùng lệnh: kubectl get services';
    } else if (lowerMessage.contains('namespace') ||
        lowerMessage.contains('ns')) {
      return 'Namespaces là cách để phân chia tài nguyên trong một cluster Kubernetes thành nhiều nhóm logic. Để kiểm tra namespaces, dùng lệnh: kubectl get namespaces';
    } else {
      return 'Kubernetes là một nền tảng điều phối container mã nguồn mở. Nó tự động hóa việc triển khai, mở rộng và quản lý các ứng dụng container. Bạn có thể sử dụng lệnh kubectl để tương tác với Kubernetes cluster.';
    }
  }

  // Provides general fallback responses for non-Kubernetes queries when offline
  String _getGeneralFallbackResponse(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('xin chào') ||
        lowerMessage.contains('chào') ||
        lowerMessage.contains('hello') ||
        lowerMessage.contains('hi')) {
      return 'Xin chào! Tôi là trợ lý ảo của Botkube. Tôi có thể giúp bạn trả lời các câu hỏi về Kubernetes và nhiều chủ đề khác. Hiện tại tôi đang hoạt động ở chế độ ngoại tuyến.';
    } else if (lowerMessage.contains('thời tiết')) {
      return 'Tôi không thể kiểm tra thời tiết hiện tại khi đang ngoại tuyến. Vui lòng kiểm tra dịch vụ thời tiết trên thiết bị của bạn hoặc kết nối lại sau.';
    } else if (lowerMessage.contains('thời gian') ||
        lowerMessage.contains('ngày') ||
        lowerMessage.contains('hôm nay')) {
      final now = DateTime.now();
      return 'Hiện tại là ${now.hour}:${now.minute} ngày ${now.day}/${now.month}/${now.year}.';
    } else {
      return 'Tôi đang hoạt động ở chế độ ngoại tuyến và không thể xử lý yêu cầu này. Vui lòng kiểm tra kết nối mạng và thử lại sau.';
    }
  }

  // Check if a list of workflows is the default Kubernetes workflow
  bool _isDefaultKubernetesWorkflow(List<dynamic> workflow) {
    if (workflow.isEmpty) return false;

    // Check if it contains common Kubernetes workflow steps
    int k8sCount = 0;
    for (var step in workflow) {
      String stepStr = step.toString().toLowerCase();
      if (stepStr.contains('kubectl') ||
          stepStr.contains('kubernetes') ||
          stepStr.contains('cluster') ||
          stepStr.contains('pod') ||
          stepStr.contains('deployment')) {
        k8sCount++;
      }
    }

    // If more than half the steps mention Kubernetes concepts, it's a K8s workflow
    return k8sCount > (workflow.length / 2);
  }

  // Check if a message is Kubernetes-related
  bool _isKubernetesRelated(String message) {
    final lowerMessage = message.toLowerCase();

    // Keywords that indicate Kubernetes-related queries
    const k8sKeywords = [
      'kubectl',
      'kubernetes',
      'k8s',
      'pod',
      'deployment',
      'service',
      'namespace',
      'cluster',
      'node',
      'ingress',
      'configmap',
      'secret',
      'volume',
      'pvc',
      'pv',
      'statefulset',
      'daemonset',
      'cronjob',
      'job',
      'api server',
      'kubeadm',
      'kubelet',
      'kube-proxy'
    ];

    // Check if message contains any Kubernetes keywords
    for (final keyword in k8sKeywords) {
      if (lowerMessage.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  // Helper method to generate contextual workflows based on user query
  List<String> _generateContextualWorkflow(String message, String response) {
    final lowerMessage = message.toLowerCase();
    final lowerResponse = response.toLowerCase();

    // Check if the question is about date/time
    if (lowerMessage.contains('ngày') ||
        lowerMessage.contains('thứ') ||
        lowerMessage.contains('hôm nay') ||
        lowerMessage.contains('thời gian') ||
        lowerResponse.contains('ngày') ||
        lowerResponse.contains('hôm nay là')) {
      return [
        "Kiểm tra lịch trên điện thoại hoặc máy tính.",
        "Đồng bộ hóa lịch với dịch vụ thời gian chính xác.",
        "Cài đặt thông báo cho các sự kiện quan trọng."
      ];
    }

    // Enhanced detection for questions about supernatural topics (ma)
    // 'ma' can be part of many Vietnamese words, so we check for more context clues
    bool isLikelyGhostQuery = false;

    // These are words commonly associated with ghost stories
    const List<String> ghostRelatedWords = [
      'ma',
      'quỷ',
      'tâm linh',
      'linh hồn',
      'hồn',
      'ám',
      'kinh dị',
      'rùng rợn',
      'kể chuyện ma',
      'chuyện ma',
      'bóng đêm',
      'mộ',
      'nghĩa địa',
      'ma quỷ',
      'siêu nhiên'
    ];

    // Count how many ghost-related terms appear in the message
    int ghostTermCount = 0;
    for (final term in ghostRelatedWords) {
      if (lowerMessage.contains(term)) {
        ghostTermCount++;

        // If term is a strong indicator (like "kể chuyện ma"), mark as likely ghost query
        if (term == 'chuyện ma' ||
            term == 'kể chuyện ma' ||
            term == 'ma quỷ' ||
            term == 'linh hồn') {
          isLikelyGhostQuery = true;
          break;
        }
      }
    }

    // If multiple ghost terms are present or we have a strong indicator, it's a ghost query
    if (isLikelyGhostQuery || ghostTermCount >= 2) {
      return [
        "Tìm hiểu các tài liệu về tâm linh hoặc triết học.",
        "Tham khảo ý kiến từ chuyên gia về tâm lý hoặc tâm linh.",
        "Khám phá các phương pháp thiền định để cải thiện sức khỏe tinh thần."
      ];
    }

    // Check if question is about weather
    if (lowerMessage.contains('thời tiết') ||
        lowerMessage.contains('mưa') ||
        lowerMessage.contains('nắng') ||
        lowerMessage.contains('nhiệt độ') ||
        lowerResponse.contains('thời tiết') ||
        lowerResponse.contains('nhiệt độ')) {
      return [
        "Kiểm tra ứng dụng thời tiết để biết dự báo mới nhất.",
        "Chuẩn bị trang phục phù hợp với điều kiện thời tiết.",
        "Lên kế hoạch các hoạt động ngoài trời dựa trên dự báo."
      ];
    }

    // Default general-purpose workflow
    return [
      "Tìm kiếm thêm thông tin về chủ đề này trên internet.",
      "Tham khảo ý kiến của chuyên gia nếu cần thiết.",
      "Ghi chú lại thông tin hữu ích để tham khảo sau."
    ];
  }

  /// Process user message with custom handling for Vietnamese text
  /// This version doesn't add the user message, which is useful when the message
  /// is already displayed in the chat widget
  Future<void> processUserMessageWithoutAdding(String message) async {
    if (_token == null || _token!.isEmpty) {
      addMessage('Lỗi: Chưa đăng nhập. Vui lòng đăng nhập trước.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    // Clear any existing workflow to prevent it from being displayed too early
    clearWorkflow();

    try {
      // Log for debugging Vietnamese characters
      print('Processing message with Vietnamese support: "$message"');
      print(
          'Message codepoints: ${message.runes.map((r) => '0x${r.toRadixString(16)}').join(', ')}');

      // Re-encode as UTF-8 to ensure Vietnamese characters are preserved
      final List<int> utf8Bytes = utf8.encode(message);
      final String utf8Message = utf8.decode(utf8Bytes);

      // First determine if this is a Kubernetes-related query
      final isKubernetes = _isKubernetesRelated(utf8Message);

      // Enhanced ghost/spiritual query detection with UTF-8 support
      bool isSpiritualQuery = _isGhostRelatedQuery(utf8Message);

      print('Processing message without adding: "$utf8Message"');
      print('Is Kubernetes query: $isKubernetes');
      print('Is spiritual query: $isSpiritualQuery');

      // Show processing message
      if (isKubernetes) {
        addMessage('Đang xử lý lệnh Kubernetes...');
      } else {
        addMessage('Đang xử lý câu hỏi...');
      }

      // Create a completer to handle both immediate and delayed responses
      final responseCompleter = Completer<Map<String, dynamic>>();
      bool hasTimedOut = false;

      // Set up timeout handler
      Timer(AppConfig.getAiModelTimeout(_selectedModel), () {
        if (!responseCompleter.isCompleted) {
          hasTimedOut = true;
          print('Request timed out, returning fallback response');

          // Create a fallback response based on the message type
          responseCompleter
              .complete(_createFallbackResponse(message, isKubernetes));
        }
      });

      // Process the request asynchronously
      if (isKubernetes) {
        // Handle as Kubernetes command
        _apiService
            .processKubernetesEvent(utf8Message, _token!,
                model: _selectedModel, saveToHistory: true)
            .then((result) {
          if (!responseCompleter.isCompleted) {
            responseCompleter.complete(result);
          }
          // If we've already timed out, still log that we got a response
          else if (hasTimedOut) {
            print('Received Kubernetes response after timeout');
          }
        }).catchError((error) {
          if (!responseCompleter.isCompleted) {
            print('Error processing Kubernetes query: $error');
            responseCompleter.complete({
              'success': false,
              'error': error.toString(),
              'response': null
            });
          }
        });
      } else {
        // Handle as natural language query
        _apiService
            .processNaturalLanguage(utf8Message, _token!,
                model: _selectedModel, saveToHistory: true)
            .then((result) {
          if (!responseCompleter.isCompleted) {
            responseCompleter.complete(result);
          }
          // If we've already timed out, still log that we got a response
          else if (hasTimedOut) {
            print('Received natural language response after timeout');
          }
        }).catchError((error) {
          if (!responseCompleter.isCompleted) {
            print('Error processing natural language query: $error');
            responseCompleter.complete({
              'success': false,
              'error': error.toString(),
              'response': null
            });
          }
        });
      }

      // Wait for the response (or timeout)
      final result = await responseCompleter.future;

      // Remove the processing message
      if (_messages.isNotEmpty) {
        if (_messages.last == 'Đang xử lý lệnh Kubernetes...' ||
            _messages.last == 'Đang xử lý câu hỏi...') {
          _messages.removeLast();
          notifyListeners();
        }
      }

      // Process the response
      if (result.containsKey('response') && result['response'] != null) {
        // Extract the response text
        String responseText = result['response'].toString();

        // Ensure we don't have an empty response
        if (responseText.trim().isEmpty) {
          responseText =
              "Không có phản hồi từ mô hình ${_selectedModel.toUpperCase()}";
        }

        // Get the workflow steps if they exist
        List<String> workflowSteps = [];
        if (result.containsKey('workflow') &&
            result['workflow'] != null &&
            result['workflow'] is List) {
          workflowSteps = List<String>.from(result['workflow']);
        }

        // Add the AI response message with the model name
        addMessage('${_selectedModel.toUpperCase()}: $responseText');

        // If we didn't get a useful workflow, generate a contextual one
        if (workflowSteps.isEmpty) {
          print('Generating contextual workflow');
          workflowSteps = _generateContextualWorkflow(message, responseText);
        }

        // Set the workflow
        if (workflowSteps.isNotEmpty) {
          print('Setting workflow with ${workflowSteps.length} steps');
          setWorkflow(workflowSteps);
        }
      } else if (result.containsKey('error') && result['error'] != null) {
        // Handle error response
        String errorMsg = result['error'].toString();
        addMessage('Lỗi: $errorMsg');

        // Generate a fallback workflow for the error case
        final contextualWorkflow =
            _generateContextualWorkflow(message, errorMsg);
        setWorkflow(contextualWorkflow);
      } else {
        // Handle case where neither response nor error is present
        addMessage(
            '${_selectedModel.toUpperCase()}: Không có phản hồi từ máy chủ');

        // Generate a fallback workflow
        final contextualWorkflow = _generateContextualWorkflow(message, "");
        setWorkflow(contextualWorkflow);
      }
    } catch (e) {
      print('Error processing message: $e');
      String errorMsg = e.toString();

      // Provide a more user-friendly error message
      if (errorMsg.contains('SocketException') ||
          errorMsg.contains('Connection refused')) {
        addMessage(
            'Lỗi kết nối: Không thể kết nối với máy chủ. Vui lòng kiểm tra kết nối mạng của bạn.');
      } else if (errorMsg.contains('TimeoutException')) {
        addMessage(
            'Lỗi thời gian chờ: Máy chủ mất quá nhiều thời gian để phản hồi. Vui lòng thử lại sau.');
      } else {
        addMessage('Lỗi khi xử lý yêu cầu: $e');
      }

      // If there's an error, try to generate a contextual workflow anyway
      final contextualWorkflow = _generateContextualWorkflow(message, "");
      setWorkflow(contextualWorkflow);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Gửi tin nhắn và nhận phản hồi từ AI
  Future<void> sendMessage(String message) async {
    if (_token == null || _token!.isEmpty) {
      addMessage('Lỗi: Chưa đăng nhập. Vui lòng đăng nhập trước.');
      return;
    }

    try {
      addMessage('User: $message');
      _isLoading = true;
      notifyListeners();

      // Gọi API để xử lý tin nhắn và nhận phản hồi
      // Sử dụng model đã chọn trong selectedModel
      final response = await _apiService.sendMessage(message, _token!,
          model: _selectedModel);

      // Thêm phản hồi của AI vào danh sách tin nhắn
      addMessage('${_selectedModel.toUpperCase()}: $response');

      // Lưu tin nhắn vào lịch sử - nếu cần
      await sendChatMessage(message, response);
    } catch (e) {
      addMessage('Lỗi: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to check if a query is related to a spiritual or ghost topic
  bool _isGhostRelatedQuery(String query) {
    final spiritualKeywords = [
      'ma',
      'quỷ',
      'tâm linh',
      'linh hồn',
      'hồn',
      'ám',
      'kinh dị',
      'rùng rợn',
      'kể chuyện ma',
      'chuyện ma',
      'bóng đêm',
      'mộ',
      'nghĩa địa',
      'ma quỷ',
      'siêu nhiên'
    ];

    final lowerQuery = query.toLowerCase();

    // Count matches and check for exact phrases
    int ghostTermCount = 0;
    for (final term in spiritualKeywords) {
      if (lowerQuery.contains(term)) {
        ghostTermCount++;

        // Strong indicators get priority
        if (term == 'chuyện ma' ||
            term == 'kể chuyện ma' ||
            term == 'ma quỷ' ||
            term == 'linh hồn') {
          return true;
        }
      }
    }

    // Multiple matches also indicate spiritual content
    return ghostTermCount >= 2;
  }

  // Public method to load and refresh workflows
  Future<void> loadWorkflows() async {
    if (_token == null || _token!.isEmpty) {
      return;
    }

    try {
      // First check server connection
      final isConnected = await _apiService.checkServerConnection();

      if (isConnected) {
        // Load workflows from server
        final serverWorkflows = await _apiService.getWorkflows(_token!);

        // Also load local workflows
        final prefs = await SharedPreferences.getInstance();
        final workflowsJson = prefs.getStringList('local_workflows') ?? [];

        List<Workflow> localWorkflows = [];
        if (workflowsJson.isNotEmpty) {
          for (final json in workflowsJson) {
            try {
              final workflow = Workflow.fromJson(jsonDecode(json));
              localWorkflows.add(workflow);
            } catch (e) {
              print('Error parsing local workflow: $e');
            }
          }
        }

        // Merge workflows, prioritizing server workflows
        final Map<String, Workflow> mergedWorkflows = {};

        // Add local workflows first
        for (final workflow in localWorkflows) {
          mergedWorkflows[workflow.id] = workflow;
        }

        // Add server workflows, replacing local if needed
        for (final workflow in serverWorkflows) {
          mergedWorkflows[workflow.id] = workflow;
        }

        // Update saved workflows
        _savedWorkflows = mergedWorkflows.values.toList();
      } else {
        // Offline mode - just load from local storage
        await _loadLocalWorkflows();
      }

      notifyListeners();
    } catch (e) {
      print('Error loading workflows: $e');
      // Fallback to local workflows on error
      await _loadLocalWorkflows();
      notifyListeners();
    }
  }

  // Private method to load workflows from local storage
  Future<void> _loadLocalWorkflows() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workflowsJson = prefs.getStringList('local_workflows') ?? [];

      List<Workflow> localWorkflows = [];
      if (workflowsJson.isNotEmpty) {
        for (final json in workflowsJson) {
          try {
            final workflow = Workflow.fromJson(jsonDecode(json));
            localWorkflows.add(workflow);
          } catch (e) {
            print('Error parsing local workflow: $e');
          }
        }
      }

      _savedWorkflows = localWorkflows;
    } catch (e) {
      print('Error loading local workflows: $e');
    }
  }
}
