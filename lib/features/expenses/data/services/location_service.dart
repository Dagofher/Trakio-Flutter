import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  const LocationResult(this.latitude, this.longitude);
}

/// Captura la ubicación GPS actual gestionando permisos y servicio.
class LocationService {
  const LocationService();

  /// Devuelve la ubicación actual, o null si no se pudo obtener
  /// (servicio apagado o permiso denegado).
  Future<LocationResult?> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    return LocationResult(position.latitude, position.longitude);
  }
}
