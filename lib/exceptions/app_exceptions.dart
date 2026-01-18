/// Base class for all app-specific exceptions
abstract class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Exception thrown when network request fails
class NetworkException extends AppException {
  const NetworkException(super.message);

  factory NetworkException.fromHttpStatus(int statusCode) {
    return NetworkException('Network request failed with status $statusCode');
  }

  factory NetworkException.timeout() {
    return const NetworkException('Network request timed out');
  }

  factory NetworkException.noConnection() {
    return const NetworkException('No internet connection available');
  }
}

/// Exception thrown when data parsing fails
class DataParsingException extends AppException {
  const DataParsingException(super.message, [this.data]);

  final dynamic data;

  @override
  String toString() => 'DataParsingException: $message${data != null ? ' (Data: $data)' : ''}';
}

/// Exception thrown when database operation fails
class DatabaseException extends AppException {
  const DatabaseException(super.message, [this.originalException]);

  final Object? originalException;

  @override
  String toString() => 'DatabaseException: $message${originalException != null ? ' (Caused by: $originalException)' : ''}';
}

/// Exception thrown when storage operation fails
class StorageException extends AppException {
  const StorageException(super.message);

  factory StorageException.notFound(String key) {
    return StorageException('Storage key not found: $key');
  }

  factory StorageException.saveFailed(String key) {
    return StorageException('Failed to save to storage: $key');
  }
}

/// Exception thrown when data validation fails
class ValidationException extends AppException {
  const ValidationException(super.message, [this.field]);

  final String? field;

  @override
  String toString() => 'ValidationException: $message${field != null ? ' (Field: $field)' : ''}';
}

/// Exception thrown when resource is not found
class NotFoundException extends AppException {
  const NotFoundException(super.message);

  factory NotFoundException.booking(String bookingNo) {
    return NotFoundException('Booking not found: $bookingNo');
  }

  factory NotFoundException.resource(String resource) {
    return NotFoundException('Resource not found: $resource');
  }
}

/// Exception thrown when operation is unauthorized
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized access']);
}

/// Exception thrown when authentication fails
class AuthenticationException extends AppException {
  const AuthenticationException(super.message);

  factory AuthenticationException.invalidCredentials() {
    return const AuthenticationException('Invalid email or password');
  }

  factory AuthenticationException.emailAlreadyInUse() {
    return const AuthenticationException('Email is already in use');
  }

  factory AuthenticationException.weakPassword() {
    return const AuthenticationException('Password is too weak');
  }

  factory AuthenticationException.userNotFound() {
    return const AuthenticationException('User not found');
  }
}

/// Exception thrown when configuration is invalid
class ConfigurationException extends AppException {
  const ConfigurationException(super.message);

  factory ConfigurationException.missingEnvVar(String varName) {
    return ConfigurationException('Missing environment variable: $varName');
  }
}

