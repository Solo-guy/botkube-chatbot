import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter/widgets.dart';
// No more conditional imports - we'll handle this differently

class AppConfig {
  // Safely access dotenv.env with fallbacks if not initialized
  static Map<String, String> get _env {
    try {
      return dotenv.env;
    } catch (e) {
      print("Error accessing dotenv: $e");
      return {};
    }
  }

  static String get serverIp => _env['SERVER_IP'] ?? 'localhost';

  static String get apiUrl {
    // Safe fallback if API_URL is not set
    if (_env['API_URL'] == null) {
      return 'http://${serverIp}:8080';
    }
    return _env['API_URL']!;
  }

  static String get wsUrl {
    // Safe fallback if WS_URL is not set
    if (_env['WS_URL'] == null) {
      return 'ws://${serverIp}:8080/ws';
    }
    return _env['WS_URL']!;
  }

  static int get apiTimeout {
    return int.tryParse(_env['API_TIMEOUT'] ?? '120000') ?? 120000;
  }

  static String get defaultUsername {
    return _env['DEFAULT_USERNAME'] ?? 'user1';
  }

  static bool get debugMode {
    return _env['DEBUG_MODE']?.toLowerCase() == 'true';
  }

  // Platform detection helpers
  static bool get isMobile {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      // If we can't determine platform, assume it's not mobile
      print("Error determining if platform is mobile: $e");
      return false;
    }
  }

  static bool get isDesktop {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (e) {
      print("Error determining if platform is desktop: $e");
      return false;
    }
  }

  static bool get isWeb => kIsWeb;

  // Check if current platform is mobile (iOS or Android)
  static bool get isMobileDevice {
    // First check for debug override
    if (_env.containsKey('FORCE_MOBILE_MODE')) {
      print("Using forced mobile mode: ${_env['FORCE_MOBILE_MODE']}");
      return _env['FORCE_MOBILE_MODE'] == 'true';
    }

    // For web platform, use more reliable detection
    if (kIsWeb) {
      try {
        // Check screen size for mobile detection on web
        final window = WidgetsBinding.instance?.window;
        if (window == null) {
          print("Window instance is null, defaulting to desktop mode");
          return false;
        }

        final windowWidth = window.physicalSize.width;
        final devicePixelRatio = window.devicePixelRatio;
        final logicalWidth = windowWidth / devicePixelRatio;

        // Use screen width as the primary detection method on web
        // Under 600px is commonly considered a mobile breakpoint
        final isMobileDevice = logicalWidth < 600;

        print(
            "Web platform detected as: ${isMobileDevice ? 'mobile' : 'desktop'}");
        print("Screen width: $logicalWidth");

        return isMobileDevice;
      } catch (e) {
        print("Error checking device type for web: $e");
        // Default to desktop if detection fails on web
        return false;
      }
    }

    // For native platforms, use direct platform detection
    try {
      final isMobile = Platform.isAndroid || Platform.isIOS;
      print(
          "Platform detected as${isMobile ? ' ' : ' not '}mobile: ${Platform.operatingSystem}");
      return isMobile;
    } catch (e) {
      print("Error detecting native platform: $e");
      return false;
    }
  }

  // API timeouts based on platform
  static Duration get requestTimeout {
    // Use longer timeout for mobile platforms that may have slower connections
    return isMobileDevice
        ? Duration(seconds: 240) // 4 minutes for mobile
        : Duration(seconds: 180); // 3 minutes for desktop/web
  }

  // Specific timeout for Kubernetes commands
  static Duration get kubernetesCommandTimeout {
    return Duration(seconds: 300); // 5 minutes timeout for k8s commands
  }

  // Model-specific timeouts (in seconds)
  static const Map<String, int> aiModelTimeouts = {
    'grok': 60, // Increase from default 30s to 60s
    'azure': 30,
    'openai': 45,
    'gemini': 30,
    'claude': 45,
  };

  // Get timeout for a specific AI model
  static Duration getAiModelTimeout(String model) {
    final lowerModel = model.toLowerCase();
    // Default to 30 seconds if model not found
    final seconds = aiModelTimeouts[lowerModel] ?? 30;
    return Duration(seconds: seconds);
  }
}
