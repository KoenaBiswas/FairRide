part of '../fare_ride_screens.dart';

class FareRideRideDetailsScreen extends StatelessWidget {
  const FareRideRideDetailsScreen({super.key, required this.rideId});
  final String rideId;

  @override
  Widget build(BuildContext context) => StreamBuilder<Ride?>(
    stream: RideService.instance.watchRide(rideId),
    builder: (context, rideSnap) {
      if (rideSnap.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Ride details')),
          body: Center(child: Text('Unable to load ride: ${rideSnap.error}')),
        );
      }
      final ride = rideSnap.data;
      if (ride == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final isDriver = uid == ride.driverId;
      return Scaffold(
        appBar: AppBar(title: const Text('Ride details')),
        body: StreamBuilder<List<RideRequest>>(
          stream: RideService.instance.watchRequests(rideId),
          builder: (context, requestSnap) {
            if (requestSnap.hasError) {
              return Center(
                child: Text('Unable to load riders: ${requestSnap.error}'),
              );
            }
            if (!requestSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final riders =
                requestSnap.data!
                    .where(
                      (r) => [
                        RequestStatus.accepted,
                        RequestStatus.pickedUp,
                        RequestStatus.dropped,
                      ].contains(r.status),
                    )
                    .toList()
                  ..sort(
                    (a, b) => b.distanceToDestKm.compareTo(a.distanceToDestKm),
                  );
            final stops = [
              LatLng(ride.startLat, ride.startLng),
              ...riders.map((r) => LatLng(r.pickupLat, r.pickupLng)),
              LatLng(ride.destLat, ride.destLng),
            ];
            return FutureBuilder<RouteResult>(
              future: RoutingService.instance.route(stops),
              builder: (context, routeSnap) {
                final route = routeSnap.data;
                final estimateFares = route == null
                    ? <String, double>{}
                    : calculateFares(
                        riders.map((r) => r.riderId).toList(),
                        route.legKm.length > 1
                            ? route.legKm.skip(1).toList()
                            : route.legKm,
                        ride.totalFare,
                      );
                RideRequest? me;
                for (final rider in riders) {
                  if (rider.riderId == uid) {
                    me = rider;
                    break;
                  }
                }
                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    if (route == null)
                      const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      SizedBox(
                        height: 240,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: stops.first,
                              initialZoom: 11,
                              initialCameraFit: CameraFit.bounds(
                                bounds: LatLngBounds.fromPoints(route.points),
                                padding: const EdgeInsets.all(36),
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.fairride',
                              ),
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: route.points,
                                    strokeWidth: 4,
                                    color: FareRideColors.green,
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: stops.first,
                                    width: 34,
                                    height: 34,
                                    child: const Icon(
                                      Icons.directions_car,
                                      color: Colors.green,
                                      size: 32,
                                    ),
                                  ),
                                  for (var i = 0; i < riders.length; i++)
                                    Marker(
                                      point: stops[i + 1],
                                      width: 34,
                                      height: 34,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.orange,
                                        child: Text(
                                          '${i + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Marker(
                                    point: stops.last,
                                    width: 34,
                                    height: 34,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (route?.isApproximate == true)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Text('Approximate route (offline)'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      '${ride.startName} → ${ride.destName}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text(ride.status.replaceAll('_', ' '))),
                        Chip(
                          label: Text(
                            '${(ride.routeKm > 0 ? ride.routeKm : route?.totalKm ?? 0).toStringAsFixed(1)} km',
                          ),
                        ),
                        Chip(
                          label: Text(
                            '${(ride.routeDurationMin > 0 ? ride.routeDurationMin : route?.durationMin ?? 0).round()} min',
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Departs ${DateFormat.yMMMd().add_jm().format(ride.departureTime)}',
                    ),
                    Text(
                      'Driver: ${ride.driverName} · ${ride.vehicleModel} ${ride.vehicleNumber}'
                          .trim(),
                    ),
                    Text(
                      '${ride.seatsAvailable} of ${ride.seatsTotal} seats left · Total fare ${formatRupees(ride.totalFare)}',
                    ),
                    if (me != null)
                      Text(
                        'Your estimated share: ${formatRupees(me.fare ?? estimateFares[me.riderId] ?? 0)}',
                      ),
                    const SizedBox(height: 14),
                    const FareRideSectionTitle('Riders · pickup order'),
                    for (var i = 0; i < riders.length; i++)
                      ListTile(
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(
                          riders[i].riderId == uid
                              ? 'You'
                              : riders[i].riderName,
                        ),
                        subtitle: Text(
                          '${riders[i].pickupName} · ${riders[i].status} · ${formatRupees(riders[i].fare ?? estimateFares[riders[i].riderId] ?? 0)}',
                        ),
                        trailing: ride.status == RideStatus.completed
                            ? Text(riders[i].paymentStatus.replaceAll('_', ' '))
                            : null,
                      ),
                    if (ride.status == RideStatus.completed && !isDriver)
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          FareRideRoutes.fareSplit,
                          arguments: rideId,
                        ),
                        icon: const Icon(Icons.qr_code),
                        label: const Text('View fare and payment QR'),
                      ),
                    const SizedBox(height: 12),
                    if (isDriver)
                      FilledButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          FareRideRoutes.pickupOrder,
                          arguments: rideId,
                        ),
                        icon: const Icon(Icons.manage_accounts),
                        label: const Text('Manage ride'),
                      )
                    else if (me == null && ride.status == RideStatus.open)
                      FilledButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          FareRideRoutes.requestRide,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Find and request this ride'),
                      )
                    else if (me != null &&
                        [
                          RequestStatus.pending,
                          RequestStatus.accepted,
                        ].contains(me.status))
                      OutlinedButton(
                        onPressed: () async {
                          try {
                            await RideService.instance.cancelRequest(rideId);
                          } catch (e) {
                            if (context.mounted) fareRideSnack(context, '$e');
                          }
                        },
                        child: const Text('Cancel request'),
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
