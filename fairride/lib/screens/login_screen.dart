part of '../fare_ride_screens.dart';

class FareRideLoginScreen extends StatefulWidget {
  const FareRideLoginScreen({super.key});
  @override
  State<FareRideLoginScreen> createState() => _FareRideLoginScreenState();
}

class _FareRideLoginScreenState extends State<FareRideLoginScreen> {
  final _phone = TextEditingController();
  String _role = 'Rider';
  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _continue() {
    Navigator.pushNamed(
      context,
      _role == 'Driver'
          ? FareRideRoutes.driverSignup
          : FareRideRoutes.riderDashboard,
    );
  }

  @override
  Widget build(BuildContext context) => FareRidePage(
    title: 'Welcome',
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FareRideBrand(compact: true),
          const SizedBox(height: 30),
          const Text(
            'Let’s get you moving',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: FareRideColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose how you want to use FareRide.',
            style: TextStyle(color: FareRideColors.muted),
          ),
          const SizedBox(height: 26),
          const FareRideSectionTitle('I’m joining as'),
          const SizedBox(height: 12),
          Row(
            children: ['Rider', 'Driver'].map((role) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: role == 'Rider' ? 10 : 0),
                  child: _RoleTile(
                    label: role,
                    selected: _role == role,
                    onTap: () => setState(() => _role = role),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 23),
          FareRideField(
            label: 'Phone number',
            hint: 'Enter your mobile number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            controller: _phone,
            validator: fareRideRequired,
          ),
          const SizedBox(height: 10),
          const Text(
            'Demo mode: continue without phone verification.',
            style: TextStyle(fontSize: 12, color: FareRideColors.muted),
          ),
          const SizedBox(height: 25),
          FareRidePrimaryButton(
            label: 'Continue as $_role',
            onPressed: _continue,
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'By continuing, you agree to our Terms and Privacy Policy.',
              textAlign: TextAlign.center,
              style: TextStyle(color: FareRideColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: selected ? FareRideColors.mint : Colors.white,
        border: Border.all(
          color: selected ? FareRideColors.green : FareRideColors.line,
          width: selected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            label == 'Rider'
                ? Icons.person_pin_circle_outlined
                : Icons.drive_eta_outlined,
            size: 27,
            color: selected ? FareRideColors.green : FareRideColors.muted,
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? FareRideColors.greenDark : FareRideColors.ink,
            ),
          ),
        ],
      ),
    ),
  );
}
