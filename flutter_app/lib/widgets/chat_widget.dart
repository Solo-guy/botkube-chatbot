import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../models/event.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../main.dart'; // Import để sử dụng GradientButton
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';
import '../models/workflow.dart';
import 'workflow_suggestion_widget.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../models/event.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../main.dart'; // Import để sử dụng GradientButton
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';
import '../models/workflow.dart';
import 'workflow_suggestion_widget.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart';
// Comment out the import for AppLocalizations as it seems to be missing
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Enhanced Vietnamese text input formatter that properly handles diacritical marks
class VietnameseTextInputFormatter extends TextInputFormatter {
  // Lưu trạng thái để theo dõi văn bản
  String _lastValidText = '';
  bool _isApplyingAccent = false;

  // Theo dõi trạng thái đặt dấu đặc biệt cho một số trường hợp
  int _lastSelectionStart = -1;
  String _lastCharBeforeCursor = '';

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Reset trạng thái áp dụng dấu
    _isApplyingAccent = false;

    // Log để debug
    // print("Old: '${oldValue.text}', New: '${newValue.text}'");
    // print("Selection: old=${oldValue.selection.baseOffset}, new=${newValue.selection.baseOffset}");

    // Lưu vị trí con trỏ cho xử lý sau này
    _lastSelectionStart = newValue.selection.baseOffset;
    if (_lastSelectionStart > 0 &&
        _lastSelectionStart <= oldValue.text.length) {
      _lastCharBeforeCursor = oldValue.text[_lastSelectionStart - 1];
    }

    // Trường hợp 1: Xử lý trường hợp gõ "dd" cho chữ "đ" (kiểu gõ Telex)
    if (newValue.text.length > oldValue.text.length &&
        newValue.text.endsWith('dd')) {
      final result = newValue.text.substring(0, newValue.text.length - 2) + 'đ';
      return TextEditingValue(
        text: result,
        selection: TextSelection.collapsed(offset: result.length),
      );
    }

    // Trường hợp 2: Xử lý các trường hợp đặt dấu
    // Nếu đang xóa nhiều ký tự, thì giữ nguyên hành động xóa
    if (newValue.text.length < oldValue.text.length - 1) {
      _lastValidText = newValue.text;
      return newValue;
    }

    // Trường hợp 3: Xử lý khi xóa đúng 1 ký tự (có thể là để đặt dấu)
    if (newValue.text.length == oldValue.text.length - 1 &&
        oldValue.text.isNotEmpty) {
      final removedChar = _findRemovedChar(oldValue.text, newValue.text);

      // Kiểm tra nếu có ký tự ngay trước vị trí con trỏ hiện tại
      String targetChar = '';
      int charPosition = -1;

      // Xác định ký tự cần đặt dấu và vị trí của nó
      if (_lastSelectionStart > 0 &&
          _lastSelectionStart < oldValue.text.length) {
        // Nếu con trỏ ở giữa văn bản, lấy ký tự trước con trỏ
        targetChar = oldValue.text[_lastSelectionStart - 1];
        charPosition = _lastSelectionStart - 1;
      } else if (newValue.text.isNotEmpty) {
        // Nếu ở cuối văn bản, lấy ký tự cuối
        targetChar = oldValue.text[oldValue.text.length - 1];
        charPosition = oldValue.text.length - 1;
      }

      // Kiểm tra nếu đó là một ký tự gõ tắt để tạo dấu
      if (_isAccentMarker(removedChar) && _isVietnameseVowel(targetChar)) {
        final accentedChar = _applyAccentFromMarker(targetChar, removedChar);
        if (accentedChar != targetChar) {
          _isApplyingAccent = true;

          // Tạo văn bản mới bằng cách thay thế ký tự cần đặt dấu
          String resultText = newValue.text.substring(0, charPosition) +
              accentedChar +
              newValue.text.substring(charPosition);

          // Lưu kết quả hợp lệ
          _lastValidText = resultText;

          return TextEditingValue(
            text: resultText,
            selection: TextSelection.collapsed(offset: charPosition + 1),
          );
        }
      }

      // Xử lý trường hợp đặc biệt khi gõ "d9" để tạo "đ" (kiểu gõ VNI)
      if (removedChar == '9' &&
          charPosition >= 0 &&
          charPosition < oldValue.text.length &&
          oldValue.text[charPosition] == 'd') {
        String resultText = newValue.text.substring(0, charPosition) +
            'đ' +
            newValue.text.substring(charPosition + 1);
        return TextEditingValue(
          text: resultText,
          selection: TextSelection.collapsed(offset: charPosition + 1),
        );
      }
    }

