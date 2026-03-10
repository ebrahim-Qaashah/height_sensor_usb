# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-03-10

### Added
- Initial release of height_sensor_usb package
- USB serial communication with ESP32-C3 devices
- Real-time height measurement streaming
- JSON-based communication protocol
- Device auto-discovery for ESP32 devices (VID: 0x303A)
- Type-safe models for measurements and sensor info
- Comprehensive error handling with custom exceptions
- Connection status monitoring
- Command protocol (INFO, READ, RESET, START, STOP, INTERVAL, STATUS)
- Example Flutter application
- Complete documentation and setup instructions
- ESP32 firmware with USB CDC support
- Android USB host permissions configuration

### Features
- **Easy Integration**: Simple API for Flutter developers
- **Real-time Data**: Stream-based measurement updates
- **Type Safety**: Strongly typed models and responses
- **Error Handling**: Comprehensive exception management
- **Device Management**: Automatic device discovery and connection
- **Protocol Support**: JSON-based command/response system
- **Cross-platform**: Android USB host support

### Documentation
- Complete API reference
- Setup instructions for hardware and software
- Example application demonstrating all features
- Troubleshooting guide
- License and contribution guidelines
