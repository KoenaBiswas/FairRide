part of '../fare_ride_screens.dart';

class FareRidePickupOrderScreen extends StatefulWidget {
  const FareRidePickupOrderScreen({super.key});
  @override
  State<FareRidePickupOrderScreen> createState() =>
      _FareRidePickupOrderScreenState();
}

class _FareRidePickupOrderScreenState extends State<FareRidePickupOrderScreen> {
  final _pickup = TextEditingController();
  final _note = TextEditingController();
  @override
  void dispose() {
    _pickup.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FareRidePage(
    title: 'Pickup details',
    navigationIndex: 0,
    bottom: FareRidePrimaryButton(
      label: 'Confirm ride',
      icon: Icons.check_rounded,
      onPressed: () {
        if (_pickup.text.trim().isEmpty) {
          fareRideSnack(context, 'Add a pickup location to continue.');
          return;
        }
        Navigator.pushNamed(context, FareRideRoutes.fareSplit);
      },
    ),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        const Text(
          'Set the pickup order',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: FareRideColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose a convenient meeting point for everyone.',
          style: TextStyle(color: FareRideColors.muted),
        ),
        const SizedBox(height: 20),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: FareRideColors.mint,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(left: 25, top: 25, child: _mapDot('A')),
              Positioned(right: 40, top: 53, child: _mapDot('B')),
              Positioned(left: 95, bottom: 22, child: _mapDot('C')),
              const Icon(
                Icons.alt_route_rounded,
                size: 92,
                color: FareRideColors.green,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FareRideField(
          label: 'Pickup address',
          hint: 'Add a meeting point',
          icon: Icons.location_on_outlined,
          controller: _pickup,
        ),
        const SizedBox(height: 14),
        const FareRideSectionTitle('Pickup sequence'),
        const SizedBox(height: 10),
        const _StopTile(
          number: '1',
          name: 'North Campus Gate',
          detail: 'Driver · 5:20 PM',
        ),
        const SizedBox(height: 8),
        const _StopTile(
          number: '2',
          name: 'Your pickup point',
          detail: 'Set above · 5:30 PM',
        ),
        const SizedBox(height: 8),
        const _StopTile(
          number: '3',
          name: 'City Center',
          detail: 'Final destination',
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _note,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Note for passengers (optional)',
            hintText: 'Look for a blue sedan…',
            alignLabelWithHint: true,
          ),
        ),
      ],
    ),
  );
  static Widget _mapDot(String label) => CircleAvatar(
    radius: 15,
    backgroundColor: Colors.white,
    child: Text(
      label,
      style: const TextStyle(
        color: FareRideColors.green,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.number,
    required this.name,
    required this.detail,
  });
  final String number, name, detail;
  @override
  Widget build(BuildContext context) => FareRideCard(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    child: Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: FareRideColors.mint,
          child: Text(
            number,
            style: const TextStyle(
              color: FareRideColors.greenDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                detail,
                style: const TextStyle(
                  color: FareRideColors.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.drag_handle_rounded, color: FareRideColors.muted),
      ],
    ),
  );
}
