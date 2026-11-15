# FareRide Flutter app

FareRide is the Flutter app in this folder. `lib/main.dart` initializes Firebase using `lib/firebase_options.dart`, then `AuthWrapper` routes signed-out users to the existing landing page and verified users to their rider or driver dashboard.

## Firebase setup

- Add the Android `google-services.json` from Firebase Console at `android/app/google-services.json`.
- Enable Email/Password and Google providers in Firebase Authentication.
- For Android Google sign-in, add the Android SHA-1 fingerprint in Firebase Project settings and download a fresh `google-services.json` afterward.
- Create the Firestore database and publish the repository's `firestore.rules`.

Email/password accounts use a role-specific profile and email verification. Driver profiles store license and vehicle text fields with `verificationStatus: pending_review`; the app does not upload files.

Ride posts, rider requests, seat transactions, fare allocation, and completed-ride history use Cloud Firestore. Amounts are displayed in Indian rupees. Rider destinations are names and coordinates and are not restricted to a campus.

Ride posting and search use place-name suggestions from the device geocoder. Users can select a result or explicitly use their current location; the selected place name and resolved coordinates are stored with the ride or request. Location permission is requested only when the current-location button is used.

Use **Load demo data** from either dashboard to add a repeatable sample set for that account's role. Driver demo accounts get rides with sample rider requests and history; rider demo accounts get nearby example rides, a pending request, an accepted ride, and history.
