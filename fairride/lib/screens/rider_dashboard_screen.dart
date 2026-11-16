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
                          TextButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FareRideRideDetailsScreen(rideId: ride.id),
                              ),
                            ),
                            icon: const Icon(Icons.info_outline),
                            label: const Text('Ride details'),
                          ),
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
                                  '${DateFormat.yMMMd().format(item.completedAt)} · Payment ${item.paymentStatus.replaceAll('_', ' ')}',
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
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FareRideRideDetailsScreen(
                                      rideId: item.rideId,
                                    ),
                                  ),
                                ),
                                child: const Text('Ride details'),
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
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .collection('documents')
              .snapshots(),
          builder: (context, docs) {
            final documentsReady = const ['licence', 'rc', 'selfie'].every(
              (key) =>
                  docs.data?.docs.any(
                    (doc) =>
                        doc.id == key && doc.data()['imageBase64'] is String,
                  ) ==
                  true,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (documentsReady)
                  Chip(
                    avatar: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    ),
                    label: const Text('Documents submitted'),
                    backgroundColor: Colors.green.shade50,
                    side: BorderSide.none,
                  )
                else
                  Card(
                    child: ListTile(
                      title: const Text(
                        'Upload your documents to start posting rides',
                      ),
                      trailing: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FareRideDriverProfileScreen(),
                          ),
                        ),
                        child: const Text('Driver profile'),
                      ),
                    ),
                  ),
                FareRidePrimaryButton(
                  label: 'Post a ride',
                  icon: Icons.add_road,
                  onPressed: documentsReady
                      ? () => Navigator.pushNamed(
                          context,
                          FareRideRoutes.postRide,
                        )
                      : null,
                ),
              ],
            );
          },
        ),
        TextButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FareRideDriverProfileScreen(),
            ),
          ),
          icon: const Icon(Icons.person_outline),
          label: const Text('Driver profile and UPI'),
        ),
        const SizedBox(height: 8),
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
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FareRideRideDetailsScreen(rideId: ride.id),
                          ),
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
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FareRideRideDetailsScreen(
                                      rideId: item.rideId,
                                    ),
                                  ),
                                ),
                                child: const Text('Ride details'),
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
