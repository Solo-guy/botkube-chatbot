class ApiResponse {
  final bool success;
  final String response;
  final List<String>? workflow;
  final String? error;

  ApiResponse({
    required this.success,
    this.response = '',
    this.workflow,
    this.error,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      response: (json['response'] ?? '').toString(),
      workflow: json['workflow'] != null
          ? List<String>.from(json['workflow'].map((x) => x.toString()))
          : null,
      error: json['error']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'response': response,
        'workflow': workflow,
        'error': error,
      };
}
