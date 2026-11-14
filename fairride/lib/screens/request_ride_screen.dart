part of '../fare_ride_screens.dart';

class FareRideRequestRideScreen extends StatefulWidget {
  const FareRideRequestRideScreen({super.key});
  @override
  State<FareRideRequestRideScreen> createState() =>
      _FareRideRequestRideScreenState();
}

class _FareRideRequestRideScreenState extends State<FareRideRequestRideScreen> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  void _request() {
    if (_from.text.trim().isEmpty || _to.text.trim().isEmpty) {
      fareRideSnack(context, 'Enter your pickup and destination first.');
      return;
    }
    fareRideSnack(context, 'Ride request sent.');
    Navigator.pushNamed(context, FareRideRoutes.fareSplit);
  }

  void _selectRide() {
    Navigator.pushNamed(context, FareRideRoutes.fareSplit);
  }

  @override
  Widget build(BuildContext context) => FareRidePage(
    title: 'Find a ride',
    navigationIndex: 1,
    bottom: FareRidePrimaryButton(
      label: 'Request this ride',
      icon: Icons.arrow_forward_rounded,
      onPressed: _request,
    ),
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
          'Find a seat on a route that works for you.',
          style: TextStyle(color: FareRideColors.muted),
        ),
        const SizedBox(height: 20),
        FareRideField(
          label: 'Pickup location',
          hint: 'Enter pickup point',
          icon: Icons.trip_origin,
          controller: _from,
        ),
        const SizedBox(height: 12),
        FareRideField(
          label: 'Destination',
          hint: 'Where are you going?',
          icon: Icons.location_on_outlined,
          controller: _to,
        ),
        const SizedBox(height: 12),
        FareRideCard(
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: FareRideColors.green,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Travel date',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    initialDate: DateTime.now(),
                  );
                  if (d != null && context.mounted) {
                    fareRideSnack(context, 'Travel date selected.');
                  }
                },
                child: const Text('Today'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 23),
        const FareRideSectionTitle(
          'Available rides',
          trailing: Text(
            '2 found',
            style: TextStyle(fontSize: 12, color: FareRideColors.muted),
          ),
        ),
        const SizedBox(height: 12),
        _AvailableRideCard(
          name: 'Maya R.',
          rating: '4.9',
          time: '5:30 PM',
          seats: '2 seats left',
          price: '\$8.50',
          onTap: _selectRide,
        ),
        const SizedBox(height: 10),
        _AvailableRideCard(
          name: 'Jordan K.',
          rating: '4.8',
          time: '6:10 PM',
          seats: '1 seat left',
          price: '\$7.00',
          onTap: _selectRide,
        ),
      ],
    ),
  );
}

class _AvailableRideCard extends StatelessWidget {
  const _AvailableRideCard({
    required this.name,
    required this.rating,
    required this.time,
    required this.seats,
    required this.price,
    required this.onTap,
  });
  final String name, rating, time, seats, price;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: FareRideCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: FareRideColors.mint,
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: FareRideColors.greenDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFE6A72F),
                        ),
                        Text(
                          ' $rating · $seats',
                          style: const TextStyle(
                            fontSize: 11,
                            color: FareRideColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: FareRideColors.greenDark,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 17,
                color: FareRideColors.green,
              ),
              const SizedBox(width: 7),
              Text(
                'Departs $time',
                style: const TextStyle(
                  fontSize: 12,
                  color: FareRideColors.muted,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select ride',
                    style: TextStyle(
                      color: FareRideColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: FareRideColors.green,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
