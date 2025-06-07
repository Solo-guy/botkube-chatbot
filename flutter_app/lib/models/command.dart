class Command {
  final String command;
  final String output;
  final String? error;

  Command({required this.command, required this.output, this.error});

  factory Command.fromJson(Map<String, dynamic> json) {
    return Command(
      command: json['command'] ?? '',
      output: json['output'] ?? '',
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() => {
        'command': command,
        'output': output,
        'error': error,
      };
}
