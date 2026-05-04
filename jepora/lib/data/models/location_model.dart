// lib/data/models/location_model.dart

class LocationModel {
  final double latitude;
  final double longitude;
  final String? label; // Nama jalan/alamat dari reverse geocoding (opsional)

  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.label,
  });

  /// Koordinat dalam format string singkat untuk ditampilkan di UI
  String get coordsString =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  /// Label yang ditampilkan: pakai label jika ada, fallback ke koordinat
  String get displayName => label != null && label!.isNotEmpty ? label! : coordsString;

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? label,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'label': label,
      };

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        label: json['label'] as String?,
      );

  @override
  String toString() => 'LocationModel(lat: $latitude, lng: $longitude, label: $label)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationModel &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}