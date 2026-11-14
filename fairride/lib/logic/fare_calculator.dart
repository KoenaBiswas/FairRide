/// riders: rider names in pickup order (farthest first)
/// legKm[i]: km from riders[i]'s pickup to the next stop
///           (the last entry runs to the destination)
/// returns: each rider's fare, summing to totalFare
Map<String, double> calculateFares({
  required List<String> riders,
  required List<double> legKm,
  required double totalFare,
}) {
  if (riders.length != legKm.length) {
    throw ArgumentError('riders and legKm must have the same length');
  }
  final totalKm = legKm.fold<double>(0, (a, b) => a + b);
  if (riders.isEmpty || totalKm <= 0) return {};

  final costPerKm = totalFare / totalKm;
  final fares = {for (final r in riders) r: 0.0};

  for (var i = 0; i < riders.length; i++) {
    final legCost = legKm[i] * costPerKm;
    final ridersInCar = i + 1; // riders 0..i are on board during leg i
    for (var j = 0; j <= i; j++) {
      fares[riders[j]] = fares[riders[j]]! + legCost / ridersInCar;
    }
  }
  return fares;
}
