class AppException implements Exception {
  final String message;
  final dynamic originalError;

  AppException(this.message, [this.originalError]);

  @override
  String toString() => 'AppException: $message ${originalError ?? ""}';
}

class AppDatabaseException extends AppException {
  AppDatabaseException(super.message, [super.originalError]);
}

class RepositoryException extends AppException {
  RepositoryException(super.message, [super.originalError]);
}

