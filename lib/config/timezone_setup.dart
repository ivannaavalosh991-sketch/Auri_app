// lib/config/timezone_setup.dart

import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Mapa base de abreviaturas a zonas horarias IANA
String _normalizeTimezone(String name) {
  final map = {
    // ---------------------------
    // LATINOAMÉRICA
    // ---------------------------
    "CST": "America/Guatemala", // Centroamérica (fallback)
    "COT": "America/Bogota", // Colombia
    "PET": "America/Lima", // Perú
    "ECT": "America/Guayaquil", // Ecuador
    "BOT": "America/La_Paz", // Bolivia
    "CLT": "America/Santiago", // Chile estándar
    "CLST": "America/Santiago", // Chile verano
    "ART": "America/Argentina/Buenos_Aires",
    "AST": "America/Anguilla", // Caribe
    // México
    "CST6CDT": "America/Mexico_City",
    "CDT": "America/Mexico_City",

    // Panamá y Caribe que usan EST sin DST
    "EST": "America/Panama",
    "EDT": "America/New_York",

    // ---------------------------
    // EUROPA
    // ---------------------------
    "CET": "Europe/Madrid",
    "CEST": "Europe/Madrid",

    "WET": "Europe/Lisbon",
    "WEST": "Europe/Lisbon",

    "EET": "Europe/Athens",
    "EEST": "Europe/Athens",

    "GMT": "Europe/London",
    "BST": "Europe/London",

    // ---------------------------
    // USA / CANADÁ
    // ---------------------------
    "PST": "America/Los_Angeles",
    "PDT": "America/Los_Angeles",

    "MST": "America/Denver",
    "MDT": "America/Denver",

    "CST_US": "America/Chicago",
    "CDT_US": "America/Chicago",

    "EST_US": "America/New_York",
    "EDT_US": "America/New_York",

    "AKST": "America/Anchorage",
    "AKDT": "America/Anchorage",
    "HST": "Pacific/Honolulu",

    // ---------------------------
    // ASIA / OCEANÍA
    // ---------------------------
    "IST": "Asia/Kolkata",
    "CHINA": "Asia/Shanghai",
    "JST": "Asia/Tokyo",

    "AEST": "Australia/Sydney",
    "AEDT": "Australia/Sydney",

    "NZST": "Pacific/Auckland",

    // ---------------------------
    // FALLBACK
    // ---------------------------
    "UTC": "Etc/UTC",
  };

  if (map.containsKey(name)) return map[name]!;
  return "Etc/UTC";
}

Future<Position?> _tryGetPosition() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );
  } catch (_) {
    return null;
  }
}

String _refineTimezone({
  required String currentLocation,
  required String abbrev,
  required String? countryCode,
}) {
  if (countryCode == null) return currentLocation;
  final cc = countryCode.toUpperCase();

  switch (abbrev) {
    case "CST":
    case "CDT":
      if (["CR", "GT", "SV", "HN", "NI"].contains(cc)) {
        return "America/Guatemala"; // Centroamérica
      }
      if (cc == "MX") {
        return "America/Mexico_City";
      }
      if (["US", "CA"].contains(cc)) {
        return "America/Chicago";
      }
      return currentLocation;

    case "EST":
    case "EDT":
      if (cc == "PA") return "America/Panama";
      if (["CO", "PE", "EC"].contains(cc)) {
        return "America/Bogota";
      }
      if (["US", "CA"].contains(cc)) {
        return "America/New_York";
      }
      return currentLocation;

    case "CET":
    case "CEST":
      if ([
        "ES",
        "FR",
        "DE",
        "IT",
        "PT",
        "NL",
        "BE",
        "LU",
        "CH",
        "AT",
      ].contains(cc)) {
        return "Europe/Madrid";
      }
      return currentLocation;

    default:
      return currentLocation;
  }
}

/// Inicializa la base de TZ y detecta la zona horaria local
Future<void> setupLocalTimezone() async {
  tz.initializeTimeZones();

  final systemName = DateTime.now().timeZoneName; // "CST", "CET", etc.
  String locationName = _normalizeTimezone(systemName);

  try {
    final pos = await _tryGetPosition();
    if (pos != null) {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final countryCode = placemarks.first.isoCountryCode;
        locationName = _refineTimezone(
          currentLocation: locationName,
          abbrev: systemName,
          countryCode: countryCode,
        );
      }
    }
  } catch (_) {
    // Si falla, seguimos con locationName base
  }

  tz.setLocalLocation(tz.getLocation(locationName));
  debugPrint(
    "Auri → timezone detectado: $systemName → usando IANA: $locationName",
  );
}
