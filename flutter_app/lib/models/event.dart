class Event {
  final String type;
  final String resource;
  final String name;
  final String namespace;
  final String cluster;

  Event({
    required this.type,
    required this.resource,
    required this.name,
    required this.namespace,
    required this.cluster,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? '';
    final resource = json['resource']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final namespace = json['namespace']?.toString() ?? '';
    final cluster = json['cluster']?.toString() ?? '';

    return Event(
      type: type,
      resource: resource,
      name: name,
      namespace: namespace,
      cluster: cluster,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'resource': resource,
        'name': name,
        'namespace': namespace,
        'cluster': cluster,
      };
}
