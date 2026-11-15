import 'dart:math';

double _round2(double value) => (value * 100).round() / 100;

/// Splits route cost across riders sharing each stretch, farthest pickup first.
/// For distances 10, 6, and 2 km with a 100 rupee total, returns 66.67,
/// 26.67, and 6.67 respectively.
Map<String, double> splitFare({
  required double totalFare,
  required Map<String, double> distances,
}) {
  if (distances.isEmpty) return {};
  final sorted = distances.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final maxDistance = sorted.first.value;
  if (maxDistance <= 0) {
    return {
      for (final rider in sorted) rider.key: _round2(totalFare / sorted.length),
    };
  }
  final rate = totalFare / maxDistance;
  final segments = List<double>.generate(sorted.length, (i) {
    final nextDistance = i + 1 < sorted.length ? sorted[i + 1].value : 0.0;
    return (sorted[i].value - nextDistance) * rate / (i + 1);
  });
  return {
    for (var i = 0; i < sorted.length; i++)
      sorted[i].key: _round2(
        segments.skip(i).fold(0.0, (sum, segment) => sum + segment),
      ),
  };
}

/// Straight-line distance between two GPS coordinates, in kilometres.
double haversineCoordinatesKm(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadiusKm = 6371.0;
  double rad(double degrees) => degrees * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return 2 * earthRadiusKm * asin(sqrt(a));
}
