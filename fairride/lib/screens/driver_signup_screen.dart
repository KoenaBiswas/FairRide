part of '../fare_ride_screens.dart';

class FareRideDriverSignupScreen extends StatefulWidget {
  const FareRideDriverSignupScreen({super.key});
  @override
  State<FareRideDriverSignupScreen> createState() =>
      _FareRideDriverSignupScreenState();
}

class _FareRideDriverSignupScreenState
    extends State<FareRideDriverSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _vehicle = TextEditingController();
  bool _licenseAdded = false;
  bool _registrationAdded = false;
  @override
  void dispose() {
    _name.dispose();
    _vehicle.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_licenseAdded || !_registrationAdded) {
      fareRideSnack(
        context,
        'Add your license and vehicle registration to continue.',
      );
      return;
    }
    Navigator.pushReplacementNamed(context, FareRideRoutes.postRide);
  }

  @override
  Widget build(BuildContext context) => FareRidePage(
    title: 'Driver sign-up',
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A few details first',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: FareRideColors.ink,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Set up your driver profile to offer rides.',
              style: TextStyle(color: FareRideColors.muted),
            ),
            const SizedBox(height: 22),
            FareRideField(
              label: 'Full name',
              hint: 'As shown on your license',
              icon: Icons.person_outline,
              controller: _name,
              validator: fareRideRequired,
            ),
            const SizedBox(height: 13),
            FareRideField(
              label: 'Vehicle make and model',
              hint: 'e.g. Toyota Corolla',
              icon: Icons.directions_car_outlined,
              controller: _vehicle,
              validator: fareRideRequired,
            ),
            const SizedBox(height: 20),
            const FareRideSectionTitle('Required documents'),
            const SizedBox(height: 12),
            _DocumentTile(
              title: 'Driver’s license',
              added: _licenseAdded,
              onTap: () => setState(() => _licenseAdded = !_licenseAdded),
            ),
            const SizedBox(height: 10),
            _DocumentTile(
              title: 'Vehicle registration',
              added: _registrationAdded,
              onTap: () =>
                  setState(() => _registrationAdded = !_registrationAdded),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: FareRideColors.amber,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF976512)),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Document upload is shown as a local demo action. Connect your secure upload flow before launch.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: FareRideColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FareRidePrimaryButton(
              label: 'Save and continue',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    ),
  );
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.title,
    required this.added,
    required this.onTap,
  });
  final String title;
  final bool added;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FareRideCard(
    padding: EdgeInsets.zero,
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(
          added ? Icons.check_circle : Icons.upload_file_rounded,
          color: added ? FareRideColors.green : FareRideColors.muted,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          added ? 'Added for this demo' : 'Tap to add a document',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Icon(added ? Icons.close : Icons.add_rounded),
        onTap: onTap,
      ),
    ),
  );
}
