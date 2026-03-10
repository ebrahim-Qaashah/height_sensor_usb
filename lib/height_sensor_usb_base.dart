import 'dart:async';
import 'package:usb_serial/usb_serial.dart';
import 'src/services/usb_connection_service.dart';
import 'src/services/height_sensor_service.dart';
import 'src/models/connection_status.dart';
import 'src/models/height_measurement.dart';
import 'src/models/sensor_info.dart';
import 'src/exceptions/height_sensor_exception.dart';

/// Main class for USB height sensor communication
class HeightSensorUsb {
  UsbConnectionService? _connectionService;
  HeightSensorService? _sensorService;
  
  /// Current connection status
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  
  /// Stream controller for connection status changes
  final StreamController<ConnectionStatus> _statusController = 
      StreamController<ConnectionStatus>.broadcast();
  
  /// Creates an instance of HeightSensorUsb
  HeightSensorUsb._();
  
  /// Factory constructor to create and initialize the sensor
  static Future<HeightSensorUsb> create() async {
    final sensor = HeightSensorUsb._();
    await sensor._initialize();
    return sensor;
  }
  
  /// Initialize the sensor services
  Future<void> _initialize() async {
    _connectionService = UsbConnectionService();
    _sensorService = HeightSensorService(_connectionService!);
    
    // Listen to connection status changes
    _connectionService!.statusStream.listen((status) {
      _connectionStatus = status;
      _statusController.add(status);
    });
  }
  
  /// Get available USB devices that could be height sensors
  Future<List<UsbDevice>> getAvailableDevices() async {
    if (_connectionService == null) {
      throw HeightSensorException('Service not initialized');
    }
    
    final devices = await UsbSerial.listDevices();
    
    // Filter for ESP32 devices (VID: 0x303A for Espressif)
    return devices.where((device) => device.vid == 0x303A).toList();
  }
  
  /// Connect to a specific USB device
  Future<bool> connect(UsbDevice device) async {
    if (_connectionService == null) {
      throw HeightSensorException('Service not initialized');
    }
    
    try {
      final success = await _connectionService!.connect(device);
      if (success) {
        // Wait for sensor to be ready
        await Future.delayed(Duration(milliseconds: 1500));
      }
      return success;
    } catch (e) {
      throw HeightSensorException('Failed to connect: $e');
    }
  }
  
  /// Stream of height measurements
  Stream<HeightMeasurement> get measurementStream {
    if (_sensorService == null) {
      throw HeightSensorException('Service not initialized');
    }
    return _sensorService!.measurementStream;
  }
  
  /// Read a single measurement on demand
  Future<HeightMeasurement> readSingleMeasurement() async {
    if (_sensorService == null) {
      throw HeightSensorException('Service not initialized');
    }
    return await _sensorService!.readSingleMeasurement();
  }
  
  /// Get sensor information
  Future<SensorInfo> getSensorInfo() async {
    if (_sensorService == null) {
      throw HeightSensorException('Service not initialized');
    }
    return await _sensorService!.getSensorInfo();
  }
  
  /// Reset the sensor
  Future<void> resetSensor() async {
    if (_connectionService == null) {
      throw HeightSensorException('Service not initialized');
    }
    await _connectionService!.sendCommand('RESET');
  }
  
  /// Disconnect from the sensor
  Future<void> disconnect() async {
    if (_connectionService != null) {
      await _connectionService!.disconnect();
    }
  }
  
  /// Current connection status
  ConnectionStatus get connectionStatus => _connectionStatus;
  
  /// Stream of connection status changes
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  
  /// Dispose resources
  void dispose() {
    _statusController.close();
    disconnect();
  }
}
