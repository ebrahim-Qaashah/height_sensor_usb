import 'dart:async';
import 'dart:convert';
import 'package:usb_serial/usb_serial.dart';
import '../models/height_measurement.dart';
import '../models/sensor_info.dart';
import '../exceptions/height_sensor_exception.dart';
import '../services/command_protocol.dart';
import '../services/usb_connection_service.dart';

/// Service for managing height sensor operations
class HeightSensorService {
  final UsbConnectionService _connection;
  final StreamController<HeightMeasurement> _measurementController = 
      StreamController<HeightMeasurement>.broadcast();
  
  /// Subscription to connection data stream
  StreamSubscription<String>? _dataSubscription;
  
  /// Buffer for incomplete JSON data
  String _dataBuffer = '';
  
  HeightSensorService(this._connection) {
    _dataSubscription = _connection.dataStream.listen(_parseIncomingData);
  }
  
  /// Stream of height measurements
  Stream<HeightMeasurement> get measurementStream => _measurementController.stream;
  
  /// Parse incoming data from USB connection
  void _parseIncomingData(String data) {
    try {
      // Add new data to buffer
      _dataBuffer += data;
      
      // Split by newlines to handle multiple JSON objects
      final lines = _dataBuffer.split('\n');
      
      // Process all complete lines except the last one (might be incomplete)
      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isNotEmpty) {
          _processJsonLine(line);
        }
      }
      
      // Keep the last line (might be incomplete)
      _dataBuffer = lines.last.trim();
      
    } catch (e) {
      _measurementController.add(
        HeightMeasurement.error('Data parsing error: $e')
      );
    }
  }
  
  /// Process a single JSON line
  void _processJsonLine(String line) {
    try {
      // Check if it's valid JSON
      if (!ResponseParser.isValidJson(line)) {
        // Handle non-JSON responses (like status messages)
        if (line.contains('ready') || line.contains('status')) {
          // Device is ready, no measurement to process
          return;
        }
        return;
      }
      
      final Map<String, dynamic> json = jsonDecode(line);
      
      // Handle different response types
      if (json.containsKey('measurement')) {
        final measurement = HeightMeasurement.fromJson(json['measurement']);
        _measurementController.add(measurement);
      } else if (json.containsKey('read')) {
        final measurement = HeightMeasurement.fromJson(json['read']);
        _measurementController.add(measurement);
      } else if (json.containsKey('error')) {
        final error = json['error'] as String;
        _measurementController.add(HeightMeasurement.error(error));
      }
      
    } catch (e) {
      _measurementController.add(
        HeightMeasurement.error('JSON parsing error: $e')
      );
    }
  }
  
  /// Read a single measurement on demand
  Future<HeightMeasurement> readSingleMeasurement() async {
    try {
      await _connection.sendCommand(CommandProtocol.read);
      
      // Wait for measurement response
      return await measurementStream.firstWhere(
        (measurement) => measurement.isValid || measurement.error != null,
        orElse: () => HeightMeasurement.timeout(),
      ).timeout(
        Duration(seconds: 5),
        onTimeout: () => HeightMeasurement.timeout(),
      );
      
    } catch (e) {
      throw HeightSensorException('Failed to read measurement: $e');
    }
  }
  
  /// Get sensor information
  Future<SensorInfo> getSensorInfo() async {
    try {
      await _connection.sendCommand(CommandProtocol.info);
      
      // Wait for info response
      final completer = Completer<SensorInfo>();
      StreamSubscription? subscription;
      
      subscription = measurementStream.listen((measurement) {
        // This is a workaround - we need to parse the raw data for info
        // In a real implementation, you'd have a separate info stream
      });
      
      // For now, return default info
      subscription?.cancel();
      return SensorInfo(
        deviceName: 'Smat Minds Height Meter',
        version: '1.0',
        sensorType: 'VL53L0X',
      );
      
    } catch (e) {
      throw HeightSensorException('Failed to get sensor info: $e');
    }
  }
  
  /// Reset the sensor
  Future<void> reset() async {
    try {
      await _connection.sendCommand(CommandProtocol.reset);
    } catch (e) {
      throw HeightSensorException('Failed to reset sensor: $e');
    }
  }
  
  /// Start continuous measurements
  Future<void> startContinuous() async {
    try {
      await _connection.sendCommand(CommandProtocol.startContinuous);
    } catch (e) {
      throw HeightSensorException('Failed to start continuous measurements: $e');
    }
  }
  
  /// Stop continuous measurements
  Future<void> stopContinuous() async {
    try {
      await _connection.sendCommand(CommandProtocol.stopContinuous);
    } catch (e) {
      throw HeightSensorException('Failed to stop continuous measurements: $e');
    }
  }
  
  /// Set measurement interval
  Future<void> setInterval(int intervalMs) async {
    try {
      final command = '${CommandProtocol.setInterval} $intervalMs';
      await _connection.sendCommand(command);
    } catch (e) {
      throw HeightSensorException('Failed to set interval: $e');
    }
  }
  
  /// Get sensor status
  Future<String> getStatus() async {
    try {
      await _connection.sendCommand(CommandProtocol.status);
      // This would need a separate status stream in a real implementation
      return 'Unknown';
    } catch (e) {
      throw HeightSensorException('Failed to get status: $e');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _dataSubscription?.cancel();
    _measurementController.close();
  }
}
