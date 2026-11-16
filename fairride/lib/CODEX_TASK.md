# Task: connect the EXISTING FareRide UI to Firebase (Auth + Firestore)

Read this whole file, then read the whole repo (`fairride/lib/**`, `pubspec.yaml`, `android/**`)
before editing. Work on branch `jyoti-firebase`. Never `git push`, never touch `main` or
`logic-maps`, never commit `build/`, `.dart_tool/` or a `fairride/fairride/` folder.

**Keep Koena's UI exactly as it looks.** Do not redesign screens, colours or widgets. Only replace
demo/fake behaviour with real Firebase behaviour. Her UI is the source of truth.

## How the existing UI is built (do not fight this)
- `lib/fare_ride_screens.dart` is ONE library. Screens, theme and widgets are `part` files
  (`part 'screens/login_screen.dart';` ...) and use private classes (`_RoleTile`, `_MemberTile` ...).
  Any NEW screen must be added as another `part 'screens/xxx.dart';` + `part of '../fare_ride_screens.dart';`.
  Put all new imports (firebase, services, intl) in `fare_ride_screens.dart`, not in the part files.
- Routes live in `FareRideRoutes` (named routes). `FareRideApp` uses `initialRoute: '/'`.
- Public widgets to reuse: `FareRidePage`, `FareRideCard`, `FareRideField`, `FareRidePrimaryButton`,
  `FareRideSectionTitle`, `FareRideBrand`, `fareRideSnack`, `fareRideRequired`, `fareRideBottomNav`,
  colours in `FareRideColors`. Add small optional params (e.g. `obscure` on `FareRideField`) rather
  than new widgets.
- `lib/logic/*` (fare_calculator, rider_ordering, route_filter) and `lib/screens/pickup_map_screen.dart`
  + `logic_demo_screen.dart` are Koena's working logic. KEEP and REUSE them.
- Everything is currently fake: phone-only login with no auth, document tiles are local toggles,
  ride lists are hard-coded, the fare split is a manual `total / people` calculator.

## Facts about the Firebase project
- Project id `fareride-d30a8`, Android package `com.example.fairride`. Email/Password and Google
  sign-in are enabled in the console. Free Spark plan: NO Cloud Functions, NO Firebase Storage.
- Rides go to ANY destination (name + lat/lng). There is no fixed campus anywhere.
- Any email address (Gmail etc.) is allowed.

Files I provide (copy into the repo):
- `lib/firebase_options.dart`  (ready)
- `lib/authenticate/auth_service.dart`  (email sign up/in + Firestore `users` profile; extend it)
- `lib/models/ride_models.dart`, `lib/services/ride_service.dart` (seat-safe Firestore transactions)
- `android/app/google-services.json`
Do NOT use my `login_screen.dart`, `signup_screen.dart`, `auth_widgets.dart`, `auth_wrapper.dart`
or `services/fare_calculator.dart`. Her UI replaces them. Make `ride_service.dart` use HER
`Point`, `haversineKm` and `calculateFares` from `lib/logic/` (delete my fare_calculator copy).

## 1. Android / Gradle (Flutter style, not the console's native snippet)
1. `android/settings.gradle.kts` -> inside `plugins { }` add once:
   `id("com.google.gms.google-services") version "4.4.4" apply false`
2. `android/app/build.gradle.kts` -> inside `plugins { }` add with NO version:
   `id("com.google.gms.google-services")`
3. Do not edit `android/build.gradle.kts`. Do not add firebase-bom or analytics by hand.
4. `minSdk` >= 23. `applicationId` must be `com.example.fairride`.

## 2. Packages
Add `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`, `intl`, `geocoding`
(turns typed addresses into lat/lng with no API key), `geolocator` (current location).
`flutter_map` and `latlong2` already exist. Run `flutter pub get`. Never hand-edit `pubspec.lock`.

