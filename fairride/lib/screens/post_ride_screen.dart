part of '../fair_ride_screens.dart';

class FairRidePostRideScreen extends StatefulWidget {
  const FairRidePostRideScreen({super.key});
  @override
  State<FairRidePostRideScreen> createState() => _FairRidePostRideScreenState();
}

class _FairRidePostRideScreenState extends State<FairRidePostRideScreen> {
  final _form = GlobalKey<FormState>();
  final _fare = TextEditingController(text: '150');
  LocationChoice? _start;
  LocationChoice? _destination;
  DateTime _departure = DateTime.now().add(const Duration(hours: 1));
  int _seats = 2;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final value = await RecentStore.instance.rideDefaults();
    if (!mounted) return;
    setState(() {
      _seats = value.seats.clamp(1, 6);
      _fare.text = value.fare.toStringAsFixed(0);
    });
  }

  @override
  void dispose() {
    _fare.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_form.currentState!.validate()) return;
    if (_start == null || _destination == null) {
      fairRideSnack(
        context,
        'Choose a starting point and destination from the place options.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final rideId = await RideService.instance.createRide(
        startName: _start!.name,
        startLat: _start!.latitude,
        startLng: _start!.longitude,
        destName: _destination!.name,
        destLat: _destination!.latitude,
        destLng: _destination!.longitude,
        departureTime: _departure,
        seats: _seats,
        totalFare: double.parse(_fare.text),
      );
      await RecentStore.instance.saveRideDefaults(
        seats: _seats,
        fare: double.parse(_fare.text),
      );
      await RecentStore.instance.savePlace(
        label: _start!.name,
        latitude: _start!.latitude,
        longitude: _start!.longitude,
      );
      await RecentStore.instance.savePlace(
        label: _destination!.name,
        latitude: _destination!.latitude,
        longitude: _destination!.longitude,
      );
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        FairRideRoutes.pickupOrder,
        arguments: rideId,
      );
    } catch (error) {
      if (mounted) fairRideSnack(context, 'Could not post ride: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseDeparture() async {
    final day = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: _departure,
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departure),
    );
    if (time == null || !mounted) return;
    setState(
      () => _departure = DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FairRidePage(
    title: 'Post a ride',
    navigationIndex: 1,
    role: 'driver',
    bottom: FairRidePrimaryButton(
      label: _busy ? 'Publishing…' : 'Publish ride',
      icon: Icons.check_rounded,
      onPressed: _busy ? null : _publish,
    ),
    child: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          const Text(
            'Share your journey',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: FairRideColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Search for a place or use your current location. Select a result to save its coordinates.',
            style: TextStyle(color: FairRideColors.muted),
          ),
          const SizedBox(height: 20),
          LocationPickerField(
            label: 'Starting point',
            onSelected: (place) => setState(() => _start = place),
          ),
          const SizedBox(height: 14),
          LocationPickerField(
            label: 'Destination',
            onSelected: (place) => setState(() => _destination = place),
          ),
          const SizedBox(height: 14),
          FairRideCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule, color: FairRideColors.green),
              title: const Text('Departure'),
              subtitle: Text(DateFormat.yMMMd().add_jm().format(_departure)),
              trailing: const Icon(Icons.edit),
              onTap: _chooseDeparture,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FairRideField(
                  label: 'Total ride fare',
                  hint: '150.00',
                  controller: _fare,
                  prefixText: '₹ ',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      (double.tryParse(value ?? '') ?? -1) <= 0
                      ? 'Enter a fare above ₹0'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FairRideCard(
                  child: Column(
                    children: [
                      const Text(
                        'Seats',
                        style: TextStyle(color: FairRideColors.muted),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _seats > 1
                                ? () => setState(() => _seats--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('$_seats'),
                          IconButton(
                            onPressed: _seats < 6
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
  );
}