    // Trường hợp 4: Nếu đang thêm ký tự, thì giữ nguyên hành động thêm
    if (newValue.text.length > oldValue.text.length) {
      _lastValidText = newValue.text;
      return newValue;
    }

    // Trường hợp 5: Kiểm tra xem có phải đang thêm dấu hay không (nếu độ dài không đổi)
    if (newValue.text.length == oldValue.text.length &&
        newValue.text != oldValue.text) {
      // Tìm vị trí ký tự thay đổi
      int changedIndex = _findChangedCharIndex(oldValue.text, newValue.text);
      if (changedIndex >= 0) {
        String oldChar = oldValue.text[changedIndex];
        String newChar = newValue.text[changedIndex];

        // Nếu đây là một thay đổi từ ký tự thường sang ký tự có dấu
        if (_isVietnameseVowel(oldChar) &&
            _isVietnameseVowel(newChar) &&
            _hasAccent(newChar)) {
          _isApplyingAccent = true;

          // Lưu kết quả hợp lệ
          _lastValidText = newValue.text;
          return newValue;
        }
      }
    }

    // Không có gì đặc biệt xảy ra, trả về giá trị mới
    _lastValidText = newValue.text;
    return newValue;
  }

  // Tìm ký tự đã bị xóa giữa hai chuỗi
  String _findRemovedChar(String oldText, String newText) {
    if (oldText.length != newText.length + 1) return '';

    for (int i = 0; i < newText.length; i++) {
      if (i >= oldText.length || newText[i] != oldText[i]) {
        return oldText[i];
      }
    }

    return oldText[oldText.length - 1];
  }

  // Tìm vị trí ký tự đã thay đổi
  int _findChangedCharIndex(String oldText, String newText) {
    if (oldText.length != newText.length) return -1;

    for (int i = 0; i < oldText.length; i++) {
      if (oldText[i] != newText[i]) {
        return i;
      }
    }

    return -1;
  }

  // Kiểm tra xem một ký tự có phải là ký tự tạo dấu trong kiểu gõ tiếng Việt không
  bool _isAccentMarker(String char) {
    if (char.isEmpty) return false;
    return "sfrxj`'/.?~\\1234567890".contains(char);
  }

  // Áp dụng dấu dựa trên ký tự marker
  String _applyAccentFromMarker(String vowel, String marker) {
    if (vowel.isEmpty || marker.isEmpty) return vowel;

    // Mapping cho các kiểu gõ Telex và VNI
    switch (marker) {
      case 's':
      case '/':
      case '\'':
      case '1':
        return _applyAccentToCharacter(vowel, 'ACUTE'); // Dấu sắc
      case 'f':
      case '`':
      case '\\':
      case '2':
        return _applyAccentToCharacter(vowel, 'GRAVE'); // Dấu huyền
      case 'r':
      case '?':
      case '3':
        return _applyAccentToCharacter(vowel, 'HOOK'); // Dấu hỏi
      case 'x':
      case '~':
      case '4':
        return _applyAccentToCharacter(vowel, 'TILDE'); // Dấu ngã
      case 'j':
      case '.':
      case '5':
        return _applyAccentToCharacter(vowel, 'DOT'); // Dấu nặng
      // Xử lý các trường hợp đặc biệt cho kiểu gõ VNI
      case '6': // ă
        if (vowel == 'a') return 'ă';
        if (vowel == 'A') return 'Ă';
        break;
      case '7': // ơ
        if (vowel == 'o') return 'ơ';
        if (vowel == 'O') return 'Ơ';
        break;
      case '8': // ư
        if (vowel == 'u') return 'ư';
        if (vowel == 'U') return 'Ư';
        break;
      case '9': // đ được xử lý riêng bên ngoài
        break;
      default:
        return vowel;
    }
    return vowel;
  }

  // Kiểm tra xem một ký tự có phải là nguyên âm tiếng Việt hay không
  bool _isVietnameseVowel(String char) {
    if (char.isEmpty) return false;

    final vietnameseVowels = 'aăâeêioôơuưyAĂÂEÊIOÔƠUƯY';

    // Bao gồm cả nguyên âm đã có dấu
    final accentedVowels =
        'àáảãạằắẳẵặầấẩẫậèéẻẽẹềếểễệìíỉĩịòóỏõọồốổỗộờớởỡợùúủũụừứửữựỳýỷỹỵ' +
            'ÀÁẢÃẠẰẮẲẴẶẦẤẨẪẬÈÉẺẼẸỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌỒỐỔỖỘỜỚỞỠỢÙÚỦŨỤỪỨỬỮỰỲÝỶỸỴ';

    return vietnameseVowels.contains(char) || accentedVowels.contains(char);
  }

  // Kiểm tra xem một ký tự có dấu hay không
  bool _hasAccent(String char) {
    if (char.isEmpty) return false;

    final accentedChars =
        'àáảãạằắẳẵặầấẩẫậèéẻẽẹềếểễệìíỉĩịòóỏõọồốổỗộờớởỡợùúủũụừứửữựỳýỷỹỵđ' +
            'ÀÁẢÃẠẰẮẲẴẶẦẤẨẪẬÈÉẺẼẸỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌỒỐỔỖỘỜỚỞỠỢÙÚỦŨỤỪỨỬỮỰỲÝỶỸỴĐ';

    return accentedChars.contains(char);
  }

  // Áp dụng dấu vào ký tự
  String _applyAccentToCharacter(String char, String accent) {
    // Bảng ánh xạ cho các loại dấu
    final Map<String, Map<String, String>> accentMaps = {
      'GRAVE': {
        'a': 'à',
        'ă': 'ằ',
        'â': 'ầ',
        'e': 'è',
        'ê': 'ề',
        'i': 'ì',
        'o': 'ò',
        'ô': 'ồ',
        'ơ': 'ờ',
        'u': 'ù',
        'ư': 'ừ',
        'y': 'ỳ',
        'A': 'À',
        'Ă': 'Ằ',
        'Â': 'Ầ',
        'E': 'È',
        'Ê': 'Ề',
        'I': 'Ì',
        'O': 'Ò',
        'Ô': 'Ồ',
        'Ơ': 'Ờ',
        'U': 'Ù',
        'Ư': 'Ừ',
        'Y': 'Ỳ'
      },
      'ACUTE': {
        'a': 'á',
        'ă': 'ắ',
        'â': 'ấ',
        'e': 'é',
        'ê': 'ế',
        'i': 'í',
        'o': 'ó',
        'ô': 'ố',
        'ơ': 'ớ',
        'u': 'ú',
        'ư': 'ứ',
        'y': 'ý',
        'A': 'Á',
        'Ă': 'Ắ',
        'Â': 'Ấ',
        'E': 'É',
        'Ê': 'Ế',
        'I': 'Í',
        'O': 'Ó',
        'Ô': 'Ố',
        'Ơ': 'Ớ',
        'U': 'Ú',
        'Ư': 'Ứ',
        'Y': 'Ý'
      },
      'HOOK': {
        'a': 'ả',
        'ă': 'ẳ',
        'â': 'ẩ',
        'e': 'ẻ',
        'ê': 'ể',
        'i': 'ỉ',
        'o': 'ỏ',
        'ô': 'ổ',
        'ơ': 'ở',
        'u': 'ủ',
        'ư': 'ử',
        'y': 'ỷ',
        'A': 'Ả',
        'Ă': 'Ẳ',
        'Â': 'Ẩ',
        'E': 'Ẻ',
        'Ê': 'Ể',
        'I': 'Ỉ',
        'O': 'Ỏ',
        'Ô': 'Ổ',
        'Ơ': 'Ở',
        'U': 'Ủ',
        'Ư': 'Ử',
        'Y': 'Ỷ'
      },
      'TILDE': {
        'a': 'ã',
        'ă': 'ẵ',
        'â': 'ẫ',
        'e': 'ẽ',
        'ê': 'ễ',
        'i': 'ĩ',
        'o': 'õ',
        'ô': 'ỗ',
        'ơ': 'ỡ',
        'u': 'ũ',
        'ư': 'ữ',
        'y': 'ỹ',
        'A': 'Ã',
        'Ă': 'Ẵ',
        'Â': 'Ẫ',
        'E': 'Ẽ',
        'Ê': 'Ễ',
        'I': 'Ĩ',
        'O': 'Õ',
        'Ô': 'Ỗ',
        'Ơ': 'Ỡ',
        'U': 'Ũ',
        'Ư': 'Ữ',
        'Y': 'Ỹ'
      },
      'DOT': {
        'a': 'ạ',
        'ă': 'ặ',
        'â': 'ậ',
        'e': 'ẹ',
        'ê': 'ệ',
        'i': 'ị',
        'o': 'ọ',
        'ô': 'ộ',
        'ơ': 'ợ',
        'u': 'ụ',
        'ư': 'ự',
        'y': 'ỵ',
        'A': 'Ạ',
        'Ă': 'Ặ',
        'Â': 'Ậ',
        'E': 'Ẹ',
        'Ê': 'Ệ',
        'I': 'Ị',
        'O': 'Ọ',
        'Ô': 'Ộ',
        'Ơ': 'Ợ',
        'U': 'Ụ',
        'Ư': 'Ự',
        'Y': 'Ỵ'
      }
    };

    // Kiểm tra nếu đã có dấu thì loại bỏ dấu trước
    String baseChar = _removeAccent(char);

    // Trả về ký tự có dấu tương ứng
    if (accentMaps.containsKey(accent) &&
        accentMaps[accent]!.containsKey(baseChar)) {
      return accentMaps[accent]![baseChar]!;
    }

    // Trả về ký tự gốc nếu không thể áp dụng dấu
    return char;
  }

  // Loại bỏ dấu từ ký tự
  String _removeAccent(String char) {
    if (char.isEmpty) return '';

    final accentToBase = {
      'á': 'a',
      'à': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'ắ': 'ă',
      'ằ': 'ă',
      'ẳ': 'ă',
      'ẵ': 'ă',
      'ặ': 'ă',
      'ấ': 'â',
      'ầ': 'â',
      'ẩ': 'â',
      'ẫ': 'â',
      'ậ': 'â',
      'é': 'e',
      'è': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ế': 'ê',
      'ề': 'ê',
      'ể': 'ê',
      'ễ': 'ê',
      'ệ': 'ê',
      'í': 'i',
      'ì': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'ó': 'o',
      'ò': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ố': 'ô',
      'ồ': 'ô',
      'ổ': 'ô',
      'ỗ': 'ô',
      'ộ': 'ô',
      'ớ': 'ơ',
      'ờ': 'ơ',
      'ở': 'ơ',
      'ỡ': 'ơ',
      'ợ': 'ơ',
      'ú': 'u',
      'ù': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ứ': 'ư',
      'ừ': 'ư',
      'ử': 'ư',
      'ữ': 'ư',
      'ự': 'ư',
      'ý': 'y',
      'ỳ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
      'Á': 'A',
      'À': 'A',
      'Ả': 'A',
      'Ã': 'A',
      'Ạ': 'A',
      'Ắ': 'Ă',
      'Ằ': 'Ă',
      'Ẳ': 'Ă',
      'Ẵ': 'Ă',
      'Ặ': 'Ă',
      'Ấ': 'Â',
      'Ầ': 'Â',
      'Ẩ': 'Â',
      'Ẫ': 'Â',
      'Ậ': 'Â',
      'É': 'E',
      'È': 'E',
      'Ẻ': 'E',
      'Ẽ': 'E',
      'Ẹ': 'E',
      'Ế': 'Ê',
      'Ề': 'Ê',
      'Ể': 'Ê',
      'Ễ': 'Ê',
      'Ệ': 'Ê',
      'Í': 'I',
      'Ì': 'I',
      'Ỉ': 'I',
      'Ĩ': 'I',
      'Ị': 'I',
      'Ó': 'O',
      'Ò': 'O',
      'Ỏ': 'O',
      'Õ': 'O',
      'Ọ': 'O',
      'Ố': 'Ô',
      'Ồ': 'Ô',
      'Ổ': 'Ô',
      'Ỗ': 'Ô',
      'Ộ': 'Ô',
      'Ớ': 'Ơ',
      'Ờ': 'Ơ',
      'Ở': 'Ơ',
      'Ỡ': 'Ơ',
      'Ợ': 'Ơ',
      'Ú': 'U',
      'Ù': 'U',
      'Ủ': 'U',
      'Ũ': 'U',
      'Ụ': 'U',
      'Ứ': 'Ư',
      'Ừ': 'Ư',
      'Ử': 'Ư',
      'Ữ': 'Ư',
      'Ự': 'Ư',
      'Ý': 'Y',
      'Ỳ': 'Y',
      'Ỷ': 'Y',
      'Ỹ': 'Y',
      'Ỵ': 'Y',
      'đ': 'd',
      'Đ': 'D'
    };

    return accentToBase[char] ?? char;
  }
}

