part of '../fare_ride_screens.dart';

class FareRidePostRideScreen extends StatefulWidget {
  const FareRidePostRideScreen({super.key});
  @override
  State<FareRidePostRideScreen> createState() => _FareRidePostRideScreenState();
}

class _FareRidePostRideScreenState extends State<FareRidePostRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _price = TextEditingController();
  int _seats = 2;
  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _price.dispose();
    super.dispose();
  }

  void _publish() {
    if (!_formKey.currentState!.validate()) return;
    fareRideSnack(context, 'Your ride is ready to be published.');
    Navigator.pushNamed(context, FareRideRoutes.pickupOrder);
  }

  @override
  Widget build(BuildContext context) => FareRidePage(
    title: 'Post a ride',
    navigationIndex: 0,
    bottom: FareRidePrimaryButton(
      label: 'Continue to pickup details',
      icon: Icons.arrow_forward_rounded,
      onPressed: _publish,
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share your journey',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: FareRideColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Offer your empty seats to people going your way.',
              style: TextStyle(color: FareRideColors.muted),
            ),
            const SizedBox(height: 23),
            FareRideField(
              label: 'Starting point',
              hint: 'Pickup location',
              icon: Icons.trip_origin,
              controller: _from,
              validator: fareRideRequired,
            ),
            const SizedBox(height: 12),
            FareRideField(
              label: 'Destination',
              hint: 'Where are you going?',
              icon: Icons.location_on_outlined,
              controller: _to,
              validator: fareRideRequired,
            ),
            const SizedBox(height: 12),
            FareRideCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Departure',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: FareRideColors.green,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 90),
                              ),
                              initialDate: DateTime.now(),
                            );
                            if (d != null && context.mounted) {
                              fareRideSnack(
                                context,
                                'Departure date selected.',
                              );
                            }
                          },
                          child: const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Choose date'),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.schedule_rounded,
                        color: FareRideColors.green,
                        size: 19,
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (t != null && context.mounted) {
                              fareRideSnack(
                                context,
                                'Departure time selected.',
                              );
                            }
                          },
                          child: const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Choose time'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: FareRideField(
                    label: 'Price per seat',
                    hint: '\$8.00',
                    icon: Icons.attach_money_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    controller: _price,
                    validator: fareRideRequired,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FareRideCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Seats',
                          style: TextStyle(
                            color: FareRideColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _seats > 1
                                  ? () => setState(() => _seats--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '$_seats',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            IconButton(
                              onPressed: _seats < 7
                                  ? () => setState(() => _seats++)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
