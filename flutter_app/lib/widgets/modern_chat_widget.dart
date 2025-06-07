import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../api_service.dart';
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';
import '../models/workflow.dart';
import '../screens/workflows_screen.dart';
import 'workflow_suggestion_widget.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:async';

// Simple code syntax highlighting widget as a replacement for flutter_syntax_view
class SyntaxView extends StatelessWidget {
  final String code;
  final Syntax syntax;
  final SyntaxTheme syntaxTheme;
  final double fontSize;
  final bool withZoom;
  final bool withLinesCount;

  const SyntaxView({
    Key? key,
    required this.code,
    this.syntax = Syntax.DART,
    this.syntaxTheme = const SyntaxTheme.vscodeDark(),
    this.fontSize = 12.0,
    this.withZoom = false,
    this.withLinesCount = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: syntaxTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Syntax enum
enum Syntax { DART, KOTLIN, JAVA, JAVASCRIPT, GO, YAML, JSON, XML, HTML, SHELL }

// SyntaxTheme class
class SyntaxTheme {
  final Color backgroundColor;
  final Color baseColor;
  final Color keywordColor;
  final Color commentColor;
  final Color stringColor;

  const SyntaxTheme({
    required this.backgroundColor,
    required this.baseColor,
    required this.keywordColor,
    required this.commentColor,
    required this.stringColor,
  });

  const SyntaxTheme.vscodeDark({
    this.backgroundColor = const Color(0xFF1E1E1E),
    this.baseColor = const Color(0xFFD4D4D4),
    this.keywordColor = const Color(0xFF569CD6),
    this.commentColor = const Color(0xFF6A9955),
    this.stringColor = const Color(0xFFCE9178),
  });
}

class ModernChatWidget extends StatefulWidget {
  const ModernChatWidget({Key? key}) : super(key: key);

  @override
  _ModernChatWidgetState createState() => _ModernChatWidgetState();
}

class _ModernChatWidgetState extends State<ModernChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isSending = false;
  final ApiService _apiService = ApiService();
  String _token = '';
  List<ChatMessage> _messages = [];

  // Animation controller for workflow suggestion
  Workflow? _suggestedWorkflow;
  bool _showWorkflowSuggestion = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadLocalChatHistory();

    // Initialize API service and get an instance of chat provider
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Listen for changes in the chat provider that might indicate history has been cleared
    chatProvider.addListener(_onChatProviderChanged);

    // Delay for smooth screen transition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _convertLegacyMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();

    // Remove listener when widget is disposed
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.removeListener(_onChatProviderChanged);

    super.dispose();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('jwt_token') ?? '';
    });
  }

  // Load chat history from local storage
  Future<void> _loadLocalChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatHistoryJson = prefs.getString('local_chat_history');

      if (chatHistoryJson != null && chatHistoryJson.isNotEmpty) {
        final List<dynamic> chatHistoryList = json.decode(chatHistoryJson);

        List<ChatMessage> loadedMessages = chatHistoryList.map((messageJson) {
          return ChatMessage.fromJson(messageJson);
        }).toList();

        if (loadedMessages.isNotEmpty) {
          setState(() {
            _messages = loadedMessages;
          });

          print(
              'Loaded ${loadedMessages.length} chat messages from local storage');

          // Scroll to bottom after loading history
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  // Save chat history to local storage
  Future<void> _saveLocalChatHistory() async {
    try {
      if (_messages.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final chatHistoryJson =
          json.encode(_messages.map((message) => message.toJson()).toList());

      await prefs.setString('local_chat_history', chatHistoryJson);
      print('Saved ${_messages.length} chat messages to local storage');
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  // Convert legacy text messages to ChatMessage objects
  void _convertLegacyMessages() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final legacyMessages = chatProvider.messages;

    if (legacyMessages.isNotEmpty) {
      List<ChatMessage> convertedMessages = [];

      for (int i = 0; i < legacyMessages.length; i++) {
        final messageText = legacyMessages[i];
        bool isUser = messageText.startsWith('User: ');
        String content = isUser
            ? messageText.substring(6)
            : messageText.startsWith('AI: ')
                ? messageText.substring(4)
                : messageText;

        final timestamp = DateTime.now()
            .subtract(Duration(minutes: legacyMessages.length - i));

        convertedMessages.add(ChatMessage(
          content: content,
          isUser: isUser,
          timestamp: timestamp,
          sender: isUser ? 'You' : 'Botkube AI',
          status: MessageStatus.delivered,
        ));
      }

      setState(() {
        _messages = convertedMessages;
      });

      // Scroll to bottom after state update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Clear input field and show sending state
    _messageController.clear();
    setState(() {
      _isSending = true;
      _showWorkflowSuggestion = false;
      _suggestedWorkflow = null;

      // Add user message
      _messages.add(ChatMessage(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
        sender: 'You',
        status: MessageStatus.sending,
      ));
    });

    try {
      // Get the ChatProvider
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final selectedModel = chatProvider.selectedModel.toUpperCase();

      // Create a messageId to track this specific message
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();

      // Start monitoring for history updates that could contain a late response
      _setupResponseMonitor(messageId, message);

      // Process message through provider - this will handle both immediate and delayed responses
      await chatProvider.processUserMessageWithoutAdding(message);

      // Get all messages from the provider to find the most recent response
      final providerMessages = chatProvider.messages;
      String? aiResponse;

      // Look for any AI response (skip user messages and processing messages)
      for (int i = providerMessages.length - 1; i >= 0; i--) {
        final msg = providerMessages[i];
        if (!msg.startsWith('User:') &&
            !msg.startsWith('Đang xử lý') &&
            msg != 'Đang xử lý lệnh Kubernetes...' &&
            msg != 'Đang xử lý câu hỏi...') {
          aiResponse = msg;
          break;
        }
      }

      if (aiResponse != null) {
        // Extract content from AI message (remove the model prefix if present)
        String aiContent = aiResponse;
        final modelPrefixPattern =
            RegExp(r'^(GROK|AZURE|OPENAI|CLAUDE|GEMINI|AI):\s*');
        if (modelPrefixPattern.hasMatch(aiResponse)) {
          aiContent = aiResponse.replaceFirst(modelPrefixPattern, '').trim();
        }

        setState(() {
          // Update user message status to delivered
          final userMessageIndex =
              _messages.lastIndexWhere((msg) => msg.isUser);
          if (userMessageIndex >= 0) {
            _messages[userMessageIndex] = _messages[userMessageIndex]
                .copyWith(status: MessageStatus.delivered);
          }

          // Add AI response
          _messages.add(ChatMessage(
            content: aiContent,
            isUser: false,
            timestamp: DateTime.now(),
            sender: 'Botkube AI (${selectedModel})',
            status: MessageStatus.delivered,
          ));
        });
      } else {
        // If no response was found, add a message indicating that one is expected later
        setState(() {
          // Update user message status to pending
          final userMessageIndex =
              _messages.lastIndexWhere((msg) => msg.isUser);
          if (userMessageIndex >= 0) {
            _messages[userMessageIndex] = _messages[userMessageIndex]
                .copyWith(status: MessageStatus.delivered);
          }

          // Add waiting message
          _messages.add(ChatMessage(
            content:
                "Đang chờ phản hồi từ máy chủ. Phản hồi sẽ được cập nhật khi khả dụng.",
            isUser: false,
            timestamp: DateTime.now(),
            sender: 'Botkube AI',
            status: MessageStatus.sending,
          ));
        });
      }

      // Get workflow from provider
      final workflow = chatProvider.workflow;

      // Create workflow suggestion if workflow is not empty
      if (workflow.isNotEmpty) {
        setState(() {
          _suggestedWorkflow = Workflow.fromSuggested(workflow,
              customTitle: "Suggested Actions",
              customDescription:
                  "Here are some actions you might want to take based on your query.");
          _showWorkflowSuggestion = true;
        });
      }

      // Save chat history locally after adding new messages
      _saveLocalChatHistory();
    } catch (e) {
      // Handle error
      setState(() {
        final userMessageIndex = _messages.lastIndexWhere((msg) => msg.isUser);
        if (userMessageIndex >= 0) {
          _messages[userMessageIndex] =
              _messages[userMessageIndex].copyWith(status: MessageStatus.error);
        }

        _messages.add(ChatMessage(
          content: "Sorry, I encountered an error: $e",
          isUser: false,
          timestamp: DateTime.now(),
          sender: 'Botkube AI',
          status: MessageStatus.error,
        ));
      });

      // Save chat history even when there's an error
      _saveLocalChatHistory();
    } finally {
      setState(() {
        _isSending = false;
      });

      // Scroll to bottom after new messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  // Setup monitoring for delayed responses
  void _setupResponseMonitor(String messageId, String originalMessage) {
    // Start a periodic check for response updates in history
    Timer.periodic(Duration(seconds: 2), (timer) {
      // Stop checking after 2 minutes (even if no response)
      if (timer.tick > 60) {
        timer.cancel();
        return;
      }

      _checkForDelayedResponse(originalMessage, timer);
    });
  }

  // Check if a delayed response has arrived
  Future<void> _checkForDelayedResponse(
      String originalMessage, Timer timer) async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final selectedModel = chatProvider.selectedModel.toUpperCase();

      // Fetch latest history to check for updates
      final apiService = ApiService();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      if (token.isEmpty) return;

      final history = await apiService.getHistory(token);

      // Look for a matching request-response pair for our original message
      for (var entry in history) {
        if (entry.message.trim() == originalMessage.trim() &&
            entry.response.isNotEmpty &&
            !entry.response.contains("Quá thời gian chờ phản hồi")) {
          // Found a real response! Update the UI
          setState(() {
            // Find the last AI message that might be a timeout or waiting message
            final lastAiMessageIndex =
                _messages.lastIndexWhere((msg) => !msg.isUser);
            if (lastAiMessageIndex >= 0) {
              // Check if the last message was a timeout message
              final lastContent =
                  _messages[lastAiMessageIndex].content.toLowerCase();
              if (lastContent.contains("thời gian chờ") ||
                  lastContent.contains("timeout") ||
                  lastContent.contains("đang chờ phản hồi")) {
                // Replace the timeout message with the real response
                _messages[lastAiMessageIndex] = ChatMessage(
                  content: entry.response,
                  isUser: false,
                  timestamp: DateTime.now(),
                  sender: 'Botkube AI (${selectedModel})',
                  status: MessageStatus.delivered,
                );

                // Cancel the timer since we found our response
                timer.cancel();

                // Save the updated chat history
                _saveLocalChatHistory();

                // Scroll to show the updated message
                _scrollToBottom();
              }
            }
          });
          break;
        }
      }
    } catch (e) {
      print('Error checking for delayed response: $e');
    }
  }

  // Execute a workflow step
  Future<String> _executeWorkflowStep(String step) async {
    try {
      final result = await _apiService.executeWorkflowStep(step, _token);
      return result;
    } catch (e) {
      return "Error executing step: $e";
    }
  }

  // Navigate to the saved workflows screen
  void _navigateToWorkflowsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkflowsScreen(),
      ),
    );
  }

  // Clear local chat history
  Future<void> _clearLocalChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_chat_history');

      setState(() {
        _messages.clear();
      });

      print('Local chat history cleared');
    } catch (e) {
      print('Error clearing local chat history: $e');
    }
  }

  // Listen for changes in the chat provider
  void _onChatProviderChanged() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Check if history was recently cleared
    if (chatProvider.checkAndResetHistoryCleared()) {
      _clearLocalChatHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Botkube AI Chat'),
        elevation: 1,
        actions: [
          // Model selection dropdown
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text('AI Model:', style: TextStyle(fontSize: 14)),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: chatProvider.selectedModel,
                  icon: Icon(Icons.arrow_drop_down),
                  elevation: 16,
                  underline: Container(
                    height: 2,
                    color: Colors.greenAccent,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      chatProvider.selectedModel = newValue;
                    }
                  },
                  items: chatProvider.availableModels
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Display a small icon or indicator for the model
                          _getModelIcon(value),
                          SizedBox(width: 8),
                          Text(value.toUpperCase()),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Clear chat history button
          IconButton(
            icon: Icon(Icons.delete_outline),
            tooltip: 'Clear chat',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Clear Chat History'),
                  content:
                      Text('Are you sure you want to clear your chat history?'),
                  actions: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      child: Text('Clear'),
                      onPressed: () {
                        _clearLocalChatHistory();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          // Saved workflows button
          IconButton(
            icon: Icon(Icons.work_outline),
            tooltip: 'Saved Workflows',
            onPressed: _navigateToWorkflowsScreen,
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [Color(0xFF121212), Color(0xFF1E1E1E)]
                      : [Color(0xFFF5F9FF), Color(0xFFE8F5E9)],
                ),
              ),
              child: Stack(
                children: [
                  // Messages list
                  _messages.isEmpty
                      ? _buildWelcomeScreen()
                      : _buildMessagesList(),

                  // Workflow suggestion
                  if (_showWorkflowSuggestion && _suggestedWorkflow != null)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      width: isSmallScreen
                          ? screenSize.width * 0.9
                          : math.min(400, screenSize.width * 0.4),
                      child: WorkflowSuggestionWidget(
                        workflow: _suggestedWorkflow!,
                        onDismiss: () {
                          setState(() {
                            _showWorkflowSuggestion = false;
                          });
                        },
                        onExecuteStep: _executeWorkflowStep,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Input field
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    final chatProvider = Provider.of<ChatProvider>(context);
    final selectedModel = chatProvider.selectedModel;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.green[300],
          ),
          SizedBox(height: 16),
          Text(
            'Welcome to Botkube AI Chat',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: 8),
          // Current model indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getModelColor(selectedModel).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getModelColor(selectedModel)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getModelIcon(selectedModel),
                SizedBox(width: 8),
                Text(
                  'Using ${selectedModel.toUpperCase()} model',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getModelColor(selectedModel),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ask me anything about Kubernetes or other topics',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          Container(
            width: 300,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Try asking:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 8),
                _buildSuggestionButton("How can I check Kubernetes pod logs?"),
                SizedBox(height: 8),
                _buildSuggestionButton(
                    "What are the best practices for Kubernetes security?"),
                SizedBox(height: 8),
                _buildSuggestionButton("How do I troubleshoot a failed pod?"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionButton(String text) {
    return InkWell(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_right, size: 16, color: Colors.green),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.green[800],
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 16,
        left: isUser ? 50 : 0,
        right: isUser ? 0 : 50,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender info and timestamp
          Padding(
            padding: EdgeInsets.only(bottom: 4, left: 8, right: 8),
            child: Row(
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isUser) _buildAvatar(message.sender),
                SizedBox(width: 8),
                Text(
                  message.sender,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  timeago.format(message.timestamp, locale: 'en_short'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                if (isUser) ...[
                  SizedBox(width: 8),
                  _buildStatusIndicator(message.status),
                  SizedBox(width: 8),
                  _buildAvatar(message.sender),
                ],
              ],
            ),
          ),

          // Message content
          Container(
            decoration: BoxDecoration(
              color: isUser
                  ? Color(0xFF1E88E5) // Blue for user
                  : Colors.white, // White for AI
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: _buildMessageContent(message.content),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String sender) {
    if (sender == 'You') {
      return CircleAvatar(
        backgroundColor: Colors.blue[700],
        radius: 16,
        child: Text(
          'U',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return CircleAvatar(
        backgroundColor: Colors.green[700],
        radius: 16,
        child: Text(
          'B',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Widget _buildStatusIndicator(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        );
      case MessageStatus.delivered:
        return Icon(Icons.check_circle, size: 12, color: Colors.green);
      case MessageStatus.error:
        return Icon(Icons.error, size: 12, color: Colors.red);
      default:
        return SizedBox(width: 12);
    }
  }

  Widget _buildMessageContent(String content) {
    // Detect if content contains code blocks
    if (content.contains('```')) {
      return _buildContentWithCodeBlocks(content);
    } else {
      return SelectableText(
        content,
        style: TextStyle(
          fontSize: 15,
          color: content.startsWith('Error:') ? Colors.red : null,
        ),
      );
    }
  }

  Widget _buildContentWithCodeBlocks(String content) {
    // Split by code blocks
    final List<String> parts = content.split(RegExp(r'```(?:[\w]*)?'));

    // Widgets to display
    List<Widget> widgets = [];

    // Flag to track if we're in a code block
    bool isCodeBlock = false;

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].trim().isEmpty) continue;

      if (isCodeBlock) {
        // This is a code block, extract language if specified
        String lang = 'shell'; // default language
        String code = parts[i].trim();

        // Create a code viewer with syntax highlighting
        widgets.add(
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF282C34),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Code with syntax highlighting
                Padding(
                  padding: EdgeInsets.all(12),
                  child: SyntaxView(
                    code: code,
                    syntax: Syntax.DART, // Default syntax
                    syntaxTheme: SyntaxTheme.vscodeDark(),
                    fontSize: 13,
                    withZoom: false,
                    withLinesCount: false,
                  ),
                ),

                // Copy button
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: Icon(Icons.copy, color: Colors.white70, size: 18),
                    tooltip: 'Copy code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Code copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // This is regular text
        widgets.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: SelectableText(
              parts[i].trim(),
              style: TextStyle(fontSize: 15),
            ),
          ),
        );
      }

      // Toggle between code block and regular text
      isCodeBlock = !isCodeBlock;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildInputField() {
    return Column(
      children: [
        // Input field
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Text input
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _inputFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: _isSending
                        ? Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                          )
                        : null,
                  ),
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),

              // Send button
              SizedBox(width: 12),
              FloatingActionButton(
                onPressed: _isSending ? null : _sendMessage,
                backgroundColor: Colors.green[700],
                elevation: 2,
                tooltip: 'Send message',
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to get an icon for each AI model
  Widget _getModelIcon(String model) {
    switch (model.toLowerCase()) {
      case 'grok':
        return Icon(Icons.auto_awesome, color: Colors.purple, size: 18);
      case 'openai':
        return Icon(Icons.lightbulb_outline, color: Colors.green, size: 18);
      case 'gemini':
        return Icon(Icons.psychology, color: Colors.blue, size: 18);
      case 'claude':
        return Icon(Icons.smart_toy_outlined, color: Colors.orange, size: 18);
      default:
        return Icon(Icons.smart_toy, color: Colors.grey, size: 18);
    }
  }

  // Helper to get color for model
  Color _getModelColor(String model) {
    switch (model.toLowerCase()) {
      case 'grok':
        return Colors.purple;
      case 'openai':
        return Colors.green;
      case 'gemini':
        return Colors.blue;
      case 'claude':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// Using MessageStatus enum from chat_message.dart
