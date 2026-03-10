/// Connection status enum for USB sensor
enum ConnectionStatus {
  /// Disconnected from sensor
  disconnected,
  
  /// Connecting to sensor
  connecting,
  
  /// Connected to sensor
  connected,
  
  /// Connection error
  error,
  
  /// Reconnecting to sensor
  reconnecting,
}

/// Extension methods for ConnectionStatus
extension ConnectionStatusExtension on ConnectionStatus {
  /// Get human-readable status description
  String get description {
    switch (this) {
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.error:
        return 'Connection Error';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting...';
    }
  }
  
  /// Check if status indicates an active connection
  bool get isConnected {
    return this == ConnectionStatus.connected;
  }
  
  /// Check if status indicates a connection attempt
  bool get isConnecting {
    return this == ConnectionStatus.connecting || 
           this == ConnectionStatus.reconnecting;
  }
  
  /// Check if status indicates an error state
  bool get hasError {
    return this == ConnectionStatus.error;
  }
}
