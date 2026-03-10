/// Custom exception for height sensor operations
class HeightSensorException implements Exception {
  /// Error message
  final String message;
  
  /// Optional error code
  final String? code;
  
  /// Optional original exception
  final Exception? originalException;
  
  HeightSensorException(this.message, {this.code, this.originalException});
  
  @override
  String toString() {
    if (code != null) {
      return 'HeightSensorException[$code]: $message';
    }
    return 'HeightSensorException: $message';
  }
}

/// Specific exception types
class ConnectionException extends HeightSensorException {
  ConnectionException(String message, {Exception? originalException})
      : super(message, code: 'CONNECTION_ERROR', originalException: originalException);
}

class DataParsingException extends HeightSensorException {
  DataParsingException(String message, {Exception? originalException})
      : super(message, code: 'PARSING_ERROR', originalException: originalException);
}

class DeviceNotFoundException extends HeightSensorException {
  DeviceNotFoundException(String message)
      : super(message, code: 'DEVICE_NOT_FOUND');
}

class CommandTimeoutException extends HeightSensorException {
  CommandTimeoutException(String command)
      : super('Command timeout: $command', code: 'COMMAND_TIMEOUT');
}

class SensorNotReadyException extends HeightSensorException {
  SensorNotReadyException(String message)
      : super(message, code: 'SENSOR_NOT_READY');
}
