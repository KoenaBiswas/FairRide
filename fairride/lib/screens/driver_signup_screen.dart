part of '../fare_ride_screens.dart';

class FareRideDriverSignupScreen extends StatelessWidget {
  const FareRideDriverSignupScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const FareRideLoginScreen(initialRole: 'driver', initialSignup: true);
}
