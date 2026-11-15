# Task: connect FareRide (Flutter) to Firebase and wire all the logic

Read this whole file, then read the entire repo before changing anything.
Work on a new branch `jyoti-firebase`. Never run `git push`, never touch `main`
or `logic-maps`, never commit `build/`, `.dart_tool/` or any `fairride/fairride/` folder.

## Context
- Flutter app in `fairride/`. Koena's UI and logic already exist:
  `lib/screens/*`, `lib/fare_ride_*.dart`, `lib/logic/*` (fare_calculator, rider_ordering, route_filter).
  KEEP her designs and logic; only connect them to Firebase.
- Firebase project: `fareride-d30a8`. Android package: `com.example.fairride`.
  Email/Password and Google sign-in are already enabled in the console.
- Free Spark plan only: NO Cloud Functions, NO Firebase Storage, NO paid APIs.
- The destination of a ride is ANY place (name + lat/lng). It is not a fixed campus.
- Login/signup works with any email address (Gmail etc.), no college-domain check.

Files I am giving you (copy into the repo, then adapt):
- `lib/firebase_options.dart`  (ready to use)
- `lib/authenticate/*`  AuthService (sign up / sign in / Firestore user profile), widgets, wrapper
- `lib/models/ride_models.dart`, `lib/services/ride_service.dart`, `lib/services/fare_calculator.dart`
- `android/app/google-services.json`  (place at `fairride/android/app/google-services.json`)

## 1. Android / Gradle (Flutter style, NOT the native-Android console snippet)
The console snippet shows the plugin in the root `build.gradle.kts` with version 4.6.0 and the
Firebase BoM + analytics. Do NOT do that: it causes "plugin is already on the classpath with a
different version". Instead:
1. `android/settings.gradle.kts` -> inside `plugins { }` add ONCE:
   `id("com.google.gms.google-services") version "4.4.4" apply false`
2. `android/app/build.gradle.kts` -> inside `plugins { }` add, with NO version:
   `id("com.google.gms.google-services")`
3. Do not edit `android/build.gradle.kts`. Do not add firebase-bom or firebase-analytics by hand
   (the FlutterFire plugins pull what they need).
4. `minSdk` must be 23 or higher. Confirm `applicationId` is `com.example.fairride`.

## 2. Packages
Add: `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`, `intl`.
Run `flutter pub get`. Never hand-edit `pubspec.lock`.

## 3. Startup
`main()` must be `async`, call `WidgetsFlutterBinding.ensureInitialized()`, then
`Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`, then run Koena's app.
There must be exactly one `main()`. Put an auth gate at the top: signed out -> her landing/login,
signed in -> the home for the user's role (rider dashboard or driver dashboard).

## 4. Authentication (wire into HER screens)
Duplicate class names will not compile (both sides have a `LoginScreen`). Keep HER UI screens and
call `AuthService` from them; delete or rename my duplicate screens in `lib/authenticate`.
- Email/password sign up with role `rider` or `driver`; login checks the role matches.
- After sign up call `sendEmailVerification()`. Until `emailVerified` is true, show a
  "Verify your email" screen with Resend and "I have verified" (calls `reload()`), then continue.
- Google sign-in: a new Google user picks Rider or Driver once, then the `users/{uid}` document is
  created; existing users go straight in. Follow the API of the installed `google_sign_in` version.
- Log out button on both dashboards.

## 5. Firestore data (all of it)
```
users/{uid}                          uid, name, email, phone, role (rider|driver),
                                     verificationStatus, createdAt
                                     driver only: licenseNumber, vehicleNumber, vehicleModel
users/{uid}/rideHistory/{rideId}     rideId, role, startName, destName, departureTime,
                                     amount, riders, completedAt
rides/{rideId}                       driverId, driverName, startName, startLat, startLng,
                                     destName, destLat, destLng, departureTime, seatsTotal,
                                     seatsAvailable, status (open|full|in_progress|completed|
                                     cancelled), riderIds[], totalFare, createdAt, updatedAt
rides/{rideId}/requests/{riderId}    riderId, riderName, pickupName, pickupLat, pickupLng,
                                     distanceToDestKm, status (pending|accepted|rejected|
                                     picked_up|dropped|cancelled), fare, createdAt
```
Seat counts change ONLY inside Firestore transactions (already written in `ride_service.dart`).
Driver sign-up: do not upload files (no Storage). Save the text fields above and set
`verificationStatus: pending_review`.

## 6. Replace demo data with live data in her screens
- post_ride_screen -> `RideService.createRide` (destination name + lat/lng, seats, total fare in rupees)
- request_ride_screen -> `watchOpenRides(nearLat, nearLng)` then `requestToJoin`
- pickup_order_screen / pickup_map_screen -> `watchRequests` (already farthest-first),
  `acceptRequest`, `rejectRequest`, `markPickedUp`, `startRide`
- fare_split_screen -> `completeRide`, then show each rider's saved fare
- rider_dashboard_screen -> `watchMyRidesAsRider` and `watchHistory` (last rides)
- driver dashboard -> `watchMyRidesAsDriver` and `watchHistory`
Keep her `lib/logic/*`. If her `fare_calculator.dart` and `lib/services/fare_calculator.dart`
both exist, keep ONE. It must return 66.67 / 26.67 / 6.67 for total 100 and distances 10, 6, 2 km.

## 7. Rupees everywhere
Every amount on every screen (home/dashboard, post ride, request ride, pickup order, fare split,
history) must show rupees. Create `lib/utils/currency.dart` with `String formatRupees(num v)` using
`NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2)`. Remove every `$`,
"USD" and "dollar". Fare input fields get a `₹` prefix. Replace hardcoded sample amounts with
realistic rupee values (about ₹40 to ₹250). This is not an exchange-rate conversion.

## 8. Firestore rules (I will paste these in the console myself)
Create `firestore.rules` with:
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

## 9. Done means
- `flutter pub get` and `flutter analyze` report no errors; the app builds for Android.
- Rider and driver sign-up both create a `users` document; wrong-role login is rejected.
- Verification email is sent; the app is gated until verified.
- Accepting a rider lowers `seatsAvailable` by 1; a full ride disappears from open rides;
  cancelling gives the seat back; two riders cannot take the last seat.
- Completing a ride saves each rider's fare and writes a `rideHistory` entry for the driver and
  every rider; both dashboards show those past rides.
- All amounts are in rupees. No leftover duplicate classes, no second `main()`.
At the end, list every file you changed and anything I must do by hand.
