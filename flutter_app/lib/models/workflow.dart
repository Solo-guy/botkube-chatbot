class Workflow {
  final String id;
  final String title;
  final List<String> steps;
  final bool isVisible;
  final String? description;
  final Map<String, dynamic>? metadata;
  final bool isCustom;
  final DateTime? createdAt;

  Workflow({
    String? id,
    required this.title,
    required this.steps,
    this.isVisible = true,
    this.description,
    this.metadata,
    this.isCustom = false,
    this.createdAt,
  }) : this.id = id ?? _generateId();

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'steps': steps,
      'isVisible': isVisible,
      'description': description,
      'metadata': metadata,
      'isCustom': isCustom,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Workflow.fromJson(Map<String, dynamic> json) {
    return Workflow(
      id: json['id'],
      title: json['title'],
      steps: List<String>.from(json['steps']),
      isVisible: json['isVisible'] ?? true,
      description: json['description'],
      metadata: json['metadata'],
      isCustom: json['isCustom'] ?? false,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Workflow copyWith({
    String? title,
    List<String>? steps,
    bool? isVisible,
    String? description,
    Map<String, dynamic>? metadata,
    bool? isCustom,
  }) {
    return Workflow(
      id: this.id,
      title: title ?? this.title,
      steps: steps ?? this.steps,
      isVisible: isVisible ?? this.isVisible,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      isCustom: isCustom ?? this.isCustom,
      createdAt: this.createdAt,
    );
  }

  factory Workflow.defaultWorkflow() {
    return Workflow(
      title: 'Quy trình làm việc được đề xuất',
      description:
          'Đây là quy trình được AI đề xuất dựa trên phân tích sự kiện hiện tại',
      steps: [
        'Kiểm tra trạng thái pod để đảm bảo không có lỗi nào đang xảy ra',
        'Xem logs của container bên trong Pod, đảm bảo ứng dụng bên trong hoạt động đúng',
        'Xác minh mục đích tạo Pod, đảm bảo rằng Pod được tạo đúng theo ý định, đặc biệt nếu đây là cluster cục bộ ("local"), có thể liên quan đến môi trường phát triển hoặc kiểm thử',
      ],
      isVisible: true,
    );
  }

  factory Workflow.kubernetesDebugging() {
    return Workflow(
      id: 'kubernetes_debugging',
      title: 'Quy trình gỡ lỗi Kubernetes',
      description: 'Các bước chi tiết để gỡ lỗi Pod trong Kubernetes',
      steps: [
        'kubectl get pods -n <namespace> - Liệt kê tất cả các pods trong namespace',
        'kubectl describe pod <pod-name> -n <namespace> - Xem thông tin chi tiết về pod cụ thể',
        'kubectl logs <pod-name> -n <namespace> - Xem logs của pod',
        'kubectl exec -it <pod-name> -n <namespace> -- /bin/bash - Kết nối vào pod để gỡ lỗi trực tiếp',
      ],
      isVisible: true,
      isCustom: false,
    );
  }

  factory Workflow.healthChecks() {
    return Workflow(
      id: 'health_checks',
      title: 'Kiểm tra sức khỏe hệ thống',
      description:
          'Các lệnh quan trọng để đánh giá trạng thái của cụm Kubernetes',
      steps: [
        'kubectl get nodes - Kiểm tra trạng thái của tất cả các nodes',
        'kubectl top nodes - Xem mức sử dụng tài nguyên của các nodes',
        'kubectl get pods -A | grep -v Running - Tìm các pods không ở trạng thái Running',
        'kubectl describe events --sort-by=.metadata.creationTimestamp - Xem các sự kiện gần đây',
      ],
      isVisible: true,
      isCustom: false,
    );
  }

  factory Workflow.fromSuggested(List<String> steps,
      {String? customTitle, String? customDescription}) {
    return Workflow(
      title: customTitle ?? 'Quy trình đã lưu từ AI',
      description:
          customDescription ?? 'Quy trình làm việc được lưu từ đề xuất của AI',
      steps: steps,
      isVisible: true,
      isCustom: true,
      createdAt: DateTime.now(),
    );
  }

  // Create an empty workflow with no steps
  factory Workflow.empty() {
    return Workflow(
      id: '',
      title: '',
      steps: [],
      isVisible: false,
      description: '',
      isCustom: false,
    );
  }
}
