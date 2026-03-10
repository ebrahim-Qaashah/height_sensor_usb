import 'package:json_annotation/json_annotation.dart';

part 'sensor_info.g.dart';

/// Model representing sensor information
@JsonSerializable()
class SensorInfo {
  /// Device name
  @JsonKey(name: 'name')
  final String deviceName;
  
  /// Firmware version
  @JsonKey(name: 'version')
  final String version;
  
  /// Sensor type
  @JsonKey(name: 'sensor')
  final String sensorType;
  
  /// Device ID (if available)
  @JsonKey(name: 'device_id')
  final String? deviceId;
  
  /// Manufacturer
  @JsonKey(name: 'manufacturer')
  final String? manufacturer;
  
  /// Model
  @JsonKey(name: 'model')
  final String? model;
  
  SensorInfo({
    required this.deviceName,
    required this.version,
    required this.sensorType,
    this.deviceId,
    this.manufacturer,
    this.model,
  });
  
  /// Create SensorInfo from JSON
  factory SensorInfo.fromJson(Map<String, dynamic> json) =>
      _$SensorInfoFromJson(json);
  
  /// Convert SensorInfo to JSON
  Map<String, dynamic> toJson() => _$SensorInfoToJson(this);
  
  @override
  String toString() {
    return 'SensorInfo(name: $deviceName, version: $version, sensor: $sensorType)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SensorInfo &&
        other.deviceName == deviceName &&
        other.version == version &&
        other.sensorType == sensorType &&
        other.deviceId == deviceId &&
        other.manufacturer == manufacturer &&
        other.model == model;
  }
  
  @override
  int get hashCode {
    return deviceName.hashCode ^
        version.hashCode ^
        sensorType.hashCode ^
        deviceId.hashCode ^
        manufacturer.hashCode ^
        model.hashCode;
  }
}
