part of 'fare_ride_screens.dart';

abstract final class FareRideColors {
  static const ink = Color(0xFF172B2A);
  static const muted = Color(0xFF71817E);
  static const green = Color(0xFF16866F);
  static const greenDark = Color(0xFF116B59);
  static const mint = Color(0xFFE8F5F0);
  static const canvas = Color(0xFFF7F9F7);
  static const line = Color(0xFFE4EAE6);
  static const amber = Color(0xFFFFF3D8);
}

final ThemeData _fareRideTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: FareRideColors.canvas,
  colorScheme: ColorScheme.fromSeed(
    seedColor: FareRideColors.green,
    primary: FareRideColors.green,
    surface: Colors.white,
  ),
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: FareRideColors.canvas,
    foregroundColor: FareRideColors.ink,
    elevation: 0,
    centerTitle: false,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: FareRideColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: FareRideColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: FareRideColors.green, width: 1.5),
    ),
  ),
);
