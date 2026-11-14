# FareRide screens

The FareRide app uses one screen library: `lib/fare_ride_screens.dart`, with page files in `lib/screens/` and shared theme/widgets in `lib/fare_ride_theme.dart` and `lib/fare_ride_widgets.dart`.

`lib/main.dart` launches `FareRideApp`. Its `MaterialApp` registers `FareRideRoutes`, so the in-app navigation calls resolve to real pages.

## Flows

- Rider: landing → role login → dashboard → find a ride → fare split.
- Driver: landing → role login → driver sign-up → post a ride → pickup details → fare split.
- Dashboard bottom navigation links to Home, Find ride, and Fare split.

Authentication, uploads, ride persistence, maps, and payments remain demo UI actions and must be connected to app services for production.
