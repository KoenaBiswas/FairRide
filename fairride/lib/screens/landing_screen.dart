part of '../fare_ride_screens.dart';

class FareRideLandingScreen extends StatelessWidget {
  const FareRideLandingScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FareRideBrand(),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              height: 320,
              decoration: BoxDecoration(
                color: FareRideColors.mint,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 25,
                    right: 24,
                    child: _bubble(Icons.location_on_rounded, 'Downtown'),
                  ),
                  Positioned(
                    bottom: 33,
                    left: 18,
                    child: _bubble(Icons.school_rounded, 'Campus'),
                  ),
                  Container(
                    width: 154,
                    height: 154,
                    decoration: BoxDecoration(
                      color: FareRideColors.green,
                      borderRadius: BorderRadius.circular(46),
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_rounded,
                      size: 82,
                      color: Colors.white,
                    ),
                  ),
                  const Positioned(
                    top: 104,
                    left: 48,
                    child: Icon(
                      Icons.route_rounded,
                      size: 38,
                      color: FareRideColors.greenDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Better rides,\nbetter together.',
              style: TextStyle(
                fontSize: 36,
                height: 1.12,
                fontWeight: FontWeight.w900,
                color: FareRideColors.ink,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Share your route, split the cost, and make every trip count.',
              style: TextStyle(
                color: FareRideColors.muted,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 26),
            FareRidePrimaryButton(
              label: 'Get started',
              icon: Icons.arrow_forward_rounded,
              onPressed: () =>
                  Navigator.pushNamed(context, FareRideRoutes.login),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, FareRideRoutes.login),
                child: const Text('I already have an account'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  static Widget _bubble(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, size: 17, color: FareRideColors.green),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: FareRideColors.ink,
          ),
        ),
      ],
    ),
  );
}
