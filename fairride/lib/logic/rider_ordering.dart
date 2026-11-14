import 'dart:math';

class Point {
  final double lat, lng;
  const Point(this.lat, this.lng);
}

class RiderPickup {
  final String name;
  final Point pickup;
  const RiderPickup(this.name, this.pickup);
}

/// Straight-line distance in km between two points.
double haversineKm(Point a, Point b) {
  const earthRadiusKm = 6371.0;
  double rad(double deg) => deg * pi / 180;

  final dLat = rad(b.lat - a.lat);
  final dLng = rad(b.lng - a.lng);
  final h =
      pow(sin(dLat / 2), 2) +
      cos(rad(a.lat)) * cos(rad(b.lat)) * pow(sin(dLng / 2), 2);
  return 2 * earthRadiusKm * asin(sqrt(h));
}

/// Farthest from the destination first, nearest last.
List<RiderPickup> sortFarthestFirst(
  List<RiderPickup> riders,
  Point destination,
) {
  final sorted = [...riders];
  sorted.sort(
    (a, b) => haversineKm(
      b.pickup,
      destination,
    ).compareTo(haversineKm(a.pickup, destination)),
  );
  return sorted;
}
