import 'package:flutter_test/flutter_test.dart';
import '../lib/models/event.dart';

void main() {
  group('Event Model', () {
    test('Event can be created from JSON', () {
      final json = {
        'type': 'create',
        'resource': 'pod',
        'name': 'test-pod',
        'namespace': 'default',
        'cluster': 'test-cluster'
      };
      final event = Event.fromJson(json);
      expect(event.type, 'create');
      expect(event.resource, 'pod');
      expect(event.name, 'test-pod');
      expect(event.namespace, 'default');
      expect(event.cluster, 'test-cluster');
    });

    test('Event can be converted to JSON', () {
      final event = Event(
          type: 'delete',
          resource: 'deployment',
          name: 'test-deployment',
          namespace: 'kube-system',
          cluster: 'prod-cluster');
      final json = event.toJson();
      expect(json['type'], 'delete');
      expect(json['resource'], 'deployment');
      expect(json['name'], 'test-deployment');
      expect(json['namespace'], 'kube-system');
      expect(json['cluster'], 'prod-cluster');
    });
  });
}
