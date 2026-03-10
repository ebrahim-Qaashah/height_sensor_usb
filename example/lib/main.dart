import 'package:flutter/material.dart';
import 'package:height_sensor_usb/height_sensor_usb.dart';
import 'package:usb_serial/usb_serial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Height Sensor USB Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HeightSensorDemo(),
    );
  }
}

class HeightSensorDemo extends StatefulWidget {
  const HeightSensorDemo({super.key});

  @override
  State<HeightSensorDemo> createState() => _HeightSensorDemoState();
}

class _HeightSensorDemoState extends State<HeightSensorDemo> {
  HeightSensorUsb? _sensor;
  List<UsbDevice> _availableDevices = [];
  HeightMeasurement? _currentMeasurement;
  SensorInfo? _sensorInfo;
  String _status = 'Initializing...';
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _initializeSensor();
  }

  Future<void> _initializeSensor() async {
    try {
      setState(() => _status = 'Creating sensor service...');
      _sensor = await HeightSensorUsb.create();
      
      // Listen to status changes
      _sensor!.statusStream.listen((status) {
        setState(() {
          _status = status.description;
        });
      });
      
      // Listen to measurements
      _sensor!.measurementStream.listen((measurement) {
        setState(() {
          _currentMeasurement = measurement;
        });
      });
      
      await _refreshDevices();
      setState(() => _status = 'Ready');
      
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _refreshDevices() async {
    if (_sensor == null) return;
    
    try {
      final devices = await _sensor!.getAvailableDevices();
      setState(() {
        _availableDevices = devices;
      });
    } catch (e) {
      setState(() => _status = 'Error finding devices: $e');
    }
  }

  Future<void> _connectToDevice(UsbDevice device) async {
    if (_sensor == null) return;
    
    setState(() {
      _isConnecting = true;
      _status = 'Connecting...';
    });
    
    try {
      final success = await _sensor!.connect(device);
      if (success) {
        // Get sensor info
        try {
          _sensorInfo = await _sensor!.getSensorInfo();
        } catch (e) {
          // Info might not be available, that's okay
        }
      }
    } catch (e) {
      setState(() => _status = 'Connection failed: $e');
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnect() async {
    if (_sensor == null) return;
    
    try {
      await _sensor!.disconnect();
      setState(() {
        _currentMeasurement = null;
        _sensorInfo = null;
      });
    } catch (e) {
      setState(() => _status = 'Disconnect error: $e');
    }
  }

  Future<void> _readSingleMeasurement() async {
    if (_sensor == null) return;
    
    try {
      final measurement = await _sensor!.readSingleMeasurement();
      setState(() {
        _currentMeasurement = measurement;
      });
    } catch (e) {
      setState(() => _status = 'Read error: $e');
    }
  }

  Future<void> _resetSensor() async {
    if (_sensor == null) return;
    
    try {
      await _sensor!.resetSensor();
      setState(() => _status = 'Sensor reset');
    } catch (e) {
      setState(() => _status = 'Reset error: $e');
    }
  }

  @override
  void dispose() {
    _sensor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Height Sensor USB Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                        ),
                        const SizedBox(width: 8),
                        Text(_status),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Device Selection
            if (_availableDevices.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Devices',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ..._availableDevices.map((device) => ListTile(
                        title: Text(device.productName ?? 'Unknown Device'),
                        subtitle: Text('VID: 0x${device.vid.toRadixString(16).padLeft(4, '0')}'),
                        trailing: ElevatedButton(
                          onPressed: _isConnecting ? null : () => _connectToDevice(device),
                          child: Text(_isConnecting ? 'Connecting...' : 'Connect'),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Measurement Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Height Measurement',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_currentMeasurement != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Distance: ${_currentMeasurement!.distanceCm.toStringAsFixed(2)} cm',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Raw: ${_currentMeasurement!.distanceMm} mm',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (_currentMeasurement!.isValid)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Valid',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            )
                          else
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _currentMeasurement?.error ?? 'Invalid',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                        ],
                      )
                    else
                      const Text('No measurement available'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Sensor Info
            if (_sensorInfo != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sensor Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Device: ${_sensorInfo!.deviceName}'),
                      Text('Version: ${_sensorInfo!.version}'),
                      Text('Sensor: ${_sensorInfo!.sensorType}'),
                    ],
                  ),
                ),
              ),
            
            const Spacer(),
            
            // Control Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sensor?.connectionStatus.isConnected == true 
                        ? _readSingleMeasurement 
                        : null,
                    child: const Text('Read Single'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sensor?.connectionStatus.isConnected == true 
                        ? _resetSensor 
                        : null,
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sensor?.connectionStatus.isConnected == true 
                        ? _disconnect 
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Disconnect'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (_sensor?.connectionStatus) {
      case ConnectionStatus.connected:
        return Icons.bluetooth_connected;
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
        return Icons.bluetooth_searching;
      case ConnectionStatus.error:
        return Icons.error;
      default:
        return Icons.bluetooth_disabled;
    }
  }

  Color _getStatusColor() {
    switch (_sensor?.connectionStatus) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
        return Colors.orange;
      case ConnectionStatus.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
