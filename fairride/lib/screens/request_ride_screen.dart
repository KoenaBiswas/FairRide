part of '../fare_ride_screens.dart';

class FareRideRequestRideScreen extends StatefulWidget {
  const FareRideRequestRideScreen({super.key});
  @override
  State<FareRideRequestRideScreen> createState() =>
      _FareRideRequestRideScreenState();
}

class _FareRideRequestRideScreenState extends State<FareRideRequestRideScreen> {
  LocationChoice? _pickup;
  LocationChoice? _destination;
  String? _busyRideId;

  Future<void> _request(Ride ride) async {
    if (_pickup == null) {
      fareRideSnack(
        context,
        'Choose your pickup from the place options or use your location.',
      );
      return;
    }
    setState(() => _busyRideId = ride.id);
    try {
      await RideService.instance.requestToJoin(
        rideId: ride.id,
        pickupName: _pickup!.name,
        pickupLat: _pickup!.latitude,
        pickupLng: _pickup!.longitude,
      );
      await RecentStore.instance.savePlace(
        label: _pickup!.name,
        latitude: _pickup!.latitude,
        longitude: _pickup!.longitude,
      );
      if (_destination != null) {
        await RecentStore.instance.savePlace(
          label: _destination!.name,
          latitude: _destination!.latitude,
          longitude: _destination!.longitude,
        );
      }
      if (mounted) {
        fareRideSnack(context, 'Request sent to ${ride.driverName}.');
      }
    } catch (error) {
      if (mounted) {
        fareRideSnack(context, 'Could not request this ride: $error');
      }
    } finally {
      if (mounted) setState(() => _busyRideId = null);
    }
  }

  Future<void> _cancelRequest(String rideId) async {
    try {
      await RideService.instance.cancelRequest(rideId);
      if (mounted) fareRideSnack(context, 'Ride request cancelled.');
    } catch (error) {
      if (mounted) fareRideSnack(context, '$error');
    }
  }

  @override
  Widget build(BuildContext context) => FareRidePage(
    title: 'Find a ride',
    navigationIndex: 1,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        const Text(
          'Where to?',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            color: FareRideColors.ink,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Search for any destination. Choose a match or use your current location.',
          style: TextStyle(color: FareRideColors.muted),
        ),
        const SizedBox(height: 18),
        LocationPickerField(
          label: 'Destination',
          onSelected: (place) => setState(() => _destination = place),
        ),
        const SizedBox(height: 12),
        LocationPickerField(
          label: 'Your pickup location',
          onSelected: (place) => setState(() => _pickup = place),
        ),
        const SizedBox(height: 22),
        const FareRideSectionTitle('Available rides'),
        const SizedBox(height: 10),
        if (_destination == null)
          const FareRideCard(
            child: Text(
              'Choose a destination above to see rides ending nearby.',
            ),
          )
        else
          StreamBuilder<List<Ride>>(
            stream: RideService.instance.watchOpenRides(
              nearLat: _destination!.latitude,
              nearLng: _destination!.longitude,
              radiusKm: 20,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const FareRideCard(
                  child: Text('Unable to load rides. Please try again.'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final rides = snapshot.data!;
              if (rides.isEmpty) {
                return const FareRideCard(
                  child: Text('No open rides found near this destination.'),
                );
              }
              return Column(
                children: [
                  for (final ride in rides)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FareRideCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.alt_route,
                                  color: FareRideColors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${ride.startName} → ${ride.destName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  formatRupees(ride.totalFare),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: FareRideColors.greenDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Driver: ${ride.driverName} · ${ride.seatsAvailable} seats available',
                              style: const TextStyle(
                                color: FareRideColors.muted,
                              ),
                            ),
                            Text(
                              'Departs ${DateFormat.yMMMd().add_jm().format(ride.departureTime)}',
                              style: const TextStyle(
                                color: FareRideColors.muted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FareRideRideDetailsScreen(
                                      rideId: ride.id,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.info_outline),
                                label: const Text('Ride details'),
                              ),
                            ),
                            StreamBuilder<RideRequest?>(
                              stream: RideService.instance.watchMyRequest(
                                ride.id,
                              ),
                              builder: (context, request) {
                                final status = request.data?.status;
                                final isActive =
                                    status == RequestStatus.pending ||
                                    status == RequestStatus.accepted;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (isActive)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          ride.status == RideStatus.inProgress
                                              ? 'Ride started'
                                              : status == RequestStatus.accepted
                                              ? 'Driver accepted your request'
                                              : 'Waiting for the driver to accept',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: FareRideColors.greenDark,
                                          ),
                                        ),
                                      ),
                                    isActive
                                        ? OutlinedButton(
                                            onPressed:
                                                status == RequestStatus.accepted
                                                ? null
                                                : () => _cancelRequest(ride.id),
                                            child: Text(
                                              status == RequestStatus.accepted
                                                  ? 'Accepted'
                                                  : 'Cancel request',
                                            ),
                                          )
                                        : FilledButton(
                                            onPressed: _busyRideId != null
                                                ? null
                                                : () => _request(ride),
                                            child: Text(
                                              _busyRideId == ride.id
                                                  ? 'Sending…'
                                                  : 'Request seat',
                                            ),
                                          ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    ),
  );
}
