// FairRide app root, screen routes, and shared screen library.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import 'dart:convert';

import 'authenticate/auth_service.dart';
import 'authenticate/auth_widgets.dart'
    show
        AuthScaffold,
        AuthTextField,
        RoleSwitch,
        PrimaryButton,
        ErrorBanner,
        validateEmail,
        validatePassword,
        validatePhone,
        validateName;
import 'models/ride_models.dart';
import 'services/ride_service.dart';
import 'services/routing_service.dart';
import 'services/recent_store.dart';
import 'logic/rider_ordering.dart' as ordering;
import 'utils/currency.dart';
import 'authenticate/auth_wrapper.dart';
import 'screens/pickup_map_screen.dart';

import 'package:intl/intl.dart';

import 'widgets/location_picker_field.dart';
import 'logic/fare_calculator.dart';

part 'fair_ride_theme.dart';
part 'fair_ride_widgets.dart';
part 'screens/landing_screen.dart';
part 'screens/login_screen.dart';
part 'screens/driver_signup_screen.dart';
part 'screens/rider_dashboard_screen.dart';
part 'screens/post_ride_screen.dart';
part 'screens/request_ride_screen.dart';
part 'screens/pickup_order_screen.dart';
part 'screens/fare_split_screen.dart';
part 'screens/ride_details_screen.dart';
part 'screens/driver_profile_screen.dart';
part 'screens/admin_review_screen.dart';
part 'screens/account_screen.dart';

class FairRideApp extends StatelessWidget {
  const FairRideApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FairRide',
    debugShowCheckedModeBanner: false,
    theme: _fairRideTheme,
    home: const AuthWrapper(),
    routes: FairRideRoutes.routes,
  );
}

abstract final class FairRideRoutes {
  static const landing = '/';
  static const login = '/login';
  static const driverSignup = '/driver-signup';
  static const riderDashboard = '/rider';
  static const driverDashboard = '/driver';
  static const postRide = '/post-ride';
  static const requestRide = '/request-ride';
  static const pickupOrder = '/pickup-order';
  static const fareSplit = '/fare-split';
  static const authGate = '/auth-gate';

  static Map<String, WidgetBuilder> get routes => {
    // landing: (_) => const FairRideLandingScreen(),
    login: (_) => const FairRideLoginScreen(),
    driverSignup: (_) =>
        const FairRideLoginScreen(initialRole: 'driver', initialSignup: true),
    riderDashboard: (_) => const FairRideRiderDashboardScreen(),
    driverDashboard: (_) => const FairRideDriverDashboardScreen(),
    postRide: (_) => const FairRidePostRideScreen(),
    requestRide: (_) => const FairRideRequestRideScreen(),
    pickupOrder: (_) => const FairRidePickupOrderScreen(),
    fareSplit: (_) => const FairRideFareSplitScreen(),
    authGate: (_) => const AuthWrapper(),
  };
}
