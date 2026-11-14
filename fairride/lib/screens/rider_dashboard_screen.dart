part of '../fare_ride_screens.dart';

class FareRideRiderDashboardScreen extends StatelessWidget {
  const FareRideRiderDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const FareRideBrand(compact: true),
      actions: [
        IconButton(
          onPressed: () =>
              fareRideSnack(context, 'Notifications are up to date.'),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text(
            'Good morning 👋',
            style: TextStyle(color: FareRideColors.muted),
          ),
          const SizedBox(height: 3),
          const Text(
            'Where are you headed?',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: FareRideColors.ink,
            ),
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: () =>
                Navigator.pushNamed(context, FareRideRoutes.requestRide),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: FareRideColors.line),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: FareRideColors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Search destination or route',
                      style: TextStyle(color: FareRideColors.muted),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 15),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const FareRideSectionTitle('Quick actions'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.search_rounded,
                  title: 'Find a ride',
                  subtitle: 'Share a trip',
                  onTap: () =>
                      Navigator.pushNamed(context, FareRideRoutes.requestRide),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.add_road_rounded,
                  title: 'Offer a ride',
                  subtitle: 'Drive together',
                  onTap: () =>
                      Navigator.pushNamed(context, FareRideRoutes.postRide),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.alt_route_rounded,
            title: 'Route planner',
            subtitle: 'Pickup order and fare tools',
            onTap: () =>
                Navigator.pushNamed(context, FareRideRoutes.routeTools),
          ),
          const SizedBox(height: 24),
          FareRideSectionTitle(
            'Popular routes',
            trailing: TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, FareRideRoutes.requestRide),
              child: const Text('See all'),
            ),
          ),
          const SizedBox(height: 12),
          _RouteCard(
            from: 'North Campus',
            to: 'City Center',
            time: 'Today · 5:30 PM',
            price: '\$8.50',
            seats: '2 seats',
            onTap: () =>
                Navigator.pushNamed(context, FareRideRoutes.requestRide),
          ),
          const SizedBox(height: 10),
          _RouteCard(
            from: 'Riverside',
            to: 'Tech Park',
            time: 'Today · 6:15 PM',
            price: '\$6.00',
            seats: '3 seats',
            onTap: () =>
                Navigator.pushNamed(context, FareRideRoutes.requestRide),
          ),
          const SizedBox(height: 22),
          FareRideCard(
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: FareRideColors.mint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: FareRideColors.green,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Split a recent fare',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Settle up with your ride group',
                        style: TextStyle(
                          fontSize: 12,
                          color: FareRideColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, FareRideRoutes.fareSplit),
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: FareRideColors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: fareRideBottomNav(context, selected: 0),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(19),
    child: FareRideCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: FareRideColors.green),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: FareRideColors.muted),
          ),
        ],
      ),
    ),
  );
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.from,
    required this.to,
    required this.time,
    required this.price,
    required this.seats,
    required this.onTap,
  });
  final String from, to, time, price, seats;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: FareRideCard(
      child: Row(
        children: [
          Column(
            children: [
              const Icon(Icons.circle, size: 10, color: FareRideColors.green),
              Container(width: 1, height: 25, color: FareRideColors.line),
              const Icon(
                Icons.location_on,
                size: 15,
                color: FareRideColors.green,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(from, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text(to, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  '$time · $seats',
                  style: const TextStyle(
                    color: FareRideColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: FareRideColors.greenDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const Text(
                'per seat',
                style: TextStyle(color: FareRideColors.muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
