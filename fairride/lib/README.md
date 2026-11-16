# FareRide Flutter app

FareRide is the Flutter app in this folder. `lib/main.dart` initializes Firebase using `lib/firebase_options.dart`, then `FareRideAuthGate` routes signed-out users to the landing page, recovers missing roles, and sends signed-in users to their rider or driver dashboard.

## Firebase setup

- Add the Android `google-services.json` from Firebase Console at `android/app/google-services.json`.
- Enable Email/Password and Google providers in Firebase Authentication.
- For Android Google sign-in, add the Android SHA-1 fingerprint in Firebase Project settings and download a fresh `google-services.json` afterward.
- Create the Firestore database and publish the repository's `firestore.rules`.

Email/password accounts use a role-specific profile and email confirmation. Driver profiles include an Indian licence number and expiry, vehicle details, UPI ID, and compressed licence/RC/selfie images in `users/{uid}/documents/`. Documents are stored as base64 in Firestore (no Firebase Storage). Drivers can post rides after uploading all three documents and saving the profile.

Ride posts, rider requests, seat transactions, road distances, fare allocation, UPI payment status, and completed-ride history use Cloud Firestore. OSRM road routes use the public routing server and fall back to visibly approximate straight-line routes offline. Payments use driver UPI QR/deep links; FareRide cannot confirm bank transfers, so the driver confirms receipt. Amounts are displayed in Indian rupees. Rider destinations are names and coordinates and are not restricted to a campus.

Ride posting and search use place-name suggestions from the device geocoder. Users can select a result or explicitly use their current location; the selected place name and resolved coordinates are stored with the ride or request. Location permission is requested only when the current-location button is used.


## Manual Firebase steps

- Publish the repository root `firestore.rules` from the Firebase Console.
- Keep Google as an enabled Firebase Authentication provider. Add the Android SHA-1 in Firebase Project settings, then download the matching `google-services.json` for `com.example.fairride` so Google sign-in works on Android.
