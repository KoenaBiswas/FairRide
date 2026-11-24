part of '../fair_ride_screens.dart';

class FairRideAccountDrawer extends StatelessWidget {
  const FairRideAccountDrawer({super.key, required this.isDriver});

  final bool isDriver;

  void _open(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            if (uid == null)
              const DrawerHeader(child: FairRideBrand())
            else
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: AuthService.instance.userDoc(uid),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() ?? {};
                  return UserAccountsDrawerHeader(
                    margin: EdgeInsets.zero,
                    decoration: const BoxDecoration(
                      color: FairRideColors.greenDark,
                    ),
                    accountName: Text(
                      data['name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? (isDriver ? 'Driver' : 'Rider'),
                    ),
                    accountEmail: Text(
                      data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '',
                    ),
                    currentAccountPicture: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: FairRideColors.greenDark),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('My profile'),
              onTap: () => _open(
                context,
                isDriver
                    ? const FairRideDriverProfileScreen()
                    : const FairRideRiderProfileScreen(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.route_outlined),
              title: const Text('Previous rides'),
              onTap: () => _open(
                context,
                const FairRideHistoryScreen(transactionsOnly: false),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Previous transactions'),
              onTap: () => _open(
                context,
                const FairRideHistoryScreen(transactionsOnly: true),
              ),
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () => fairRideSignOut(context),
            ),
          ],
        ),
      ),
    );
  }
}

class FairRideRiderProfileScreen extends StatelessWidget {
  const FairRideRiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Sign in to continue.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: AuthService.instance.userDoc(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Could not load profile: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data() ?? {};
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 34)),
              const SizedBox(height: 12),
              Text(
                data['name'] ?? 'Rider',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              FairRideCard(
                child: Column(
                  children: [
                    _AccountDetailRow(icon: Icons.email_outlined, label: 'Email', value: data['email'] ?? ''),
                    _AccountDetailRow(icon: Icons.phone_outlined, label: 'Phone', value: data['phone'] ?? ''),
                    _AccountDetailRow(icon: Icons.badge_outlined, label: 'Role', value: 'Rider'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const FairRideSectionTitle('Your travel and payment history'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const FairRideHistoryScreen(transactionsOnly: false),
                  ),
                ),
                icon: const Icon(Icons.route_outlined),
                label: const Text('Previous rides'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const FairRideHistoryScreen(transactionsOnly: true),
                  ),
                ),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Previous transactions'),
              ),
              const SizedBox(height: 16),
              FairRideHomeInsights(isDriver: false),
            ],
          );
        },
      ),
    );
  }
}

class FairRideHistoryScreen extends StatelessWidget {
  const FairRideHistoryScreen({super.key, required this.transactionsOnly});

  final bool transactionsOnly;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(transactionsOnly ? 'Previous transactions' : 'Previous rides'),
    ),
    body: StreamBuilder<List<RideHistoryItem>>(
      stream: RideService.instance.watchHistory(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Could not load history: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return Center(
            child: Text(
              transactionsOnly
                  ? 'Your past transactions will appear here after a ride.'
                  : 'Your completed rides will appear here.',
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FairRideCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Icon(
                        transactionsOnly
                            ? Icons.currency_rupee
                            : Icons.route_outlined,
                      ),
                    ),
                    title: Text('${item.startName} → ${item.destName}'),
                    subtitle: Text(
                      transactionsOnly
                          ? item.role == 'driver'
                              ? 'Fare allocation · ${DateFormat.yMMMd().format(item.completedAt)}'
                              : 'Payment ${item.paymentStatus.replaceAll('_', ' ')} · ${DateFormat.yMMMd().format(item.completedAt)}'
                          : '${DateFormat.yMMMd().format(item.completedAt)} · ${item.riders > 0 ? '${item.riders} riders' : 'Completed ride'}',
                    ),
                    trailing: Text(
                      formatRupees(item.amount),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => FairRideRideDetailsScreen(rideId: item.rideId),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class FairRideHomeInsights extends StatelessWidget {
  const FairRideHomeInsights({super.key, required this.isDriver});

  final bool isDriver;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<RideHistoryItem>>(
    stream: RideService.instance.watchHistory(limit: 100),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const FairRideCard(
          child: Text('Could not load your trip and payment insights.'),
        );
      }
      if (!snapshot.hasData) {
        return const FairRideCard(
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final history = snapshot.data!;
      final allocatedAmount = history.fold<double>(
        0,
        (total, item) => total + item.amount,
      );
      final totalRiders = history.fold<int>(0, (total, item) => total + item.riders);
      final confirmedItems = history
          .where((item) => item.paymentStatus == 'confirmed')
          .toList();
      final paid = confirmedItems.length;
      final confirmedAmount = confirmedItems.fold<double>(
        0,
        (total, item) => total + item.amount,
      );
      final average = history.isEmpty ? 0.0 : allocatedAmount / history.length;
      final headline = isDriver
          ? '${history.length} completed trips · $totalRiders riders served'
          : '${history.length} completed trips · $paid payments confirmed';
      final amountLabel = isDriver ? 'Fares allocated' : 'Confirmed payments';
      final amountValue = isDriver ? allocatedAmount : confirmedAmount;
      return FairRideCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDriver ? 'Your driving snapshot' : 'Your travel snapshot',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(headline, style: const TextStyle(color: FairRideColors.muted)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _InsightMetric(
                    label: amountLabel,
                    value: formatRupees(amountValue),
                    icon: Icons.currency_rupee,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InsightMetric(
                    label: isDriver ? 'Average per trip' : 'Average fare',
                    value: formatRupees(average),
                    icon: Icons.insights_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              history.isEmpty
                  ? isDriver
                      ? 'Post your first ride to see your trip and fare insights here.'
                      : 'Complete a ride to see your travel and payment insights here.'
                  : isDriver
                      ? 'Amounts show fare allocations from completed rides.'
                      : '$paid of ${history.length} payments confirmed by drivers.',
              style: const TextStyle(fontSize: 12, color: FairRideColors.muted),
            ),
          ],
        ),
      );
    },
  );
}

class _InsightMetric extends StatelessWidget {
  const _InsightMetric({required this.label, required this.value, required this.icon});

  final String label, value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: FairRideColors.mint,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: FairRideColors.greenDark),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(fontSize: 11, color: FairRideColors.muted)),
      ],
    ),
  );
}

class _AccountDetailRow extends StatelessWidget {
  const _AccountDetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 20, color: FairRideColors.greenDark),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Text(label, style: const TextStyle(color: FairRideColors.muted)),
        ),
        Expanded(child: Text(value.isEmpty ? 'Not provided' : value)),
      ],
    ),
  );
}
