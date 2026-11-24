part of '../fair_ride_screens.dart';

class FairRideLandingScreen extends StatelessWidget {
  const FairRideLandingScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FairRideBrand(),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              height: 320,
              decoration: BoxDecoration(
                color: FairRideColors.mint,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _LandingRoutePainter()),
                  ),
                  Positioned(
                    top: 25,
                    right: 24,
                    child: _bubble(
                      Icons.location_on_rounded,
                      'Your destination',
                    ),
                  ),
                  Positioned(
                    bottom: 33,
                    left: 18,
                    child: _bubble(Icons.trip_origin_rounded, 'Your pickup'),
                  ),
                  Container(
                    width: 154,
                    height: 154,
                    decoration: BoxDecoration(
                      color: FairRideColors.green,
                      borderRadius: BorderRadius.circular(46),
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_rounded,
                      size: 82,
                      color: Colors.white,
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
                color: FairRideColors.ink,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Share your route, split the cost, and make every trip count.',
              style: TextStyle(
                color: FairRideColors.muted,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 26),
            FairRidePrimaryButton(
              label: 'Get started',
              icon: Icons.arrow_forward_rounded,
              onPressed: () =>
                  Navigator.pushNamed(context, FairRideRoutes.login),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, FairRideRoutes.login),
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
        Icon(icon, size: 17, color: FairRideColors.green),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: FairRideColors.ink,
          ),
        ),
      ],
    ),
  );
}

class _LandingRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pickupWidth = _bubbleWidth('Your pickup');
    final destinationWidth = _bubbleWidth('Your destination');
    final pickup = Offset(18 + pickupWidth, size.height - 33 - 17.5);
    final destination = Offset(size.width - 24 - destinationWidth, 25 + 17.5);
    final center = Offset(size.width / 2, size.height / 2);
    const carHalfSize = 77.0;
    final carEntry = Offset(center.dx - carHalfSize, center.dy);
    final carExit = Offset(center.dx + carHalfSize, center.dy);

    final route = ui.Path()
      ..moveTo(pickup.dx, pickup.dy)
      ..cubicTo(
        pickup.dx - 22,
        pickup.dy - 4,
        carEntry.dx - 14,
        carEntry.dy + 28,
        carEntry.dx,
        carEntry.dy,
      )
      ..cubicTo(
        center.dx - 30,
        center.dy + 43,
        center.dx + 30,
        center.dy - 43,
        carExit.dx,
        carExit.dy,
      )
      ..cubicTo(
        carExit.dx + 28,
        carExit.dy - 24,
        destination.dx - 16,
        destination.dy + 22,
        destination.dx,
        destination.dy,
      );

    canvas.drawPath(
      route,
      Paint()
        ..color = FairRideColors.greenDark.withAlpha(145)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  double _bubbleWidth(String label) {
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    return 12 + 17 + 6 + text.width + 12;
  }

  @override
  bool shouldRepaint(covariant _LandingRoutePainter oldDelegate) => false;
}

