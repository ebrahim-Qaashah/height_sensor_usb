# Height Sensor USB Package

A Flutter package for USB serial communication with VL53L0X height sensor devices.

## Features

- 🚀 Easy USB connection to ESP32-C3 based height sensors
- 📊 Real-time height measurement streaming
- 📱 Android USB host support
- 🛡️ Type-safe models and error handling
- 🔄 Automatic device discovery
- 📝 JSON-based communication protocol

## Requirements

- Flutter SDK >= 3.0.0
- Android device with USB OTG support
- ESP32-C3 height sensor with USB support
- USB-C cable for connection

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  height_sensor_usb:
    git: https://github.com/your-repo/height_sensor_usb.git
```

## Android Setup

Add USB permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-feature android:name="android.hardware.usb.host" />
<uses-permission android:name="android.permission.USB_PERMISSION" />
```

## Usage

### Basic Usage

```dart
import 'package:height_sensor_usb/height_sensor_usb.dart';

class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  HeightSensorUsb? _sensor;
  HeightMeasurement? _currentMeasurement;

  @override
  void initState() {
    super.initState();
    _initializeSensor();
  }

  Future<void> _initializeSensor() async {
    try {
      // Create sensor instance
      _sensor = await HeightSensorUsb.create();
      
      // Get available devices
      final devices = await _sensor!.getAvailableDevices();
      
      if (devices.isNotEmpty) {
        // Connect to first device
        await _sensor!.connect(devices.first);
        
        // Listen to measurements
        _sensor!.measurementStream.listen((measurement) {
          setState(() {
            _currentMeasurement = measurement;
          });
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Height: ${_currentMeasurement?.distanceCm.toStringAsFixed(2) ?? 'N/A'} cm'),
            Text('Status: ${_currentMeasurement?.isValid ?? false ? 'Valid' : 'Invalid'}'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sensor?.dispose();
    super.dispose();
  }
}
```

### Advanced Usage

```dart
// Read single measurement
final measurement = await sensor.readSingleMeasurement();

// Get sensor information
final info = await sensor.getSensorInfo();
print('Device: ${info.deviceName}');
print('Version: ${info.version}');

// Reset sensor
await sensor.resetSensor();

// Monitor connection status
sensor.statusStream.listen((status) {
  print('Connection status: ${status.description}');
});
```

## Hardware Setup

### ESP32-C3 Configuration

Your ESP32-C3 needs to be configured with USB CDC support. Add these flags to your `platformio.ini`:

```ini
build_flags = 
    -DARDUINO_USB_MODE=1
    -DARDUINO_USB_CDC_ON_BOOT=1
```

### Firmware Protocol

The package expects JSON responses in this format:

```json
{
  "measurement": {
    "distance_cm": 15.23,
    "distance_mm": 1523,
    "timestamp": 1640995200000,
    "is_valid": true
  }
}
```

### Supported Commands

- `INFO` - Get sensor information
- `READ` - Read single measurement
- `RESET` - Reset the sensor
- `STATUS` - Get connection status

## API Reference

### HeightSensorUsb

Main class for sensor communication.

#### Methods

- `HeightSensorUsb.create()` - Create and initialize sensor
- `getAvailableDevices()` - Get list of available USB devices
- `connect(UsbDevice device)` - Connect to specific device
- `disconnect()` - Disconnect from sensor
- `readSingleMeasurement()` - Read one measurement
- `getSensorInfo()` - Get sensor information
- `resetSensor()` - Reset the sensor

#### Streams

- `measurementStream` - Stream of height measurements
- `statusStream` - Stream of connection status changes

#### Properties

- `connectionStatus` - Current connection status

### Models

#### HeightMeasurement

```dart
class HeightMeasurement {
  final double distanceCm;      // Distance in centimeters
  final int distanceMm;          // Distance in millimeters
  final int timestamp;           // Measurement timestamp
  final bool isValid;            // Whether measurement is valid
  final String? error;           // Error message if invalid
}
```

#### SensorInfo

```dart
class SensorInfo {
  final String deviceName;       // Device name
  final String version;          // Firmware version
  final String sensorType;       // Sensor type (VL53L0X)
  final String? deviceId;        // Device ID (optional)
}
```

#### ConnectionStatus

```dart
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
  reconnecting,
}
```

## Error Handling

The package provides specific exception types:

- `ConnectionException` - USB connection errors
- `DataParsingException` - JSON parsing errors
- `DeviceNotFoundException` - No device found
- `CommandTimeoutException` - Command timeout
- `SensorNotReadyException` - Sensor not ready

```dart
try {
  await sensor.connect(device);
} on ConnectionException catch (e) {
  print('Connection failed: $e');
} on HeightSensorException catch (e) {
  print('Sensor error: $e');
}
```

## Example App

See the `example/` directory for a complete Flutter app demonstrating all features.

## Troubleshooting

### Device Not Found

- Ensure ESP32-C3 is properly connected via USB
- Check that Android device supports USB OTG
- Verify USB permissions are granted

### Connection Errors

- Make sure ESP32-C3 firmware has USB CDC enabled
- Check baud rate compatibility (115200)
- Ensure device is not already in use

### Measurement Errors

- Check sensor wiring (VL53L0X connections)
- Verify sensor is powered (3.3V)
- Ensure I2C pull-up resistors are present

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and questions, please use the GitHub issue tracker.
