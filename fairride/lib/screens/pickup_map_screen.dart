import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/ride_models.dart';
import '../services/ride_service.dart';

class PickupMapScreen extends StatelessWidget {
  final String rideId;
  const PickupMapScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) => StreamBuilder<Ride?>(
    stream: RideService.instance.watchRide(rideId),
    builder: (context, rideSnapshot) {
      final ride = rideSnapshot.data;
      if (ride == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final destination = LatLng(ride.destLat, ride.destLng);
      final start = LatLng(ride.startLat, ride.startLng);
      return Scaffold(
        appBar: AppBar(title: const Text('Pickup order')),
        body: StreamBuilder<List<RideRequest>>(
          stream: RideService.instance.watchRequests(rideId),
          builder: (context, requestSnapshot) {
            final requests = requestSnapshot.data ?? const <RideRequest>[];
            final stops = [
              start,
              for (final request in requests)
                LatLng(request.pickupLat, request.pickupLng),
              destination,
            ];
            final center = LatLng(
              (ride.startLat + ride.destLat) / 2,
              (ride.startLng + ride.destLng) / 2,
            );
            return FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 11),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.fairride',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(points: stops, strokeWidth: 4, color: Colors.blue),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: start,
                      width: 42,
                      height: 42,
                      child: const Icon(
                        Icons.directions_car,
                        color: Colors.green,
                        size: 36,
                      ),
                    ),
                    for (var i = 0; i < requests.length; i++)
                      Marker(
                        point: stops[i + 1],
                        width: 42,
                        height: 42,
                        child: CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    Marker(
                      point: destination,
                      width: 42,
                      height: 42,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 38,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
