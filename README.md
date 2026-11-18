# FareRide

FareRide is a Flutter campus carpool app for riders and drivers. It uses Firebase Authentication and Cloud Firestore for accounts, ride requests, ride progress, fare records, and payment status.

## Features

### Riders

- Find rides by destination and request a seat.
- See whether a request is waiting for the driver, accepted, or part of a ride that has started.
- View upcoming and completed rides, fare splits, and payment history.
- Pay the driver through a UPI app or QR code, then submit a UTR/reference number for the driver to confirm.
- Use the rider home page, profile drawer, previous rides, previous transactions, and fare-split navigation.

### Drivers

- Submit a driving licence, vehicle RC, and selfie from the driver profile. All three uploaded documents are required before posting a ride; administrator approval is not required to post.
- Create rides, review and accept or decline rider requests, manage pickup order, start rides, and complete rides.
- View active rides, completed-trip fare summaries, passenger counts, uploaded documents, UPI ID, profile details, and history.

### Locations and routes

- Search places using Photon/OpenStreetMap results biased toward Delhi NCR, with the device geocoder as a fallback.
- Pick an exact point on the map when a place name is missing from search results. Current location and recent places are also available.
- Calculate road routes with OSRM. When routing is unavailable, the app uses a straight-line estimate and identifies it as approximate.

## Requirements

- Flutter SDK with the Dart version allowed by `pubspec.yaml` (`^3.13.7`).
- Android Studio or another supported Flutter development setup.
- A Firebase project with **Email/Password** and **Google** sign-in enabled, and Cloud Firestore created.
- An Android app registered in Firebase. Configure its package name, SHA-1/SHA-256 fingerprints for Google sign-in, and the Firebase Android configuration.

## Firebase setup

1. Create or select a Firebase project and register the Android app using the application ID in `android/app/build.gradle.kts`.
2. Enable Email/Password and Google providers in Firebase Authentication.
3. Create a Cloud Firestore database.
4. Configure Firebase for Flutter with FlutterFire CLI. Generate or update `lib/firebase_options.dart` for the platforms you plan to run.
5. Apply the repository Firestore rules from [`../firestore.rules`](../firestore.rules) in the Firebase console or through your Firebase CLI deployment configuration.
6. For Google sign-in on Android, add the app signing certificate fingerprints to Firebase and refresh the Android Firebase configuration.

Do not commit private service credentials or signing keys. `firebase_options.dart` contains client configuration; use Firebase Authentication and Firestore rules to protect access to user data.

## Run the app

From this directory (`fairride`):

```powershell
flutter doctor
flutter pub get
flutter run
```

To run static analysis or the test suite:

```powershell
flutter analyze
flutter test
```

Android requests Internet access for Firebase, place search, routing, and map tiles. Location permission is requested only when the user chooses current location; camera access is used when taking driver-document photos.

## Data and payment notes

- User profiles are stored at `users/{uid}`. Driver document images are stored as base64 under `users/{uid}/documents/{documentId}`.
- Rides are stored at `rides/{rideId}`; seat requests are stored under `rides/{rideId}/requests/{riderUid}`.
- Completed ride summaries are stored under each user’s `rideHistory` collection.
- FareRide does not handle or verify bank transfers. It launches a UPI app or displays a QR code; the rider enters the payment reference and the driver confirms receipt after checking their account.
- Place search and road routing use public services (Photon/OpenStreetMap and OSRM). Those services may have usage limits or temporary outages. The app provides a map-pin selection fallback and approximate route fallback where applicable.

## Project layout

```text
lib/
  authenticate/   Firebase authentication and auth-state routing
  logic/          Fare calculation and rider ordering
  models/         Ride, request, and history models
  screens/        Rider, driver, payment, and profile screens
  services/       Firebase data access, routing, and local recent-item storage
  widgets/        Reusable location and form widgets
android/          Android app configuration
ios/              iOS project configuration
```
