import 'package:flutter/services.dart';

/// A text input formatter that maintains Vietnamese characters
/// This formatter ensures that Vietnamese characters with diacritical
/// marks are properly handled during text input
class VietnameseTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Simply return the new value without modifying it
    // This is a placeholder implementation that doesn't interfere with Vietnamese input
    return newValue;
  }
}
