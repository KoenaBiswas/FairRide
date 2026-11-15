part of '../fare_ride_screens.dart';

const _farePaymentUpiId = '7291098653@pthdfc';

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

  Uri _paymentUri(double amount, String rideId) => Uri(
    scheme: 'upi',
    host: 'pay',
    queryParameters: {
      'pa': _farePaymentUpiId,
      'pn': 'FareRide',
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
      'tn': 'FareRide $rideId',
    },
  );

  Future<void> _pay(double amount, String rideId) async {
    try {
      final launched = await launchUrl(
        _paymentUri(amount, rideId),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        fareRideSnack(context, 'No UPI app could open this payment link.');
      }
    } catch (error) {
      if (mounted) fareRideSnack(context, 'Could not open a UPI app: $error');
    }
  }

  Future<void> _copyPaymentLink(double amount, String rideId) async {
    await Clipboard.setData(
      ClipboardData(text: _paymentUri(amount, rideId).toString()),
    );
    if (mounted) fareRideSnack(context, 'UPI payment link copied.');
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
            child: Center(child: Text('Could not load this ride.')),
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
                  final estimates = splitFare(
                    totalFare: ride.totalFare,
                    distances: {
                      for (final rider in riders)
                        rider.riderId: rider.distanceToDestKm,
                    },
                  );
                  return Column(
                    children: [
                      for (final rider in riders)
                        _RiderShareCard(
                          rider: rider,
                          estimate: estimates[rider.riderId] ?? 0,
                          isCurrentUser: uid == rider.riderId,
                          onCopy: (amount) => _copyPaymentLink(amount, rideId),
                          onPay: (amount) => _pay(amount, rideId),
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
                    'Payment opens in your installed UPI app. FareRide does not confirm or track the payment.',
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
    required this.onCopy,
    required this.onPay,
  });

  final RideRequest rider;
  final double estimate;
  final bool isCurrentUser;
  final ValueChanged<double> onCopy;
  final ValueChanged<double> onPay;

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
                        '${rider.pickupName} · ${rider.status}',
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
            if (isCurrentUser) ...[
              if (!isSaved)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'This share is an estimate and may change until the ride is completed.',
                    style: TextStyle(color: FareRideColors.muted, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onCopy(amount),
                      icon: const Icon(Icons.link),
                      label: Text(
                        isSaved ? 'Copy payment link' : 'Copy estimate link',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => onPay(amount),
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: Text(isSaved ? 'Pay with UPI' : 'Pay estimate'),
                    ),
                  ),
                ],
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
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No accepted or active rides yet. Accepted rides will show up here.',
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Choose a ride',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
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
              ],
            );
          },
        );
      },
    );
  }
}