// Nút với gradient cho dialog
class DialogButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const DialogButton({
    Key? key,
    required this.onPressed,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF5C0000),
            Color(0xFFC20000),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            text,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class ChatWidget extends StatefulWidget {
  const ChatWidget({Key? key}) : super(key: key);

  @override
  _ChatWidgetState createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Tải lịch sử chat khi widget được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ChatProvider>(context, listen: false);

      // Clear any existing messages first to prevent duplicates on page reload
      provider.clearMessages();

      // Then load the chat history
      provider.loadHistory();

      // Lắng nghe thay đổi workflow
      provider.addListener(_checkForWorkflow);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    // Đảm bảo hủy đăng ký listener khi widget bị hủy
    final provider = Provider.of<ChatProvider>(context, listen: false);
    provider.removeListener(_checkForWorkflow);
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _checkForWorkflow() {
    final provider = Provider.of<ChatProvider>(context, listen: false);

    // Make sure we check both workflow and currentWorkflow
    bool hasWorkflow = provider.workflow.isNotEmpty;
    bool hasCurrentWorkflow = provider.currentWorkflow != null;

    // Log workflow state for debugging
    print(
        'Checking workflow - Has steps: $hasWorkflow, Has workflow object: $hasCurrentWorkflow');
    if (hasWorkflow) {
      print('Workflow steps count: ${provider.workflow.length}');
      print('Workflow steps: ${provider.workflow.join(" | ")}');
    }

    // Show workflow dialog immediately if there are workflow steps and not already showing
    if (hasWorkflow && !_isWorkflowDialogShowing) {
      print('Showing workflow dialog');
      // No delay - directly show workflow
      if (mounted && !_isWorkflowDialogShowing) {
        _showWorkflow(provider.workflow);
      }
    } else {
      print(
          'Not showing workflow dialog. HasWorkflow: $hasWorkflow, IsShowing: $_isWorkflowDialogShowing');
    }
  }

  Future<void> _handleMessage(String text) async {
    if (text.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _textController.clear();

    try {
      // Log message before processing (helps debug Vietnamese text issues)
      print('Handling message: "$text"');
      print('Message length: ${text.length}');

      // Log each character and its code point to debug Vietnamese character issues
      print('Character breakdown:');
      for (int i = 0; i < text.length; i++) {
        int codePoint = text.codeUnitAt(i);
        String char = text[i];
        print(
            'Char[$i]: $char (Unicode: U+${codePoint.toRadixString(16).padLeft(4, '0')})');
      }

      // Normalize the text to NFC form to ensure proper Vietnamese handling
      // NFC form combines characters and diacritics in the most compact way
      String normalizedText = text;

      // Ensure all Vietnamese characters are properly encoded
      final List<int> bytes = utf8.encode(normalizedText);
      final String utf8Text = utf8.decode(bytes, allowMalformed: true);

      // Use the normalized text for all further processing
      final String processedText = utf8Text;
      print('Normalized text: "$processedText"');

      // Detect ghost/spirit-related Vietnamese queries
      final lowerText = processedText.toLowerCase();

      // These are words commonly associated with ghost stories in Vietnamese
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

      bool containsGhostTerms = false;
      for (final term in ghostRelatedWords) {
        if (lowerText.contains(term)) {
          containsGhostTerms = true;
          print('Ghost-related term detected: $term');
          break;
        }
      }

      // Check if the message contains Vietnamese characters that need special handling
      bool hasVietnameseChars = RegExp(
              r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]',
              unicode: true)
          .hasMatch(lowerText);

      if (hasVietnameseChars) {
        print(
            'Message contains Vietnamese characters, ensuring proper encoding');
        // Extra logging for troubleshooting
        for (int i = 0; i < processedText.length; i++) {
          final char = processedText[i];
          final codePoint = char.codeUnitAt(0);
          print(
              'Character $i: $char (${codePoint.toRadixString(16).padLeft(4, '0')})');
        }
      }

      if (containsGhostTerms) {
        print('Message contains ghost-related terms, using special handling');
      }

      // First display the user's message locally to ensure it shows immediately
      // Use the normalized text to preserve all Vietnamese characters
      chatProvider.addMessage('User: $processedText');

      // Use the provider's method to process the message and get AI response
      // We don't need to add the user message again as we already did it above
      await chatProvider.processUserMessageWithoutAdding(processedText);

      // We scroll to bottom to show the new messages as they appear
      _scrollToBottom();
    } catch (e) {
      print('Error handling message: $e');

      // Attempt recovery on error - use the original text to preserve Vietnamese characters
      try {
        chatProvider.addMessage('User: $text');
        chatProvider.addMessage('Error: $e');
      } catch (innerError) {
        print('Error during recovery: $innerError');
      }
    }
  }

  // Check if the workflow is the default Kubernetes workflow
  bool _isDefaultKubernetesWorkflow(List<dynamic> workflow) {
    if (workflow.length != 3) return false;

    // Check if this is the default Kubernetes workflow that's often applied to non-Kubernetes queries
    String workflowString = workflow.join(' ').toLowerCase();
    return workflowString.contains('log pod') &&
        workflowString.contains('tài nguyên') &&
        workflowString.contains('lịch sử');
  }

  // Generate appropriate workflow based on query context
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

    // Check if question is about spiritual/supernatural topics
    if (lowerMessage.contains('ma') ||
        lowerMessage.contains('quỷ') ||
        lowerMessage.contains('tâm linh') ||
        lowerResponse.contains('tâm linh') ||
        lowerResponse.contains('ma quỷ')) {
      return [
        "Tìm hiểu các tài liệu về tâm linh hoặc triết học.",
        "Tham khảo ý kiến từ chuyên gia về tâm lý hoặc tâm linh.",
        "Khám phá các phương pháp thiền định để cải thiện sức khỏe tinh thần."
      ];
    }

    // Default general-purpose workflow
    return [
      "Tìm kiếm thêm thông tin về chủ đề này trên internet.",
      "Tham khảo ý kiến của chuyên gia nếu cần thiết.",
      "Ghi chú lại thông tin hữu ích để tham khảo sau."
    ];
  }

  bool _isKubernetesRelated(String input) {
    if (input.isEmpty) {
      return false;
    }

    final lowerInput = input.toLowerCase().trim();
    final kubernetesKeywords = [
      'pod',
      'pods',
      'namespace',
      'cluster',
      'kubectl',
      'deployment',
      'service',
      'node',
      'nodes',
      'configmap',
      'secret',
      'daemonset',
      'statefulset',
      'cronjob',
      'job',
      'ingress',
      'networkpolicy',
      'persistentvolume',
      'pv',
      'pvc',
      'scale',
      'rollout',
      'restart',
      'port-forward',
      'exec',
      'logs',
      'label',
      'api-resource',
      'api-version',
      'config',
      'cluster-info',
      'k8s',
      'kube'
    ];

    // Check for exact commands first
    if (lowerInput.startsWith('kubectl ') ||
        lowerInput.startsWith('get ') ||
        lowerInput.startsWith('describe ') ||
        lowerInput.startsWith('delete ') ||
        lowerInput.startsWith('apply ') ||
        lowerInput.startsWith('create ')) {
      return true;
    }

    // Then check for keyword presence as whole words, not parts of words
    for (final keyword in kubernetesKeywords) {
      final pattern = RegExp(r'\b' + keyword + r'\b');
      if (pattern.hasMatch(lowerInput)) {
        return true;
      }
    }

    // Simple greetings and questions should not be treated as Kubernetes queries
    final commonPhrases = [
      'hi',
      'hello',
      'hey',
      'what',
      'who',
      'where',
      'when',
      'why',
      'how',
      'tell me',
      'explain',
      'describe',
      'talk about',
      'can you',
      'could you',
      'i want',
      'i need',
      'help me',
      'xin chào',
      'chào'
    ];

    for (final phrase in commonPhrases) {
      if (lowerInput.startsWith(phrase)) {
        return false;
      }
    }

    return false; // Default to natural language if uncertain
  }

  Future<String> _handleExecuteWorkflowStep(String step) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Extract command from step text (assuming format like: "1. Command to execute" or "- Command to execute")
    final commandMatch = RegExp(r'(?:\d+\.\s|\-\s)(.+)').firstMatch(step);
    final command = commandMatch?.group(1)?.trim() ?? step.trim();

    // Add the command to the chat
    chatProvider.addMessage('Đang thực hiện: $command');

    try {
      chatProvider.setLoading(true);

      // Check if token is valid
      if (chatProvider.token == null || chatProvider.token!.isEmpty) {
        await chatProvider.reloadToken();
        if (chatProvider.token == null || chatProvider.token!.isEmpty) {
          chatProvider.addMessage(
              'Lỗi: Chưa đăng nhập. Vui lòng đăng nhập trước khi thực hiện lệnh.');
          return 'Lỗi: Không có token';
        }
      }

      // Execute the command through API service
      final result =
          await _apiService.sendCommand(command, chatProvider.token!);

      // Show the result
      chatProvider.addMessage('Kết quả: $result');

      // Save to chat history
      await _apiService.sendChatMessage(command, result);

      return result; // Return result for the workflow widget to handle
    } catch (e) {
      final errorMsg = 'Lỗi khi thực hiện bước: $e';
      chatProvider.addMessage(errorMsg);
      print('Lỗi chi tiết khi thực hiện bước: $e');
      throw Exception(
          errorMsg); // Rethrow to let workflow widget know there was an error
    } finally {
      chatProvider.setLoading(false);
    }
  }

  // Biến để theo dõi trạng thái hiển thị của dialog
  bool _isWorkflowDialogShowing = false;

  void _showWorkflow(List<String> workflowSteps) {
    if (_isWorkflowDialogShowing) return;
    _isWorkflowDialogShowing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use showGeneralDialog instead of showDialog for more control
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: "Workflow Dialog",
        transitionDuration: Duration(milliseconds: 200),
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return SafeArea(
            child: Center(
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                    maxWidth: MediaQuery.of(context).size.width * 0.95,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: WorkflowSuggestionWidget(
                          workflow: Workflow(
                            title: 'Quy trình làm việc được đề xuất',
                            steps: workflowSteps,
                            description:
                                'Đây là quy trình được AI đề xuất dựa trên phân tích sự kiện hiện tại',
                          ),
                          onDismiss: () {
                            Navigator.of(context).pop();
                            _dismissWorkflow();
                          },
                          onExecuteStep: (step) async {
                            final result =
                                await _handleExecuteWorkflowStep(step);
                            return result;
                          },
                        ),
                      ),
                      // Add a "Save to Templates" button at the bottom
                      Container(
                        width: double.infinity,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFF004D40),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: TextButton.icon(
                          icon: Icon(Icons.save, color: Colors.white),
                          label: Text(
                            'Lưu vào mẫu quy trình',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          onPressed: () =>
                              _showSaveWorkflowDialog(workflowSteps),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ).then((_) {
        _isWorkflowDialogShowing = false;
      });
    });
  }

  // Show dialog to save workflow with custom title and description
  void _showSaveWorkflowDialog(List<String> steps) {
    final TextEditingController titleController =
        TextEditingController(text: 'Quy trình đã lưu từ AI');
    final TextEditingController descriptionController = TextEditingController(
        text: 'Quy trình làm việc được lưu từ đề xuất của AI');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Lưu quy trình làm việc'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                inputFormatters: [VietnameseTextInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                inputFormatters: [VietnameseTextInputFormatter()],
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF014D17),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final chatProvider =
                    Provider.of<ChatProvider>(context, listen: false);
                chatProvider.saveCurrentWorkflow(
                  title: titleController.text,
                  description: descriptionController.text,
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã lưu quy trình thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _dismissWorkflow() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.clearWorkflow();
    _isWorkflowDialogShowing = false;
  }

  void _showWorkflowTemplateSelector(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow more height for content
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        // Use a percentage of screen height
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chọn mẫu quy trình làm việc',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF014D17),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  ...chatProvider.savedWorkflows.map(
                    (workflow) => _buildWorkflowTemplateCard(
                      context,
                      workflow,
                      chatProvider,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildCreateCustomWorkflowCard(context, chatProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowTemplateCard(
    BuildContext context,
    Workflow workflow,
    ChatProvider chatProvider,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              workflow.isCustom ? Colors.blue.shade300 : Colors.grey.shade300,
          width: workflow.isCustom ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              // Apply the selected workflow template
              chatProvider.setWorkflow(workflow);
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          workflow.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF014D17),
                          ),
                        ),
                      ),
                      if (workflow.isCustom)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            'Tùy chỉnh',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (workflow.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        workflow.description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${workflow.steps.length} bước',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                      if (workflow.createdAt != null)
                        Text(
                          'Tạo: ${_formatDateTime(workflow.createdAt!)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (workflow.isCustom)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Chỉnh sửa',
                    onPressed: () => _showEditWorkflowDialog(
                        context, workflow, chatProvider),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Xóa',
                    onPressed: () => _showDeleteWorkflowConfirmation(
                        context, workflow, chatProvider),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Format DateTime to a readable string
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  // Show dialog to confirm workflow deletion
  void _showDeleteWorkflowConfirmation(
    BuildContext context,
    Workflow workflow,
    ChatProvider chatProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xóa quy trình'),
          content: Text(
              'Bạn có chắc chắn muốn xóa quy trình "${workflow.title}" không? Hành động này không thể hoàn tác.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await chatProvider.deleteWorkflow(workflow.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa quy trình'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  // Show dialog to edit a workflow
  void _showEditWorkflowDialog(
    BuildContext context,
    Workflow workflow,
    ChatProvider chatProvider,
  ) {
    final TextEditingController titleController =
        TextEditingController(text: workflow.title);
    final TextEditingController descriptionController =
        TextEditingController(text: workflow.description ?? '');
    final TextEditingController stepsController = TextEditingController(
      text: workflow.steps.join('\n'),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chỉnh sửa quy trình'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  inputFormatters: [VietnameseTextInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Tiêu đề',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  inputFormatters: [VietnameseTextInputFormatter()],
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Text('Các bước', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Mỗi bước trên một dòng:',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                SizedBox(height: 8),
                TextField(
                  controller: stepsController,
                  inputFormatters: [VietnameseTextInputFormatter()],
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Nhập các bước của quy trình',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF014D17),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Create updated workflow
                final steps = stepsController.text
                    .split('\n')
                    .where((step) => step.trim().isNotEmpty)
                    .map((step) => step.trim())
                    .toList();

                if (steps.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Quy trình phải có ít nhất một bước'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final updatedWorkflow = workflow.copyWith(
                  title: titleController.text,
                  description: descriptionController.text,
                  steps: steps,
                );

                chatProvider.updateWorkflow(updatedWorkflow);
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã cập nhật quy trình'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCreateCustomWorkflowCard(
    BuildContext context,
    ChatProvider chatProvider,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade300, width: 2),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _showCreateWorkflowDialog(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.add_circle, color: Colors.blue, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tạo quy trình tùy chỉnh',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tạo quy trình làm việc với các lệnh tùy chỉnh của riêng bạn',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateWorkflowDialog(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    TextEditingController titleController =
        TextEditingController(text: 'Quy trình tùy chỉnh mới');
    TextEditingController descriptionController = TextEditingController(
        text: 'Quy trình tùy chỉnh với các lệnh của riêng tôi');
    TextEditingController workflowController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tạo quy trình tùy chỉnh'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                inputFormatters: [VietnameseTextInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                inputFormatters: [VietnameseTextInputFormatter()],
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              Text('Các bước', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                'Nhập các lệnh quy trình, mỗi lệnh trên một dòng.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              SizedBox(height: 8),
              TextField(
                controller: workflowController,
                inputFormatters: [VietnameseTextInputFormatter()],
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Ví dụ:\nkubectl get pods\nkubectl get services',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF014D17),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              String workflowText = workflowController.text.trim();
              if (workflowText.isNotEmpty) {
                List<String> steps = workflowText
                    .split('\n')
                    .where((step) => step.trim().isNotEmpty)
                    .map((step) => step.trim())
                    .toList();

                if (steps.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Quy trình phải có ít nhất một bước'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Create a new custom workflow
                final newWorkflow = Workflow(
                  title: titleController.text,
                  description: descriptionController.text,
                  steps: steps,
                  isCustom: true,
                  createdAt: DateTime.now(),
                );

                // Save workflow and apply it
                chatProvider.saveWorkflow(newWorkflow);
                chatProvider.setWorkflow(newWorkflow);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã tạo quy trình mới'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Vui lòng nhập các bước cho quy trình'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Tạo quy trình'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _scrollToBottom();
    final chatProvider = Provider.of<ChatProvider>(context);
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tư vấn AI'),
        actions: <Widget>[
          // Thêm dropdown để chọn model AI
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButton<String>(
              value: chatProvider.selectedModel,
              icon: const Icon(Icons.arrow_drop_down),
              elevation: 16,
              underline: Container(
                height: 2,
                color: Colors.purple,
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
                  child: Text(value.toUpperCase()),
                );
              }).toList(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              chatProvider.loadHistory();
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          // Thêm kiểm tra và tải lại token
          if (chatProvider.token == null || chatProvider.token!.isEmpty) {
            print('ChatWidget - Token rỗng hoặc null');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              chatProvider.reloadToken();
            });
          }

          return Column(
            children: [
              // Hiển thị trạng thái đăng nhập (chỉ hiển thị khi đang debug)
              if (chatProvider.token == null || chatProvider.token!.isEmpty)
                Container(
                  color: Colors.red[100],
                  padding: const EdgeInsets.all(8.0),
                  width: double.infinity,
                  child: Text(
                    'Chưa đăng nhập (Token: ${chatProvider.token})',
                    style: TextStyle(color: Colors.red[900]),
                  ),
                ),

              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return ListTile(
                      title: Text(
                        message,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (chatProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),

              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Add workflow template button
                    IconButton(
                      icon: Icon(Icons.playlist_add, color: Color(0xFF014D17)),
                      tooltip: 'Thêm quy trình làm việc',
                      onPressed: () {
                        _showWorkflowTemplateSelector(context);
                      },
                    ),
                    Expanded(
                      child: RawKeyboardListener(
                        focusNode: FocusNode(),
                        onKey: (RawKeyEvent event) {
                          // Chỉ theo dõi, không xử lý
                        },
                        child: TextField(
                          controller: _textController,
                          keyboardType: TextInputType.text,
                          maxLines: 1,
                          textDirection: TextDirection.ltr,
                          // Không sử dụng formatter nào cả
                          inputFormatters: [],
                          // Tăng độ ưu tiên cho đầu vào bàn phím gốc
                          enableInteractiveSelection: true,
                          enableIMEPersonalizedLearning: true,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16.0,
                            // Đảm bảo sử dụng locale tiếng Việt
                            locale: Locale('vi', 'VN'),
                            height: 1.3, // Thêm khoảng cách cho dấu
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nhập tin nhắn...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            isCollapsed: false,
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF014D17), width: 2),
                            ),
                          ),
                          enableSuggestions: true,
                          autocorrect: false,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (text) {
                            if (text.isNotEmpty) {
                              _handleMessage(text);
                            }
                          },
                          onTap: () {
                            // Đảm bảo con trỏ luôn ở cuối văn bản khi tap vào trường nhập liệu
                            _textController.selection =
                                TextSelection.fromPosition(
                              TextPosition(offset: _textController.text.length),
                            );
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: () {
                        final text = _textController.text.trim();
                        if (text.isNotEmpty) {
                          _handleMessage(text);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
