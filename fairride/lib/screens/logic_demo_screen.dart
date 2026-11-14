import 'package:flutter/material.dart';

import '../logic/fare_calculator.dart';
import '../logic/rider_ordering.dart';
import '../logic/route_filter.dart';
import 'pickup_map_screen.dart';

class LogicDemoScreen extends StatefulWidget {
  const LogicDemoScreen({super.key});
  @override
  State<LogicDemoScreen> createState() => _LogicDemoScreenState();
}

class _LogicDemoScreenState extends State<LogicDemoScreen> {
  static const campus = Point(28.6139, 77.2090);

  // fake driver route (the real Directions polyline replaces this later)
  static const route = [
    Point(28.6192, 77.0330),
    Point(28.6292, 77.0780),
    Point(28.6415, 77.1219),
    campus,
  ];

  // fake riders who requested to join
  static const requests = [
    RiderPickup('Rajouri', Point(28.6420, 77.1200)),
    RiderPickup('Janakpuri', Point(28.6300, 77.0800)),
    RiderPickup('Dwarka Mor', Point(28.6195, 77.0335)),
    RiderPickup('Gurgaon', Point(28.4595, 77.0266)),
  ];

  double maxKm = 1.5;
  double totalFare = 100;

  @override
  Widget build(BuildContext context) {
    final kept = filterByRoute(requests, route, maxKm: maxKm);
    final dropped = requests.where((r) => !kept.contains(r)).toList();
    final ordered = sortFarthestFirst(kept, campus);

    // straight-line leg lengths for now; road distances replace these later
    final legKm = <double>[
      for (var i = 0; i < ordered.length; i++)
        haversineKm(
          ordered[i].pickup,
          i + 1 < ordered.length ? ordered[i + 1].pickup : campus,
        ),
    ];

    final fares = ordered.isEmpty
        ? <String, double>{}
        : calculateFares(
            riders: ordered.map((r) => r.name).toList(),
            legKm: legKm,
            totalFare: totalFare,
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Logic demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Max distance from route: ${maxKm.toStringAsFixed(1)} km'),
          Slider(
            value: maxKm,
            min: 0.1,
            max: 25,
            divisions: 249,
            onChanged: (v) => setState(() => maxKm = v),
          ),
          Text('Total fare: ₹${totalFare.round()}'),
          Slider(
            value: totalFare,
            min: 50,
            max: 500,
            divisions: 45,
            onChanged: (v) => setState(() => totalFare = v),
          ),
          const Divider(),
          const Text(
            'Rejected (too far from route)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final r in dropped)
            ListTile(
              dense: true,
              leading: const Icon(Icons.block, color: Colors.red),
              title: Text(r.name),
              subtitle: Text(
                '${distanceToRouteKm(r.pickup, route).toStringAsFixed(1)} km from route',
              ),
            ),
          const Divider(),
          const Text(
            'Pickup order and fare',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          for (var i = 0; i < ordered.length; i++)
            ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(ordered[i].name),
              subtitle: Text(
                '${haversineKm(ordered[i].pickup, campus).toStringAsFixed(1)} km from destination, '
                'next leg ${legKm[i].toStringAsFixed(1)} km',
              ),
              trailing: Text(
                '₹${(fares[ordered[i].name] ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          const Divider(),
          Text(
            'Sum of fares: ₹${fares.values.fold<double>(0, (a, b) => a + b).toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PickupMapScreen(
                  orderedRiders: ordered,
                  destination: campus,
                ),
              ),
            ),
            child: const Text('Show on map'),
          ),
        ],
      ),
    );
  }
}