## 3. main.dart and the auth gate
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FareRideApp());
}
```
Exactly one `main()`. In `FareRideApp` replace `initialRoute` with `home: const FareRideAuthGate()`
and REMOVE the `landing: ...` entry from `FareRideRoutes.routes` (Flutter asserts if both `home` and
a `'/'` route exist). `FareRideAuthGate` (new part file) is a StreamBuilder on `authStateChanges`
then on the `users/{uid}` document:
- signed out -> `FareRideLandingScreen`
- signed in, email not verified -> `FareRideVerifyEmailScreen`
- verified, role rider -> `FareRideRiderDashboardScreen`
- verified, role driver and `licenseNumber` missing -> `FareRideDriverSignupScreen`
- verified, role driver -> `FareRideDriverDashboardScreen` (new)
If the profile doc does not exist yet, show a loader (it is written right after sign up).

## 4. Authentication (inside her screens)
`FareRideLoginScreen`: keep her layout and role tiles. Replace the phone field with Email + Password
(`FareRideField` needs an `obscure` option). Add a Log in / Sign up toggle. Sign up also asks Name and
Phone. Add a "Continue with Google" button styled like her widgets.
- Email sign up: `AuthService.signUp` then `sendEmailVerification()`.
- Email login: `AuthService.signIn(expectedRole: selected tile)`; wrong role shows the error.
- Google: new user picks Rider/Driver once (small new `part` screen), then the profile is created;
  existing user goes straight in. Follow the installed `google_sign_in` version's API.
- New `FareRideVerifyEmailScreen`: text, Resend, "I have verified" (calls `reload()`), Log out.
- Add a Log out action to the AppBar of both dashboards.
- Show `AuthService` error messages with `fareRideSnack`.

## 5. Firestore data
```
users/{uid}                          uid, name, email, phone, role (rider|driver), verificationStatus,
                                     createdAt; driver also: licenseNumber, vehicleNumber,
                                     vehicleModel, documentsSubmitted
users/{uid}/rideHistory/{rideId}     rideId, role, startName, destName, departureTime, amount,
                                     riders, completedAt
rides/{rideId}                       driverId, driverName, startName, startLat, startLng, destName,
                                     destLat, destLng, departureTime, seatsTotal, seatsAvailable,
                                     status (open|full|in_progress|completed|cancelled), riderIds[],
                                     totalFare, createdAt, updatedAt
rides/{rideId}/requests/{riderId}    riderId, riderName, pickupName, pickupLat, pickupLng,
                                     distanceToDestKm, status (pending|accepted|rejected|picked_up|
                                     dropped|cancelled), fare, createdAt
