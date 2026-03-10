/// Command protocol for height sensor communication
class CommandProtocol {
  /// Get sensor information
  static const String info = 'INFO';
  
  /// Read single measurement
  static const String read = 'READ';
  
  /// Reset sensor
  static const String reset = 'RESET';
  
  /// Start continuous measurements
  static const String startContinuous = 'START';
  
  /// Stop continuous measurements
  static const String stopContinuous = 'STOP';
  
  /// Set measurement interval
  static const String setInterval = 'INTERVAL';
  
  /// Get sensor status
  static const String status = 'STATUS';
  
  /// All available commands
  static const List<String> allCommands = [
    info,
    read,
    reset,
    startContinuous,
    stopContinuous,
    setInterval,
    status,
  ];
  
  /// Validate command
  static bool isValidCommand(String command) {
    return allCommands.contains(command.toUpperCase());
  }
  
  /// Format command with parameters
  static String formatCommand(String command, {String? parameter}) {
    final cmd = command.toUpperCase();
    if (parameter != null && parameter.isNotEmpty) {
      return '$cmd $parameter';
    }
    return cmd;
  }
  
  /// Parse command from string
  static String? parseCommand(String input) {
    final parts = input.trim().split(' ');
    if (parts.isEmpty) return null;
    
    final command = parts[0].toUpperCase();
    return isValidCommand(command) ? command : null;
  }
  
  /// Parse parameter from command string
  static String? parseParameter(String input) {
    final parts = input.trim().split(' ');
    if (parts.length <= 1) return null;
    
    return parts.sublist(1).join(' ');
  }
}

/// Response types from sensor
enum ResponseType {
  measurement,
  info,
  status,
  error,
  read,
  unknown,
}

/// Response parser
class ResponseParser {
  /// Parse response type from JSON string
  static ResponseType parseResponseType(String jsonString) {
    try {
      if (jsonString.contains('"measurement"')) {
        return ResponseType.measurement;
      } else if (jsonString.contains('"info"')) {
        return ResponseType.info;
      } else if (jsonString.contains('"status"')) {
        return ResponseType.status;
      } else if (jsonString.contains('"read"')) {
        return ResponseType.read;
      } else if (jsonString.contains('"error"')) {
        return ResponseType.error;
      } else {
        return ResponseType.unknown;
      }
    } catch (e) {
      return ResponseType.unknown;
    }
  }
  
  /// Check if response is a valid JSON
  static bool isValidJson(String jsonString) {
    try {
      jsonString.trim();
      return jsonString.startsWith('{') && jsonString.endsWith('}');
    } catch (e) {
      return false;
    }
  }
  
  /// Extract measurement from response
  static Map<String, dynamic>? extractMeasurement(String jsonString) {
    try {
      final type = parseResponseType(jsonString);
      if (type == ResponseType.measurement || type == ResponseType.read) {
        // This would be parsed by the models, just validation here
        return {'valid': true};
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }
}
