import 'package:json_annotation/json_annotation.dart';

part 'height_measurement.g.dart';

/// Model representing a height measurement from the sensor
@JsonSerializable()
class HeightMeasurement {
  /// Distance in centimeters
  @JsonKey(name: 'distance_cm')
  final double distanceCm;
  
  /// Distance in millimeters
  @JsonKey(name: 'distance_mm')
  final int distanceMm;
  
  /// Timestamp of the measurement
  @JsonKey(name: 'timestamp')
  final int timestamp;
  
  /// Whether the measurement is valid
  @JsonKey(name: 'is_valid', defaultValue: true)
  final bool isValid;
  
  /// Error message if measurement failed
  @JsonKey(name: 'error')
  final String? error;
  
  HeightMeasurement({
    required this.distanceCm,
    required this.distanceMm,
    required this.timestamp,
    this.isValid = true,
    this.error,
  });
  
  /// Create a HeightMeasurement from JSON
  factory HeightMeasurement.fromJson(Map<String, dynamic> json) =>
      _$HeightMeasurementFromJson(json);
  
  /// Convert HeightMeasurement to JSON
  Map<String, dynamic> toJson() => _$HeightMeasurementToJson(this);
  
  /// Create a failed measurement
  factory HeightMeasurement.error(String error, {int? timestamp}) {
    return HeightMeasurement(
      distanceCm: 0.0,
      distanceMm: 0,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      isValid: false,
      error: error,
    );
  }
  
  /// Create a timeout measurement
  factory HeightMeasurement.timeout({int? timestamp}) {
    return HeightMeasurement.error(
      'Sensor timeout - no object detected',
      timestamp: timestamp,
    );
  }
  
  @override
  String toString() {
    if (isValid) {
      return 'HeightMeasurement(distance: ${distanceCm.toStringAsFixed(2)} cm, '
             'timestamp: $timestamp)';
    } else {
      return 'HeightMeasurement.error(error: $error, timestamp: $timestamp)';
    }
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HeightMeasurement &&
        other.distanceCm == distanceCm &&
        other.distanceMm == distanceMm &&
        other.timestamp == timestamp &&
        other.isValid == isValid &&
        other.error == error;
  }
  
  @override
  int get hashCode {
    return distanceCm.hashCode ^
        distanceMm.hashCode ^
        timestamp.hashCode ^
        isValid.hashCode ^
        error.hashCode;
  }
}
