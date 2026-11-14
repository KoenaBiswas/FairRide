part of '../fare_ride_screens.dart';

class FareRideFareSplitScreen extends StatefulWidget {
  const FareRideFareSplitScreen({super.key});
  @override
  State<FareRideFareSplitScreen> createState() =>
      _FareRideFareSplitScreenState();
}

class _FareRideFareSplitScreenState extends State<FareRideFareSplitScreen> {
  final _total = TextEditingController(text: '24.00');
  int _people = 3;
  @override
  void dispose() {
    _total.dispose();
    super.dispose();
  }

  double get _amount {
    final value = double.tryParse(_total.text) ?? 0;
    return _people == 0 ? 0 : value / _people;
  }

  @override
  Widget build(BuildContext context) => FareRidePage(
    title: 'Fare split',
    navigationIndex: 2,
    bottom: FareRidePrimaryButton(
      label: 'Share the split',
      icon: Icons.ios_share_rounded,
      onPressed: () =>
          fareRideSnack(context, 'Fare split copied and ready to share.'),
    ),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      children: [
        const Text(
          'Everyone pays less.',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: FareRideColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Split the ride fare fairly with your group.',
          style: TextStyle(color: FareRideColors.muted),
        ),
        const SizedBox(height: 20),
        FareRideCard(
          child: Column(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 36,
                color: FareRideColors.green,
              ),
              const SizedBox(height: 9),
              const Text(
                'North Campus → City Center',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Today · 5:30 PM',
                style: TextStyle(color: FareRideColors.muted, fontSize: 12),
              ),
              const Divider(height: 25),
              FareRideField(
                label: 'Total fare',
                icon: Icons.attach_money_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                controller: _total,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Split between',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: _people > 1
                        ? () => setState(() => _people--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_people',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  IconButton(
                    onPressed: _people < 8
                        ? () => setState(() => _people++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: FareRideColors.mint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Each person pays',
                      style: TextStyle(
                        color: FareRideColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '\$${_amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: FareRideColors.greenDark,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const FareRideSectionTitle('Ride group'),
        const SizedBox(height: 10),
        const _MemberTile(
          initial: 'M',
          name: 'Maya R.',
          role: 'Driver',
          amount: 'Paid',
        ),
        const SizedBox(height: 8),
        _MemberTile(
          initial: 'Y',
          name: 'You',
          role: 'Rider',
          amount: '\$${_amount.toStringAsFixed(2)}',
        ),
        const SizedBox(height: 8),
        _MemberTile(
          initial: 'J',
          name: 'Jordan K.',
          role: 'Rider',
          amount: '\$${_amount.toStringAsFixed(2)}',
        ),
      ],
    ),
  );
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.initial,
    required this.name,
    required this.role,
    required this.amount,
  });
  final String initial, name, role, amount;
  @override
  Widget build(BuildContext context) => FareRideCard(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: FareRideColors.mint,
          child: Text(
            initial,
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
                role,
                style: const TextStyle(
                  fontSize: 11,
                  color: FareRideColors.muted,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: FareRideColors.greenDark,
          ),
        ),
      ],
    ),
  );
}
