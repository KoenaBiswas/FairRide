part of '../fair_ride_screens.dart';

class FairRidePickupOrderScreen extends StatelessWidget {
  const FairRidePickupOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rideId = ModalRoute.of(context)?.settings.arguments as String?;
    if (rideId == null) {
      return const FairRidePage(
        title: 'Pickup details',
        role: 'driver',
        child: Center(
          child: Text('Open pickup management from a posted ride.'),
        ),
      );
    }
    return StreamBuilder<Ride?>(
      stream: RideService.instance.watchRide(rideId),
      builder: (context, rideSnap) {
        final ride = rideSnap.data;
        if (ride == null) {
          return const FairRidePage(
            title: 'Pickup details',
            role: 'driver',
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return FairRidePage(
          title: 'Pickup details',
          role: 'driver',
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '${ride.startName} → ${ride.destName}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${ride.seatsAvailable} of ${ride.seatsTotal} seats available · ${formatRupees(ride.totalFare)} total',
                style: const TextStyle(color: FairRideColors.muted),
              ),
              Text(
                ride.status == RideStatus.inProgress
                    ? 'Current status: Ride started'
                    : 'Current status: Ride not started',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PickupMapScreen(rideId: rideId),
                  ),
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text('View pickup map'),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FairRideRideDetailsScreen(rideId: rideId),
                  ),
                ),
                icon: const Icon(Icons.info_outline),
                label: const Text('Ride details'),
              ),
              const SizedBox(height: 12),
              FairRideSectionTitle(
                'Rider requests · farthest pickup first',
                trailing: Text(ride.status),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<RideRequest>>(
                stream: RideService.instance.watchRequests(rideId),
                builder: (context, requestSnap) {
                  if (requestSnap.hasError) {
                    return const FairRideCard(
                      child: Text('Unable to load requests.'),
                    );
                  }
                  if (!requestSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final requests = requestSnap.data!;
                  if (requests.isEmpty) {
                    return const FairRideCard(
                      child: Text('No rider requests yet.'),
                    );
                  }
                  return Column(
                    children: [
                      for (final request in requests)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FairRideCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.riderName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${request.pickupName} · ${request.distanceToDestKm.toStringAsFixed(1)} km from destination · ${requestStatusLabel(request.status)}',
                                  style: const TextStyle(
                                    color: FairRideColors.muted,
                                  ),
                                ),
                                if (request.fare != null)
                                  Text(
                                    'Fare: ${formatRupees(request.fare!)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                if (ride.status == RideStatus.completed) ...[
                                  Text(
                                    'Payment: ${request.paymentStatus.replaceAll('_', ' ')}',
                                  ),
                                  if (request.paymentStatus == 'marked_paid')
                                    TextButton(
                                      onPressed: () async {
                                        try {
                                          await RideService.instance
                                              .confirmPayment(
                                                rideId,
                                                request.riderId,
                                              );
                                        } catch (e) {
                                          if (context.mounted) {
                                            fairRideSnack(context, '$e');
                                          }
                                        }
                                      },
                                      child: const Text('Confirm received'),
                                    ),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (request.status == RequestStatus.pending)
                                      OutlinedButton(
                                        onPressed: () =>
                                            RideService.instance.rejectRequest(
                                              rideId,
                                              request.riderId,
                                            ),
                                        child: const Text('Reject'),
                                      ),
                                    if (request.status == RequestStatus.pending)
                                      FilledButton(
                                        onPressed: () async {
                                          try {
                                            await RideService.instance
                                                .acceptRequest(
                                                  rideId,
                                                  request.riderId,
                                                );
                                          } catch (e) {
                                            if (context.mounted) {
                                              fairRideSnack(context, '$e');
                                            }
                                          }
                                        },
                                        child: const Text('Accept'),
                                      ),
                                    if (request.status ==
                                        RequestStatus.accepted)
                                      OutlinedButton(
                                        onPressed: () =>
                                            RideService.instance.markPickedUp(
                                              rideId,
                                              request.riderId,
                                            ),
                                        child: const Text('Mark picked up'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              if (ride.status == RideStatus.open ||
                  ride.status == RideStatus.full)
                FairRidePrimaryButton(
                  label: 'Start ride',
                  icon: Icons.play_arrow,
                  onPressed: ride.riderIds.isEmpty
                      ? null
                      : () async {
                          try {
                            final accepted = await RideService.instance
                                .watchRequests(rideId)
                                .first;
                            final pickups = accepted
                                .where(
                                  (r) =>
                                      r.status == RequestStatus.accepted ||
                                      r.status == RequestStatus.pickedUp,
                                )
                                .map(
                                  (r) => ordering.RiderPickup(
                                    r.riderId,
                                    ordering.Point(r.pickupLat, r.pickupLng),
                                  ),
                                )
                                .toList();
                            final sorted = ordering.sortFarthestFirst(
                              pickups,
                              ordering.Point(ride.destLat, ride.destLng),
                            );
                            final stops = [
                              LatLng(ride.startLat, ride.startLng),
                              ...sorted.map(
                                (p) => LatLng(p.pickup.lat, p.pickup.lng),
                              ),
                              LatLng(ride.destLat, ride.destLng),
                            ];
                            final route = await RoutingService.instance.route(
                              stops,
                            );
                            await RideService.instance.startRide(
                              rideId,
                              roadLegKm: route.legKm,
                              routeKm: route.totalKm,
                              durationMin: route.durationMin,
                              approximate: route.isApproximate,
                            );
                            if (route.isApproximate && context.mounted) {
                              fairRideSnack(
                                context,
                                'Approximate route (offline) saved for fare estimates.',
                              );
                            }
                          } catch (e) {
                            if (context.mounted) fairRideSnack(context, '$e');
                          }
                        },
                ),
              if (ride.status == RideStatus.inProgress) ...[
                const SizedBox(height: 10),
                FairRidePrimaryButton(
                  label: 'Complete ride and split fare',
                  icon: Icons.check,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    FairRideRoutes.fareSplit,
                    arguments: rideId,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
