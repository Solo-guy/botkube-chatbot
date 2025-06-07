import 'package:flutter_test/flutter_test.dart';
import '../lib/models/command.dart';

void main() {
  group('Command Model', () {
    test('Command can be created from JSON', () {
      final json = {'command': 'kubectl get pods'};
      final command = Command.fromJson(json);
      expect(command.command, 'kubectl get pods');
    });

    test('Command can be converted to JSON', () {
      final command =
          Command(command: 'kubectl delete pod test-pod', output: '');
      final json = command.toJson();
      expect(json['command'], 'kubectl delete pod test-pod');
    });
  });
}
