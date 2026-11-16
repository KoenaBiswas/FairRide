import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/ride_models.dart';
import '../services/ride_service.dart';
import '../services/routing_service.dart';
import '../logic/rider_ordering.dart' as ordering;

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
            final requests = (requestSnapshot.data ?? const <RideRequest>[])
                .where(
                  (r) =>
                      r.status == RequestStatus.accepted ||
                      r.status == RequestStatus.pickedUp,
                )
                .toList();
            final ordered = ordering.sortFarthestFirst(
              requests
                  .map(
                    (r) => ordering.RiderPickup(
                      r.riderId,
                      ordering.Point(r.pickupLat, r.pickupLng),
                    ),
                  )
                  .toList(),
              ordering.Point(ride.destLat, ride.destLng),
            );
            final requestById = {for (final r in requests) r.riderId: r};
            final orderedRequests = ordered
                .map((p) => requestById[p.name]!)
                .toList();
            final stops = [
              start,
              for (final r in orderedRequests) LatLng(r.pickupLat, r.pickupLng),
              destination,
            ];
            return FutureBuilder<RouteResult>(
              future: RoutingService.instance.route(stops),
              builder: (context, routeSnapshot) {
                final result = routeSnapshot.data;
                if (result == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: start,
                        initialZoom: 11,
                        initialCameraFit: CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints(result.points),
                          padding: const EdgeInsets.all(44),
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.fairride',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: result.points,
                              strokeWidth: 4,
                              color: Colors.blue,
                            ),
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
                            for (var i = 0; i < orderedRequests.length; i++)
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
                    ),
                    if (result.isApproximate)
                      const Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Text('Approximate route (offline)'),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      );
    },
  );
}
