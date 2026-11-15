part of '../fare_ride_screens.dart';

class FareRideRiderDashboardScreen extends StatelessWidget {
  const FareRideRiderDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const FareRideBrand(compact: true),
      actions: [
        IconButton(
          tooltip: 'Log out',
          onPressed: AuthService.instance.signOut,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Welcome to FareRide',
          style: TextStyle(color: FareRideColors.muted),
        ),
        const SizedBox(height: 4),
        const Text(
          'Where are you headed?',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: FareRideColors.ink,
          ),
        ),
        const SizedBox(height: 16),
        FareRidePrimaryButton(
          label: 'Find a ride',
          icon: Icons.search,
          onPressed: () =>
              Navigator.pushNamed(context, FareRideRoutes.requestRide),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            try {
              final added = await RideService.instance.seedDemoData();
              if (context.mounted) {
                fareRideSnack(
                  context,
                  added
                      ? 'Demo rides and history added to your account.'
                      : 'Demo data is already loaded for this account.',
                );
              }
            } catch (error) {
              if (context.mounted) fareRideSnack(context, '$error');
            }
          },
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Load demo data'),
        ),
        const SizedBox(height: 20),
        const FareRideSectionTitle('Your upcoming rides'),
        const SizedBox(height: 8),
        StreamBuilder<List<Ride>>(
          stream: RideService.instance.watchMyRidesAsRider(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rides = snap.data!;
            if (rides.isEmpty) {
              return const FareRideCard(child: Text('No accepted rides yet.'));
            }
            return Column(
              children: [
                for (final ride in rides)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FareRideCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ride.startName} → ${ride.destName}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Driver ${ride.driverName} · ${ride.status} · departs ${DateFormat.yMMMd().add_jm().format(ride.departureTime)}',
                            style: const TextStyle(color: FareRideColors.muted),
                          ),
                          const SizedBox(height: 4),
                          Text('Total fare ${formatRupees(ride.totalFare)}'),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                FareRideRoutes.fareSplit,
                                arguments: ride.id,
                              ),
                              icon: const Icon(Icons.receipt_long_outlined),
                              label: const Text('View fare split'),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () async {
                                try {
                                  await RideService.instance.cancelRequest(
                                    ride.id,
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    fareRideSnack(context, '$e');
                                  }
                                }
                              },
                              child: const Text('Cancel seat'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        const FareRideSectionTitle('Ride history'),
        const SizedBox(height: 8),
        StreamBuilder<List<RideHistoryItem>>(
          stream: RideService.instance.watchHistory(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data!;
            if (items.isEmpty) {
              return const FareRideCard(
                child: Text('Completed rides will appear here.'),
              );
            }
            return Column(
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FareRideCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.startName} → ${item.destName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  DateFormat.yMMMd().format(item.completedAt),
                                  style: const TextStyle(
                                    color: FareRideColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatRupees(item.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  FareRideRoutes.fareSplit,
                                  arguments: item.rideId,
                                ),
                                child: const Text('Fare details'),
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
      ],
    ),
  );
}

class FareRideDriverDashboardScreen extends StatelessWidget {
  const FareRideDriverDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const FareRideBrand(compact: true),
      actions: [
        IconButton(
          tooltip: 'Log out',
          onPressed: AuthService.instance.signOut,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Driver dashboard',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: FareRideColors.ink,
          ),
        ),
        const SizedBox(height: 14),
        FareRidePrimaryButton(
          label: 'Post a ride',
          icon: Icons.add_road,
          onPressed: () =>
              Navigator.pushNamed(context, FareRideRoutes.postRide),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            try {
              final added = await RideService.instance.seedDemoData();
              if (context.mounted) {
                fareRideSnack(
                  context,
                  added
                      ? 'Demo rides, requests, and history added.'
                      : 'Demo data is already loaded for this account.',
                );
              }
            } catch (error) {
              if (context.mounted) fareRideSnack(context, '$error');
            }
          },
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Load demo data'),
        ),
        const SizedBox(height: 22),
        const FareRideSectionTitle('Your active rides'),
        const SizedBox(height: 8),
        StreamBuilder<List<Ride>>(
          stream: RideService.instance.watchMyRidesAsDriver(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rides = snap.data!;
            if (rides.isEmpty) {
              return const FareRideCard(
                child: Text('You have no active rides.'),
              );
            }
            return Column(
              children: [
                for (final ride in rides)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FareRideCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${ride.startName} → ${ride.destName}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${ride.seatsAvailable}/${ride.seatsTotal} seats · ${ride.status} · ${formatRupees(ride.totalFare)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pushNamed(
                          context,
                          ride.status == RideStatus.inProgress
                              ? FareRideRoutes.fareSplit
                              : FareRideRoutes.pickupOrder,
                          arguments: ride.id,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        const FareRideSectionTitle('Ride history'),
        const SizedBox(height: 8),
        StreamBuilder<List<RideHistoryItem>>(
          stream: RideService.instance.watchHistory(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data!;
            if (items.isEmpty) {
              return const FareRideCard(
                child: Text('Completed rides will appear here.'),
              );
            }
            return Column(
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FareRideCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.startName} → ${item.destName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${item.riders} riders · ${DateFormat.yMMMd().format(item.completedAt)}',
                                  style: const TextStyle(
                                    color: FareRideColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatRupees(item.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  FareRideRoutes.fareSplit,
                                  arguments: item.rideId,
                                ),
                                child: const Text('Fare details'),
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
      ],
    ),
  );
}
