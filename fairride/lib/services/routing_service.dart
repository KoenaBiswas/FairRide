import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  const RouteResult({
    required this.points,
    required this.legKm,
    required this.totalKm,
    required this.durationMin,
    required this.isApproximate,
  });
  final List<LatLng> points;
  final List<double> legKm;
  final double totalKm, durationMin;
  final bool isApproximate;
}

class RoutingService {
  RoutingService._();
  static final instance = RoutingService._();

  Future<RouteResult> route(List<LatLng> stops) async {
    if (stops.length < 2) return _fallback(stops);
    try {
      final coordinates = stops
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/$coordinates',
        {'overview': 'full', 'geometries': 'geojson', 'steps': 'false'},
      );
      final response = await http
          .get(
            uri,
            headers: {'User-Agent': 'FairRide/1.0 (campus carpool demo)'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('Routing returned ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        throw Exception('No road route found');
      }
      final r = routes.first as Map<String, dynamic>;
      final geometry =
          (r['geometry'] as Map<String, dynamic>)['coordinates'] as List;
      final points = geometry
          .map(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList();
      final legs = (r['legs'] as List)
          .map((leg) => ((leg as Map)['distance'] as num).toDouble() / 1000)
          .toList();
      return RouteResult(
        points: points,
        legKm: legs,
        totalKm: ((r['distance'] as num).toDouble() / 1000),
        durationMin: ((r['duration'] as num).toDouble() / 60),
        isApproximate: false,
      );
    } catch (error) {
      debugPrint('OSRM unavailable, using approximate route: $error');
      return _fallback(stops);
    }
  }

  RouteResult _fallback(List<LatLng> stops) {
    const d = Distance();
    final legs = <double>[];
    for (var i = 0; i + 1 < stops.length; i++) {
      legs.add(d.as(LengthUnit.Kilometer, stops[i], stops[i + 1]));
    }
    return RouteResult(
      points: stops,
      legKm: legs,
      totalKm: legs.fold(0.0, (a, b) => a + b),
      durationMin: legs.fold(0.0, (a, b) => a + b) / 30 * 60,
      isApproximate: true,
    );
  }
}

List<LatLng> routeStops({
  required LatLng start,
  required List<LatLng> pickups,
  required LatLng destination,
}) {
  final ordered = [...pickups]
    ..sort(
      (a, b) => _distance(b, destination).compareTo(_distance(a, destination)),
    );
  return [start, ...ordered, destination];
}

double _distance(LatLng a, LatLng b) {
  const d = Distance();
  return d.as(LengthUnit.Meter, a, b);
}
