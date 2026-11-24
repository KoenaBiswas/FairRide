part of '../fair_ride_screens.dart';

class FairRideRiderDashboardScreen extends StatelessWidget {
  const FairRideRiderDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: const FairRideAccountDrawer(isDriver: false),
    appBar: AppBar(
      title: const FairRideBrand(compact: true),
    ),
    bottomNavigationBar: fairRideBottomNav(context, selected: 0),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Welcome to FairRide',
          style: TextStyle(color: FairRideColors.muted),
        ),
        const SizedBox(height: 4),
        const Text(
          'Where are you headed?',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: FairRideColors.ink,
          ),
        ),
        const SizedBox(height: 16),
        const FairRideHomeInsights(isDriver: false),
        const SizedBox(height: 12),
        FairRidePrimaryButton(
          label: 'Find a ride',
          icon: Icons.search,
          onPressed: () =>
              Navigator.pushNamed(context, FairRideRoutes.requestRide),
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 20),
        const FairRideSectionTitle('Your upcoming rides'),
        const SizedBox(height: 8),
        StreamBuilder<List<Ride>>(
          stream: RideService.instance.watchMyRidesAsRider(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rides = snap.data!;
            if (rides.isEmpty) {
              return const FairRideCard(child: Text('No accepted rides yet.'));
            }
            return Column(
              children: [
                for (final ride in rides)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FairRideCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ride.startName} → ${ride.destName}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Driver ${ride.driverName} · ${ride.status == RideStatus.inProgress ? 'Ride started' : 'Driver accepted your request'} · departs ${DateFormat.yMMMd().add_jm().format(ride.departureTime)}',
                            style: const TextStyle(color: FairRideColors.muted),
                          ),
                          const SizedBox(height: 4),
                          Text('Total fare ${formatRupees(ride.totalFare)}'),
                          TextButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FairRideRideDetailsScreen(rideId: ride.id),
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
                                FairRideRoutes.fareSplit,
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
                                    fairRideSnack(context, '$e');
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
        const FairRideSectionTitle('Ride history'),
        const SizedBox(height: 8),
        StreamBuilder<List<RideHistoryItem>>(
          stream: RideService.instance.watchHistory(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data!;
            if (items.isEmpty) {
              return const FairRideCard(
                child: Text('Completed rides will appear here.'),
              );
            }
            return Column(
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FairRideCard(
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
                                    color: FairRideColors.muted,
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
                                    builder: (_) => FairRideRideDetailsScreen(
                                      rideId: item.rideId,
                                    ),
                                  ),
                                ),
                                child: const Text('Ride details'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  FairRideRoutes.fareSplit,
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

class FairRideDriverDashboardScreen extends StatelessWidget {
  const FairRideDriverDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: const FairRideAccountDrawer(isDriver: true),
    appBar: AppBar(
      title: const FairRideBrand(compact: true),
    ),
    bottomNavigationBar: fairRideBottomNav(
      context,
      selected: 0,
      role: 'driver',
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Driver dashboard',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: FairRideColors.ink,
          ),
        ),
        const SizedBox(height: 14),
        const FairRideHomeInsights(isDriver: true),
        const SizedBox(height: 12),
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
                        doc.id == key &&
                        doc.data()['imageBase64'] is String &&
                        (doc.data()['imageBase64'] as String).isNotEmpty,
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
                            builder: (_) => const FairRideDriverProfileScreen(),
                          ),
                        ),
                        child: const Text('Driver profile'),
                      ),
                    ),
                  ),
                FairRidePrimaryButton(
                  label: 'Post a ride',
                  icon: Icons.add_road,
                  onPressed: documentsReady
                      ? () => Navigator.pushNamed(
                          context,
                          FairRideRoutes.postRide,
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
              builder: (_) => const FairRideDriverProfileScreen(),
            ),
          ),
          icon: const Icon(Icons.person_outline),
          label: const Text('Driver profile and UPI'),
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 22),
        const FairRideSectionTitle('Your active rides'),
        const SizedBox(height: 8),
        StreamBuilder<List<Ride>>(
          stream: RideService.instance.watchMyRidesAsDriver(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rides = snap.data!;
            if (rides.isEmpty) {
              return const FairRideCard(
                child: Text('You have no active rides.'),
              );
            }
            return Column(
              children: [
                for (final ride in rides)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FairRideCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${ride.startName} → ${ride.destName}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${ride.seatsAvailable}/${ride.seatsTotal} seats · ${ride.riderIds.length} accepted · ${ride.status == RideStatus.inProgress ? 'Ride started' : 'Ride not started'} · ${formatRupees(ride.totalFare)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FairRideRideDetailsScreen(rideId: ride.id),
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
        const FairRideSectionTitle('Ride history'),
        const SizedBox(height: 8),
        StreamBuilder<List<RideHistoryItem>>(
          stream: RideService.instance.watchHistory(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data!;
            if (items.isEmpty) {
              return const FairRideCard(
                child: Text('Completed rides will appear here.'),
              );
            }
            return Column(
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FairRideCard(
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
                                    color: FairRideColors.muted,
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
                                    builder: (_) => FairRideRideDetailsScreen(
                                      rideId: item.rideId,
                                    ),
                                  ),
                                ),
                                child: const Text('Ride details'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  FairRideRoutes.fareSplit,
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
