import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import '../models/connection_status.dart';
import '../exceptions/height_sensor_exception.dart';

/// Service for managing USB serial connection to height sensor
class UsbConnectionService {
  UsbPort? _port;
  final StreamController<String> _dataController = StreamController<String>.broadcast();
  final StreamController<ConnectionStatus> _statusController = 
      StreamController<ConnectionStatus>.broadcast();
  
  /// Stream of incoming data from USB
  Stream<String> get dataStream => _dataController.stream;
  
  /// Stream of connection status changes
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  
  /// Current connection status
  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;
  
  /// Connect to USB device
  Future<bool> connect(UsbDevice device) async {
    try {
      _updateStatus(ConnectionStatus.connecting);
      
      // Create and open port
      _port = await device.create();
      if (_port == null) {
        throw ConnectionException('Failed to create USB port');
      }
      
      final opened = await _port!.open();
      if (!opened) {
        throw ConnectionException('Failed to open USB port');
      }
      
      // Configure port parameters
      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        115200, // Baud rate
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
      
      // Start listening for data
      _port!.inputStream?.listen(
        (data) {
          final String text = String.fromCharCodes(data);
          _dataController.add(text);
        },
        onError: (error) {
          _updateStatus(ConnectionStatus.error);
          _dataController.addError(ConnectionException('Data stream error: $error'));
        },
        onDone: () {
          _updateStatus(ConnectionStatus.disconnected);
        },
      );
      
      _updateStatus(ConnectionStatus.connected);
      return true;
      
    } catch (e) {
      _updateStatus(ConnectionStatus.error);
      throw ConnectionException('Connection failed: $e', originalException: e as Exception);
    }
  }
  
  /// Send command to device
  Future<void> sendCommand(String command) async {
    if (_port == null) {
      throw HeightSensorException('Not connected to device');
    }
    
    if (_status != ConnectionStatus.connected) {
      throw HeightSensorException('Device not ready for commands');
    }
    
    try {
      final commandData = Uint8List.fromList('$command\n'.codeUnits);
      await _port!.write(commandData);
    } catch (e) {
      throw HeightSensorException('Failed to send command: $command');
    }
  }
  
  /// Send raw data to device
  Future<void> sendRawData(Uint8List data) async {
    if (_port == null) {
      throw HeightSensorException('Not connected to device');
    }
    
    if (_status != ConnectionStatus.connected) {
      throw HeightSensorException('Device not ready for data transmission');
    }
    
    try {
      await _port!.write(data);
    } catch (e) {
      throw HeightSensorException('Failed to send data: $e');
    }
  }
  
  /// Check if connected
  bool get isConnected => _status == ConnectionStatus.connected;
  
  /// Get device info if connected
  Map<String, dynamic>? getDeviceInfo() {
    if (_port == null) return null;
    
    return {
      'vid': _port!.vid,
      'pid': _port!.pid,
      'productName': _port!.productName,
      'serialNumber': _port!.serialNumber,
    };
  }
  
  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      _updateStatus(ConnectionStatus.disconnected);
      
      if (_port != null) {
        await _port!.close();
        _port = null;
      }
    } catch (e) {
      // Ignore disconnect errors
    }
  }
  
  /// Update connection status
  void _updateStatus(ConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }
  
  /// Dispose resources
  void dispose() {
    _dataController.close();
    _statusController.close();
    disconnect();
  }
}
