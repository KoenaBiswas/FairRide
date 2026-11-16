part of '../fare_ride_screens.dart';

class FareRideFareSplitScreen extends StatefulWidget {
  const FareRideFareSplitScreen({super.key});
  @override
  State<FareRideFareSplitScreen> createState() =>
      _FareRideFareSplitScreenState();
}

class _FareRideFareSplitScreenState extends State<FareRideFareSplitScreen> {
  bool _busy = false;
  String? _completedRide;

  Future<void> _complete(String rideId) async {
    setState(() => _busy = true);
    try {
      await RideService.instance.completeRide(rideId);
      if (mounted) setState(() => _completedRide = rideId);
    } catch (error) {
      if (mounted) fareRideSnack(context, 'Could not complete ride: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Uri _paymentUri(double amount, Ride ride) => Uri(
    scheme: 'upi',
    host: 'pay',
    queryParameters: {
      'pa': ride.driverUpiId,
      'pn': ride.driverName,
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
      'tn':
          'FareRide ${ride.id.length > 8 ? ride.id.substring(0, 8) : ride.id}',
    },
  );

  Future<void> _pay(double amount, Ride ride) async {
    if (ride.driverUpiId.isEmpty) {
      if (mounted) fareRideSnack(context, 'The driver has not added a UPI ID.');
      return;
    }
    try {
      final launched = await launchUrl(
        _paymentUri(amount, ride),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        fareRideSnack(context, 'No UPI app could open this payment link.');
      }
    } catch (error) {
      if (mounted) fareRideSnack(context, 'Could not open a UPI app: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideId =
        _completedRide ?? ModalRoute.of(context)?.settings.arguments as String?;
    if (rideId == null) {
      return const FareRidePage(
        title: 'Fare split',
        navigationIndex: 2,
        child: _RideFareChooser(),
      );
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<Ride?>(
      stream: RideService.instance.watchRide(rideId),
      builder: (context, rideSnapshot) {
        final ride = rideSnapshot.data;
        if (rideSnapshot.hasError) {
          return const FareRidePage(
            title: 'Fare split',
            child: Center(
              child: Text(
                'Could not load this ride. Check your connection and Firestore rules.',
              ),
            ),
          );
        }
        if (ride == null) {
          return const FareRidePage(
            title: 'Fare split',
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final isDriver = uid == ride.driverId;
        return FareRidePage(
          title: 'Fare split',
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Ride fare summary',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: FareRideColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${ride.startName} → ${ride.destName}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                'Total fare ${formatRupees(ride.totalFare)} · ${ride.status}',
                style: const TextStyle(color: FareRideColors.muted),
              ),
              const SizedBox(height: 18),
              const FareRideSectionTitle('Accepted rider shares'),
              const SizedBox(height: 8),
              StreamBuilder<List<RideRequest>>(
                stream: RideService.instance.watchRequests(rideId),
                builder: (context, requestSnapshot) {
                  if (requestSnapshot.hasError) {
                    return const FareRideCard(
                      child: Text('Could not load rider fares.'),
                    );
                  }
                  if (!requestSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final riders = requestSnapshot.data!
                      .where(
                        (request) =>
                            request.status == RequestStatus.accepted ||
                            request.status == RequestStatus.pickedUp ||
                            request.status == RequestStatus.dropped,
                      )
                      .toList();
                  if (riders.isEmpty) {
                    return const FareRideCard(
                      child: Text(
                        'No accepted riders yet. Accepted riders will appear here with their estimated share.',
                      ),
                    );
                  }
                  final ordered = [...riders]
                    ..sort(
                      (a, b) =>
                          b.distanceToDestKm.compareTo(a.distanceToDestKm),
                    );
                  final fareLegs = ride.roadLegKm.length >= ordered.length + 1
                      ? ride.roadLegKm.skip(1).toList()
                      : <double>[];
                  final estimates = fareLegs.length == ordered.length
                      ? calculateFares(
                          ordered.map((r) => r.riderId).toList(),
                          fareLegs,
                          ride.totalFare,
                        )
                      : splitFare(
                          totalFare: ride.totalFare,
                          distances: {
                            for (final rider in ordered)
                              rider.riderId: rider.distanceToDestKm,
                          },
                        );
                  final collected = riders
                      .where((r) => r.paymentStatus == 'confirmed')
                      .fold<double>(
                        0,
                        (total, r) =>
                            total + (r.fare ?? estimates[r.riderId] ?? 0),
                      );
                  final pending = riders.fold<double>(
                    0,
                    (total, r) =>
                        total +
                        (r.paymentStatus == 'confirmed'
                            ? 0
                            : (r.fare ?? estimates[r.riderId] ?? 0)),
                  );
                  return Column(
                    children: [
                      if (isDriver && ride.status == RideStatus.completed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: FareRideCard(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total collected ${formatRupees(collected)}',
                                ),
                                Text('Outstanding ${formatRupees(pending)}'),
                              ],
                            ),
                          ),
                        ),
                      for (final rider in riders)
                        _RiderShareCard(
                          rider: rider,
                          estimate: estimates[rider.riderId] ?? 0,
                          isCurrentUser: uid == rider.riderId,
                          onPay: (amount) => _pay(amount, ride),
                          completed: ride.status == RideStatus.completed,
                          isDriver: isDriver,
                          onConfirm: () => RideService.instance.confirmPayment(
                            rideId,
                            rider.riderId,
                          ),
                          paymentUri: ride.driverUpiId.isEmpty
                              ? ''
                              : _paymentUri(
                                  rider.fare ?? estimates[rider.riderId] ?? 0,
                                  ride,
                                ).toString(),
                          onMarkPaid: (utr) => RideService.instance.markPaid(
                            rideId,
                            rider.riderId,
                            utr: utr,
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (uid != null &&
                  isDriver &&
                  ride.status == RideStatus.inProgress) ...[
                const SizedBox(height: 16),
                FareRidePrimaryButton(
                  label: _busy
                      ? 'Saving fares…'
                      : 'Complete ride and save fares',
                  icon: Icons.check,
                  onPressed: _busy ? null : () => _complete(rideId),
                ),
              ],
              if (ride.status == RideStatus.completed &&
                  uid != null &&
                  uid != ride.driverId)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'FareRide cannot see your bank payment. The driver confirms receipt after checking their account.',
                    style: TextStyle(color: FareRideColors.muted, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RiderShareCard extends StatelessWidget {
  const _RiderShareCard({
    required this.rider,
    required this.estimate,
    required this.isCurrentUser,
    required this.onPay,
    required this.completed,
    required this.isDriver,
    required this.onConfirm,
    required this.paymentUri,
    required this.onMarkPaid,
  });

  final RideRequest rider;
  final double estimate;
  final bool isCurrentUser;
  final ValueChanged<double> onPay;
  final bool completed, isDriver;
  final VoidCallback onConfirm;
  final String paymentUri;
  final ValueChanged<String> onMarkPaid;
  @override
  Widget build(BuildContext context) {
    final amount = rider.fare ?? estimate;
    final isSaved = rider.fare != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FareRideCard(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider.riderName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${rider.pickupName} · ${requestStatusLabel(rider.status)}',
                        style: const TextStyle(color: FareRideColors.muted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatRupees(amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: FareRideColors.greenDark,
                      ),
                    ),
                    Text(
                      isSaved ? 'saved' : 'estimated',
                      style: const TextStyle(
                        fontSize: 11,
                        color: FareRideColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (completed)
              Text('Payment: ${rider.paymentStatus.replaceAll('_', ' ')}'),
            if (completed && isDriver && rider.paymentStatus == 'marked_paid')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.verified),
                  label: const Text('Confirm received'),
                ),
              ),
            if (isCurrentUser && completed) ...[
              if (paymentUri.isNotEmpty && rider.paymentStatus != 'confirmed')
                QrImageView(data: paymentUri, size: 190),
              if (rider.paymentStatus == 'unpaid')
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => onPay(amount),
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('Pay with UPI app'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final controller = TextEditingController();
                        final value = await showDialog<String>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Mark payment sent'),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                labelText: 'UTR or last 4 digits (optional)',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, controller.text),
                                child: const Text('I have paid'),
                              ),
                            ],
                          ),
                        );
                        controller.dispose();
                        if (value != null) onMarkPaid(value);
                      },
                      child: const Text('I have paid'),
                    ),
                  ],
                ),
              const Text(
                'FareRide cannot see your bank payment. The driver confirms receipt after checking their account.',
                style: TextStyle(color: FareRideColors.muted, fontSize: 12),
              ),
            ],
            if (isCurrentUser && !completed) ...[
              if (!isSaved)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'This share is an estimate and may change until the ride is completed.',
                    style: TextStyle(color: FareRideColors.muted, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'Payment becomes available after the driver completes the ride.',
                style: TextStyle(color: FareRideColors.muted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RideFareChooser extends StatelessWidget {
  const _RideFareChooser();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Sign in to view ride fares.'));
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: AuthService.instance.userDoc(uid),
      builder: (context, profile) {
        if (profile.hasError) {
          return Center(
            child: Text('Could not load your profile: ${profile.error}'),
          );
        }
        if (!profile.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final role = profile.data?.data()?['role'];
        final rides = role == 'driver'
            ? RideService.instance.watchMyRidesAsDriver()
            : RideService.instance.watchMyRidesAsRider();
        return StreamBuilder<List<Ride>>(
          stream: rides,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Could not load rides: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Current and recent rides',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                if (snapshot.data!.isNotEmpty)
                  for (final ride in snapshot.data!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FareRideCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${ride.startName} → ${ride.destName}'),
                          subtitle: Text(
                            '${ride.status} · ${formatRupees(ride.totalFare)}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            FareRideRoutes.fareSplit,
                            arguments: ride.id,
                          ),
                        ),
                      ),
                    ),
                if (snapshot.data!.isEmpty) _RecentRideHistory(),
                const SizedBox(height: 12),
                const _QuickFareCalculator(),
              ],
            );
          },
        );
      },
    );
  }
}

class _RecentRideHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) => StreamBuilder<List<RideHistoryItem>>(
    stream: RideService.instance.watchHistory(limit: 1),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Text('Could not load ride history: ${snapshot.error}');
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.data!.isEmpty) {
        return Column(
          children: [
            const Text('No current or previous rides yet.'),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, FareRideRoutes.requestRide),
              child: const Text('Find or post a ride'),
            ),
          ],
        );
      }
      final ride = snapshot.data!.first;
      return FareRideCard(
        child: ListTile(
          title: Text('${ride.startName} → ${ride.destName}'),
          subtitle: Text('Last ride · ${formatRupees(ride.amount)}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(
            context,
            FareRideRoutes.fareSplit,
            arguments: ride.rideId,
          ),
        ),
      );
    },
  );
}

class _QuickFareCalculator extends StatefulWidget {
  const _QuickFareCalculator();
  @override
  State<_QuickFareCalculator> createState() => _QuickFareCalculatorState();
}

class _QuickFareCalculatorState extends State<_QuickFareCalculator> {
  final _total = TextEditingController(text: '100');
  final _distances = TextEditingController(text: '10, 6, 2');
  Map<String, double>? _shares;
  @override
  void dispose() {
    _total.dispose();
    _distances.dispose();
    super.dispose();
  }

  void _calculate() {
    final ds = _distances.text
        .split(',')
        .map((v) => double.tryParse(v.trim()))
        .whereType<double>()
        .toList();
    final amount = double.tryParse(_total.text) ?? 0;
    setState(
      () => _shares = splitFare(
        totalFare: amount,
        distances: {
          for (var i = 0; i < ds.length; i++) 'Rider ${i + 1}': ds[i],
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: const Text('Quick calculator'),
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _total,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total fare',
                prefixText: '₹ ',
              ),
            ),
            TextField(
              controller: _distances,
              decoration: const InputDecoration(
                labelText: 'Distance to destination (km, comma separated)',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
            ),
            if (_shares != null)
              for (final entry in _shares!.entries)
                ListTile(
                  title: Text(entry.key),
                  trailing: Text(formatRupees(entry.value)),
                ),
          ],
        ),
      ),
    ],
  );
}
