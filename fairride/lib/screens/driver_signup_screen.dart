part of '../fair_ride_screens.dart';

class FairRideDriverSignupScreen extends StatelessWidget {
  const FairRideDriverSignupScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const FairRideLoginScreen(initialRole: 'driver', initialSignup: true);
}
