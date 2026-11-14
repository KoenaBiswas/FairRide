import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../logic/rider_ordering.dart';

class PickupMapScreen extends StatelessWidget {
  final List<RiderPickup> orderedRiders; // already farthest first
  final Point destination;

  const PickupMapScreen({
    super.key,
    required this.orderedRiders,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final dest = LatLng(destination.lat, destination.lng);
    final stops = [
      for (final r in orderedRiders) LatLng(r.pickup.lat, r.pickup.lng),
      dest,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Pickup order')),
      body: FlutterMap(
        options: MapOptions(initialCenter: dest, initialZoom: 11),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.fairride',
          ),
          // straight lines between stops for now; the real road route replaces this later
          PolylineLayer(
            polylines: [
              Polyline(points: stops, strokeWidth: 4, color: Colors.blue),
            ],
          ),
          MarkerLayer(
            markers: [
              for (var i = 0; i < orderedRiders.length; i++)
                Marker(
                  point: stops[i],
                  width: 40,
                  height: 40,
                  child: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              Marker(
                point: dest,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