```
Seat counts change only inside transactions (already in `ride_service.dart`). No file uploads:
`FareRideDriverSignupScreen` keeps its two demo document tiles, but add text fields for licence
number and vehicle number, save everything to `users/{uid}`, set `documentsSubmitted: true` and
`verificationStatus: pending_review`.

## 6. Screen by screen
Addresses -> coordinates: use `geocoding` `locationFromAddress`; show a snackbar if not found.
Pass ids between screens with `Navigator.pushNamed(..., arguments: rideId)`.

**Driver**
- `post_ride_screen`: the date and time pickers currently only show a snackbar and DISCARD the value.
  Store them. Destination and start get geocoded. Relabel "Price per seat" to "Total trip fare"
  (the fare is split between riders by distance); keep the seat stepper. Publish -> `createRide`,
  then go to the driver dashboard (it currently goes to `pickupOrder`, which is a rider screen).
- New `FareRideDriverDashboardScreen`: AppBar with brand + Log out, "Post a ride" button, active
  rides (`watchMyRidesAsDriver`), last rides (`watchHistory`).
- New `FareRideManageRideScreen(rideId)`: shows pending requests with Accept / Reject
  (`acceptRequest`, `rejectRequest`), accepted riders in pickup order using her `sortFarthestFirst`
  with a "Picked up" button each (`markPickedUp`), Start ride (`startRide`), Complete ride
  (`completeRide`), and "Show on map" using her `PickupMapScreen`. Use `filterByRoute` with the
  straight line start -> destination as the route to flag requests that are too far off route.

**Rider**
- `request_ride_screen`: replace the 2 hard-coded cards with `watchOpenRides(nearLat, nearLng,
  radiusKm: 1.5)` for the typed destination. Tapping a card selects it; the bottom button needs a
  selected ride (today both the card and the button just open the fare split). Show driver name,
  departure time, seats left, destination.
- `pickup_order_screen` (this is the rider's "Pickup details"): "Confirm ride" -> geocode the pickup
  address -> `requestToJoin`. Replace the hard-coded "Pickup sequence" with the accepted riders in
  order from `watchRequests`, marking "You". After confirming open a new
  `FareRideRideStatusScreen(rideId)` driven by `watchMyRequest`: pending / accepted / rejected /
  picked up / dropped, the fare once dropped, and a Cancel button (`cancelRequest`).
- `rider_dashboard_screen`: greeting uses the user's real name. "Popular routes" becomes live open
  rides (`watchOpenRides`, top 3). "Split a recent fare" opens the latest `rideHistory` item. Add a
  "Your last rides" list (`watchHistory`).
- `fare_split_screen`: when opened with a completed `rideId`, show the real per-rider fares (rupees,
  from the `requests` documents) and the total. When opened with no argument keep the manual
  calculator as it is, but in rupees.

## 7. Logic must be consistent
Her `calculateFares(riders, legKm, totalFare)` is the fare function. Verify before wiring it: total
100 with leg lengths [4, 4, 2] km must give 66.67 / 26.67 / 6.67 for riders 1 / 2 / 3. If it
does not, fix it. `completeRide` must use it, so what the driver completes is what each rider sees.

## 8. Rupees (every amount, every screen)
Create `lib/utils/currency.dart`: `String formatRupees(num v)` using
`NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2)` and import it in
`fare_ride_screens.dart`. These spots still use dollars; fix all of them:
- `fare_split_screen`: `'\$${_amount...}'` (3 places), `Icons.attach_money_rounded`, default total '24.00'
- `post_ride_screen`: hint `'\$8.00'`, `Icons.attach_money_rounded`
- `request_ride_screen`: `'\$8.50'`, `'\$7.00'` (these cards become live data anyway)
- `rider_dashboard_screen`: `'\$8.50'`, `'\$6.00'` (become live data anyway)
Use `Icons.currency_rupee_rounded` for money fields. Placeholder amounts should be realistic rupee
values (about ₹40 to ₹250), not a dollar-to-rupee exchange conversion. Search the whole repo for
`\$`, `attach_money`, "USD" and "dollar" when done. `logic_demo_screen` already uses ₹.

## 9. Firestore rules (I paste these in the console myself)
Create `firestore.rules`:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
      match /rideHistory/{rideId} {
        allow read: if request.auth != null && request.auth.uid == uid;
        allow write: if request.auth != null;
      }
    }
    match /rides/{rideId} {
      allow read, write: if request.auth != null;
      match /requests/{riderId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

## 10. Done means
- `flutter pub get` and `flutter analyze` show no errors; the Android app builds and runs.
- The UI looks the same as before apart from the new fields and screens listed above.
- Rider and driver sign-up each create a `users` document; wrong-role login is rejected;
  the verification email is sent and the app is gated until verified; Google sign-in works.
- Driver posts a ride; rider finds it by destination, requests it; driver accepts and
  `seatsAvailable` drops by 1; a full ride leaves the open list; cancel restores the seat.
- Completing a ride saves each rider's fare and writes `rideHistory` for the driver and every rider;
  both dashboards show those past rides.
- No `$` left; all money is in rupees; one `main()`; no duplicate classes.
At the end list every file you changed and anything I must do by hand.