import 'dart:developer' as developer;

class Logger {
  Logger._();

  static void info(String message) {
    developer.log('INFO: $message', name: 'MicroGoals');
  }

  static void warning(String message) {
    developer.log('WARNING: $message', name: 'MicroGoals');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      'ERROR: $message',
      name: 'MicroGoals',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

