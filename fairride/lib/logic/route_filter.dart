import 'dart:math' hide Point;

import 'rider_ordering.dart';

/// Shortest distance in km from point p to the segment a-b.
/// Uses a flat local projection, which is accurate enough over a few km.
double distanceToSegmentKm(Point p, Point a, Point b) {
  const kmPerDegLat = 111.32;
  final kmPerDegLng = 111.32 * cos(p.lat * pi / 180);

  // p becomes the origin (0, 0)
  final ax = (a.lng - p.lng) * kmPerDegLng;
  final ay = (a.lat - p.lat) * kmPerDegLat;
  final bx = (b.lng - p.lng) * kmPerDegLng;
  final by = (b.lat - p.lat) * kmPerDegLat;

  final dx = bx - ax, dy = by - ay;
  final lenSq = dx * dx + dy * dy;

  // how far along the segment the closest point lies (0 = a, 1 = b)
  var t = lenSq == 0 ? 0.0 : (-ax * dx - ay * dy) / lenSq;
  t = max(0.0, min(1.0, t));

  final cx = ax + t * dx, cy = ay + t * dy;
  return sqrt(cx * cx + cy * cy);
}

/// Shortest distance in km from p to the whole route (list of polyline points).
double distanceToRouteKm(Point p, List<Point> route) {
  if (route.isEmpty) return double.infinity;
  if (route.length == 1) return haversineKm(p, route.first);

  var best = double.infinity;
  for (var i = 0; i < route.length - 1; i++) {
    best = min(best, distanceToSegmentKm(p, route[i], route[i + 1]));
  }
  return best;
}

/// Keeps only riders whose pickup is within maxKm of the driver's route.
List<RiderPickup> filterByRoute(
  List<RiderPickup> riders,
  List<Point> route, {
  double maxKm = 1.5,
}) {
  return riders
      .where((r) => distanceToRouteKm(r.pickup, route) <= maxKm)
      .toList();
}
