part of '../fare_ride_screens.dart';

class FareRidePickupOrderScreen extends StatelessWidget {
  const FareRidePickupOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rideId = ModalRoute.of(context)?.settings.arguments as String?;
    if (rideId == null) {
      return const FareRidePage(
        title: 'Pickup details',
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
          return const FareRidePage(
            title: 'Pickup details',
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return FareRidePage(
          title: 'Pickup details',
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
                style: const TextStyle(color: FareRideColors.muted),
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
              const SizedBox(height: 12),
              FareRideSectionTitle(
                'Rider requests · farthest pickup first',
                trailing: Text(ride.status),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<RideRequest>>(
                stream: RideService.instance.watchRequests(rideId),
                builder: (context, requestSnap) {
                  if (requestSnap.hasError) {
                    return const FareRideCard(
                      child: Text('Unable to load requests.'),
                    );
                  }
                  if (!requestSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final requests = requestSnap.data!;
                  if (requests.isEmpty) {
                    return const FareRideCard(
                      child: Text('No rider requests yet.'),
                    );
                  }
                  return Column(
                    children: [
                      for (final request in requests)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FareRideCard(
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
                                  '${request.pickupName} · ${request.distanceToDestKm.toStringAsFixed(1)} km from destination · ${request.status}',
                                  style: const TextStyle(
                                    color: FareRideColors.muted,
                                  ),
                                ),
                                if (request.fare != null)
                                  Text(
                                    'Fare: ${formatRupees(request.fare!)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
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
                                              fareRideSnack(context, '$e');
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
                FareRidePrimaryButton(
                  label: 'Start ride',
                  icon: Icons.play_arrow,
                  onPressed: ride.riderIds.isEmpty
                      ? null
                      : () async {
                          try {
                            await RideService.instance.startRide(rideId);
                          } catch (e) {
                            if (context.mounted) fareRideSnack(context, '$e');
                          }
                        },
                ),
              if (ride.status == RideStatus.inProgress) ...[
                const SizedBox(height: 10),
                FareRidePrimaryButton(
                  label: 'Complete ride and split fare',
                  icon: Icons.check,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    FareRideRoutes.fareSplit,
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
