// FareRide app root, screen routes, and shared screen library.

import 'package:flutter/material.dart';

import 'screens/logic_demo_screen.dart';

part 'fare_ride_theme.dart';
part 'fare_ride_widgets.dart';
part 'screens/landing_screen.dart';
part 'screens/login_screen.dart';
part 'screens/driver_signup_screen.dart';
part 'screens/rider_dashboard_screen.dart';
part 'screens/post_ride_screen.dart';
part 'screens/request_ride_screen.dart';
part 'screens/pickup_order_screen.dart';
part 'screens/fare_split_screen.dart';

class FareRideApp extends StatelessWidget {
  const FareRideApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FareRide',
    debugShowCheckedModeBanner: false,
    theme: _fareRideTheme,
    initialRoute: FareRideRoutes.landing,
    routes: FareRideRoutes.routes,
  );
}

abstract final class FareRideRoutes {
  static const landing = '/';
  static const login = '/login';
  static const driverSignup = '/driver-signup';
  static const riderDashboard = '/rider';
  static const postRide = '/post-ride';
  static const requestRide = '/request-ride';
  static const pickupOrder = '/pickup-order';
  static const fareSplit = '/fare-split';
  static const routeTools = '/route-tools';

  static Map<String, WidgetBuilder> get routes => {
    landing: (_) => const FareRideLandingScreen(),
    login: (_) => const FareRideLoginScreen(),
    driverSignup: (_) => const FareRideDriverSignupScreen(),
    riderDashboard: (_) => const FareRideRiderDashboardScreen(),
    postRide: (_) => const FareRidePostRideScreen(),
    requestRide: (_) => const FareRideRequestRideScreen(),
    pickupOrder: (_) => const FareRidePickupOrderScreen(),
    fareSplit: (_) => const FareRideFareSplitScreen(),
    routeTools: (_) => const LogicDemoScreen(),
  };
}
