import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RecentPlace {
  const RecentPlace({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final double latitude;
  final double longitude;

  Map<String, Object> toJson() => {
    'label': label,
    'lat': latitude,
    'lng': longitude,
  };

  factory RecentPlace.fromJson(Map<String, dynamic> json) => RecentPlace(
    label: json['label'] as String? ?? '',
    latitude: (json['lat'] as num?)?.toDouble() ?? 0,
    longitude: (json['lng'] as num?)?.toDouble() ?? 0,
  );
}

/// Device-local convenience data. Passwords and authentication tokens are
/// deliberately never stored here.
class RecentStore {
  RecentStore._();
  static final instance = RecentStore._();

  static const _emails = 'recent_emails';
  static const _phones = 'recent_phones';
  static const _places = 'recent_places';
  static const _role = 'last_role';
  static const _seats = 'last_ride_seats';
  static const _fare = 'last_ride_fare';

  Future<List<String>> recentEmails() async =>
      (await SharedPreferences.getInstance()).getStringList(_emails) ??
      const [];

  Future<void> saveEmail(String value) async {
    final email = value.trim().toLowerCase();
    if (email.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _emails,
      _newestFirst(prefs.getStringList(_emails) ?? const [], email, 5),
    );
  }

  Future<void> removeEmail(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _emails,
      (prefs.getStringList(_emails) ?? const [])
          .where((email) => email != value)
          .toList(),
    );
  }

  Future<List<String>> recentPhones() async =>
      (await SharedPreferences.getInstance()).getStringList(_phones) ??
      const [];

  Future<void> savePhone(String value) async {
    final phone = value.trim();
    if (phone.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _phones,
      _newestFirst(prefs.getStringList(_phones) ?? const [], phone, 3),
    );
  }

  Future<void> removePhone(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _phones,
      (prefs.getStringList(_phones) ?? const [])
          .where((phone) => phone != value)
          .toList(),
    );
  }

  Future<String?> lastRole() async =>
      (await SharedPreferences.getInstance()).getString(_role);

  Future<void> saveRole(String role) async {
    if (role != 'rider' && role != 'driver') return;
    await (await SharedPreferences.getInstance()).setString(_role, role);
  }

  Future<List<RecentPlace>> recentPlaces() async {
    final values =
        (await SharedPreferences.getInstance()).getStringList(_places) ??
        const [];
    return values
        .map((value) {
          try {
            return RecentPlace.fromJson(
              jsonDecode(value) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<RecentPlace>()
        .where((place) => place.label.isNotEmpty)
        .toList();
  }

  Future<void> savePlace({
    required String label,
    required double latitude,
    required double longitude,
  }) async {
    final placeName = label.trim();
    if (placeName.isEmpty || !latitude.isFinite || !longitude.isFinite) return;
    final prefs = await SharedPreferences.getInstance();
    final places = await recentPlaces();
    final next = [
      RecentPlace(label: placeName, latitude: latitude, longitude: longitude),
      ...places.where(
        (place) => place.label.toLowerCase() != placeName.toLowerCase(),
      ),
    ].take(8);
    await prefs.setStringList(
      _places,
      next.map((place) => jsonEncode(place.toJson())).toList(),
    );
  }

  Future<void> removePlace(String label) async {
    final prefs = await SharedPreferences.getInstance();
    final places = await recentPlaces();
    await prefs.setStringList(
      _places,
      places
          .where((place) => place.label != label)
          .map((place) => jsonEncode(place.toJson()))
          .toList(),
    );
  }

  Future<({int seats, double fare})> rideDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      seats: prefs.getInt(_seats) ?? 2,
      fare: double.tryParse(prefs.getString(_fare) ?? '') ?? 150,
    );
  }

  Future<void> saveRideDefaults({
    required int seats,
    required double fare,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seats, seats);
    await prefs.setString(_fare, fare.toString());
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emails);
    await prefs.remove(_phones);
    await prefs.remove(_places);
    await prefs.remove(_role);
    await prefs.remove(_seats);
    await prefs.remove(_fare);
  }

  Future<void> clearSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emails);
    await prefs.remove(_phones);
    await prefs.remove(_places);
  }

  List<String> _newestFirst(List<String> current, String value, int limit) => [
    value,
    ...current.where((item) => item.toLowerCase() != value.toLowerCase()),
  ].take(limit).toList();
}
