import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/ride_models.dart';
import '../logic/fare_calculator.dart';

class RideException implements Exception {
  RideException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// All ride data lives here. Seat counts are changed inside Firestore
/// transactions, so two riders can never take the same last seat.
class RideService {
  RideService._();
  static final RideService instance = RideService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _rides =>
      _db.collection('rides');

  User get _user {
    final u = _auth.currentUser;
    if (u == null) throw RideException('Please log in first.');
    return u;
  }

  CollectionReference<Map<String, dynamic>> _history(String uid) =>
      _db.collection('users').doc(uid).collection('rideHistory');

  /// Seeds repeatable Firestore examples for the signed-in user's role.
  /// Returns false when this account already has the demo set.
  Future<bool> seedDemoData() async {
    final user = _user;
    final profile = await _db.collection('users').doc(user.uid).get();
    final data = profile.data();
    final role = data?['role'] as String?;
    if (role != 'rider' && role != 'driver') {
      throw RideException(
        'Your FareRide profile needs a rider or driver role.',
      );
    }

    final prefix = 'demo_${user.uid}_$role';
    final firstRide = _rides.doc('${prefix}_open_1');
    if ((await firstRide.get()).exists) return false;

    final now = DateTime.now();
    final batch = _db.batch();
    final driverIsCurrentUser = role == 'driver';
    final driverId = driverIsCurrentUser
        ? user.uid
        : 'sample_driver_${user.uid}';
    final driverName = driverIsCurrentUser
        ? (data?['name'] as String? ?? user.displayName ?? 'Demo Driver')
        : 'Riya Sharma · Demo driver';

    Map<String, dynamic> rideData({
      required String startName,
      required double startLat,
      required double startLng,
      required String destName,
      required double destLat,
      required double destLng,
      required DateTime departure,
      required int seatsTotal,
      required int seatsAvailable,
      required String status,
      required List<String> riderIds,
      required double fare,
    }) => {
      'driverId': driverId,
      'driverName': driverName,
      'startName': startName,
      'startLat': startLat,
      'startLng': startLng,
      'destName': destName,
      'destLat': destLat,
      'destLng': destLng,
      'departureTime': Timestamp.fromDate(departure),
      'seatsTotal': seatsTotal,
      'seatsAvailable': seatsAvailable,
      'status': status,
      'riderIds': riderIds,
      'totalFare': fare,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    Map<String, dynamic> requestData({
      required String riderId,
      required String riderName,
      required String pickupName,
      required double pickupLat,
      required double pickupLng,
      required double distance,
      required String status,
    }) => {
      'riderId': riderId,
      'riderName': riderName,
      'pickupName': pickupName,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'distanceToDestKm': distance,
      'status': status,
      'fare': null,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final openRide1 = firstRide;
    final openRide2 = _rides.doc('${prefix}_open_2');
    final historyRide = _rides.doc('${prefix}_completed');
    final riderA = 'sample_rider_${user.uid}_a';
    final riderB = 'sample_rider_${user.uid}_b';

    if (driverIsCurrentUser) {
      batch.set(
        openRide1,
        rideData(
          startName: 'Connaught Place',
          startLat: 28.6315,
          startLng: 77.2167,
          destName: 'India Gate',
          destLat: 28.6129,
          destLng: 77.2295,
          departure: now.add(const Duration(hours: 1)),
          seatsTotal: 3,
          seatsAvailable: 2,
          status: RideStatus.open,
          riderIds: [riderA],
          fare: 180,
        ),
      );
      batch.set(
        openRide1.collection('requests').doc(riderA),
        requestData(
          riderId: riderA,
          riderName: 'Aarav Mehta',
          pickupName: 'Janpath',
          pickupLat: 28.6242,
          pickupLng: 77.2195,
          distance: 3.4,
          status: RequestStatus.accepted,
        ),
      );
      batch.set(
        openRide1.collection('requests').doc(riderB),
        requestData(
          riderId: riderB,
          riderName: 'Maya Kapoor',
          pickupName: 'Khan Market',
          pickupLat: 28.5988,
          pickupLng: 77.2311,
          distance: 5.8,
          status: RequestStatus.pending,
        ),
      );
      batch.set(
        openRide2,
        rideData(
          startName: 'Hauz Khas',
          startLat: 28.5494,
          startLng: 77.2001,
          destName: 'Gurugram Cyber Hub',
          destLat: 28.4950,
          destLng: 77.0890,
          departure: now.add(const Duration(hours: 3)),
          seatsTotal: 3,
          seatsAvailable: 3,
          status: RideStatus.open,
          riderIds: const [],
          fare: 240,
        ),
      );
      batch.set(
        openRide2.collection('requests').doc('${riderA}_2'),
        requestData(
          riderId: '${riderA}_2',
          riderName: 'Aarav Mehta',
          pickupName: 'Green Park',
          pickupLat: 28.5595,
          pickupLng: 77.2060,
          distance: 12.2,
          status: RequestStatus.pending,
        ),
      );
      batch.set(
        historyRide,
        rideData(
          startName: 'Lajpat Nagar',
          startLat: 28.5677,
          startLng: 77.2433,
          destName: 'Noida Sector 18',
          destLat: 28.5708,
          destLng: 77.3261,
          departure: now.subtract(const Duration(days: 2)),
          seatsTotal: 3,
          seatsAvailable: 0,
          status: RideStatus.completed,
          riderIds: [riderA, riderB],
          fare: 320,
        )..['completedAt'] = FieldValue.serverTimestamp(),
      );
      batch.set(_history(user.uid).doc(historyRide.id), {
        'rideId': historyRide.id,
        'role': 'driver',
        'startName': 'Lajpat Nagar',
        'destName': 'Noida Sector 18',
        'departureTime': Timestamp.fromDate(
          now.subtract(const Duration(days: 2)),
        ),
        'amount': 320.0,
        'riders': 2,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final pendingRide = openRide2;
      final acceptedRide = historyRide;
      final riderName =
          data?['name'] as String? ?? user.displayName ?? 'Demo Rider';
      batch.set(
        openRide1,
        rideData(
          startName: 'Connaught Place',
          startLat: 28.6315,
          startLng: 77.2167,
          destName: 'India Gate',
          destLat: 28.6129,
          destLng: 77.2295,
          departure: now.add(const Duration(hours: 1)),
          seatsTotal: 3,
          seatsAvailable: 3,
          status: RideStatus.open,
          riderIds: const [],
          fare: 180,
        ),
      );
      batch.set(
        pendingRide,
        rideData(
          startName: 'Hauz Khas',
          startLat: 28.5494,
          startLng: 77.2001,
          destName: 'Gurugram Cyber Hub',
          destLat: 28.4950,
          destLng: 77.0890,
          departure: now.add(const Duration(hours: 3)),
          seatsTotal: 3,
          seatsAvailable: 2,
          status: RideStatus.open,
          riderIds: const [],
          fare: 240,
        ),
      );
      batch.set(
        pendingRide.collection('requests').doc(user.uid),
        requestData(
          riderId: user.uid,
          riderName: riderName,
          pickupName: 'Green Park',
          pickupLat: 28.5595,
          pickupLng: 77.2060,
          distance: 12.2,
          status: RequestStatus.pending,
        ),
      );
      batch.set(
        acceptedRide,
        rideData(
          startName: 'Lajpat Nagar',
          startLat: 28.5677,
          startLng: 77.2433,
          destName: 'Noida Sector 18',
          destLat: 28.5708,
          destLng: 77.3261,
          departure: now.add(const Duration(hours: 2)),
          seatsTotal: 3,
          seatsAvailable: 2,
          status: RideStatus.open,
          riderIds: [user.uid],
          fare: 160,
        ),
      );
      batch.set(
        acceptedRide.collection('requests').doc(user.uid),
        requestData(
          riderId: user.uid,
          riderName: riderName,
          pickupName: 'Lajpat Nagar Metro',
          pickupLat: 28.5700,
          pickupLng: 77.2430,
          distance: 8.1,
          status: RequestStatus.accepted,
        ),
      );
      batch.set(_history(user.uid).doc('${prefix}_history'), {
        'rideId': '${prefix}_history',
        'role': 'rider',
        'startName': 'Rajiv Chowk',
        'destName': 'Saket',
        'departureTime': Timestamp.fromDate(
          now.subtract(const Duration(days: 1)),
        ),
        'amount': 95.0,
        'completedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    return true;
  }

  // ------------------------------------------------------------ DRIVER

  /// Driver posts a ride. Returns the new ride id.
  Future<String> createRide({
    required String startName,
    required double startLat,
    required double startLng,
    required String destName,
    required double destLat,
    required double destLng,
    required DateTime departureTime,
    required int seats,
    required double totalFare,
  }) async {
    final user = _user;
    final profile =
        (await _db.collection('users').doc(user.uid).get()).data() ?? {};
    final docs = await _db
        .collection('users')
        .doc(user.uid)
        .collection('documents')
        .get();
    final submittedDocumentIds = {
      for (final doc in docs.docs)
        if (doc.data()['imageBase64'] is String &&
            (doc.data()['imageBase64'] as String).isNotEmpty)
          doc.id,
    };
    const requiredDocuments = ['licence', 'rc', 'selfie'];
    if (!requiredDocuments.every(submittedDocumentIds.contains)) {
      throw RideException(
        'Submit your driving licence, vehicle RC, and selfie in your driver profile before posting a ride.',
      );
    }
    if (seats < 1 || seats > 6) throw RideException('Seats must be 1 to 6.');
    if (totalFare < 0) throw RideException('Fare cannot be negative.');
    final ref = _rides.doc();
    await ref.set({
      'driverId': user.uid,
      'driverName': user.displayName ?? 'Driver',
      'vehicleModel': profile['vehicleModel'] ?? '',
      'vehicleNumber': profile['vehicleNumber'] ?? '',
      'driverUpiId': profile['upiId'] ?? '',
      'startName': startName,
      'startLat': startLat,
      'startLng': startLng,
      'destName': destName,
      'destLat': destLat,
      'destLng': destLng,
      'departureTime': Timestamp.fromDate(departureTime),
      'seatsTotal': seats,
      'seatsAvailable': seats,
      'status': RideStatus.open,
      'riderIds': <String>[],
      'totalFare': totalFare,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Driver accepts a pending request: seat count goes down by 1, the rider is
  /// added to the ride, and the ride becomes 'full' when no seats are left.
  Future<void> acceptRequest(String rideId, String riderId) async {
    final uid = _user.uid;
    final rideRef = _rides.doc(rideId);
    final reqRef = rideRef.collection('requests').doc(riderId);
    await _db.runTransaction((tx) async {
      final rideSnap = await tx.get(rideRef);
      final reqSnap = await tx.get(reqRef);
      if (!rideSnap.exists || !reqSnap.exists) {
        throw RideException('Request not found.');
      }
      final ride = rideSnap.data()!;
      if (ride['driverId'] != uid) {
        throw RideException('Only the driver can accept riders.');
      }
      if (ride['status'] != RideStatus.open) {
        throw RideException('This ride is not accepting riders.');
      }
      if (reqSnap.data()!['status'] != RequestStatus.pending) {
        throw RideException('This request was already handled.');
      }
      final seats = (ride['seatsAvailable'] as num).toInt();
      if (seats <= 0) throw RideException('No seats left.');

      final newSeats = seats - 1;
      tx.update(rideRef, {
        'seatsAvailable': newSeats,
        'riderIds': FieldValue.arrayUnion([riderId]),
        'status': newSeats == 0 ? RideStatus.full : RideStatus.open,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(reqRef, {
        'status': RequestStatus.accepted,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectRequest(String rideId, String riderId) {
    return _rides.doc(rideId).collection('requests').doc(riderId).update({
      'status': RequestStatus.rejected,
    });
  }

  /// Driver leaves; no more riders can join or cancel seats after this.
  Future<void> startRide(
    String rideId, {
    required List<double> roadLegKm,
    required double routeKm,
    required double durationMin,
    required bool approximate,
  }) async {
    final uid = _user.uid;
    final ref = _rides.doc(rideId);
    final snap = await ref.get();
    if (!snap.exists || snap.data()?['driverId'] != uid) {
      throw RideException('Only the driver can start this ride.');
    }
    await ref.update({
      'status': RideStatus.inProgress,
      'roadLegKm': roadLegKm,
      'routeKm': routeKm,
      'routeDurationMin': durationMin,
      'routeApproximate': approximate,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markPickedUp(String rideId, String riderId) => _rides
      .doc(rideId)
      .collection('requests')
      .doc(riderId)
      .update({'status': RequestStatus.pickedUp});

  Future<void> cancelRide(String rideId) => _rides.doc(rideId).update({
    'status': RideStatus.cancelled,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// Destination reached: splits the fare, saves each rider's fare, marks the
  /// ride completed and writes a history entry for the driver and every rider.
  Future<void> completeRide(String rideId) async {
    final uid = _user.uid;
    final rideRef = _rides.doc(rideId);
    final rideSnap = await rideRef.get();
    if (!rideSnap.exists) throw RideException('Ride not found.');
    final ride = Ride.fromDoc(rideSnap);
    if (ride.driverId != uid) {
      throw RideException('Only the driver can finish this ride.');
    }
    if (ride.status == RideStatus.completed) return;
    if (ride.status != RideStatus.inProgress) {
      throw RideException('Start the ride before completing it.');
    }

    final reqSnap = await rideRef
        .collection('requests')
        .where(
          'status',
          whereIn: [RequestStatus.accepted, RequestStatus.pickedUp],
        )
        .get();
    final riders = reqSnap.docs.map(RideRequest.fromDoc).toList();

    final ordered = [...riders]
      ..sort((a, b) => b.distanceToDestKm.compareTo(a.distanceToDestKm));
    final roadLegs = ride.roadLegKm.length >= ordered.length + 1
        ? ride.roadLegKm.skip(1).toList()
        : List<double>.generate(
            ordered.length,
            (i) => i < ride.roadLegKm.length ? ride.roadLegKm[i] : 0.0,
          );
    final fares = calculateFares(
      ordered.map((r) => r.riderId).toList(),
      roadLegs,
      ride.totalFare,
    );

    final batch = _db.batch();
    batch.update(rideRef, {
      'status': RideStatus.completed,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final common = {
      'rideId': rideId,
      'startName': ride.startName,
      'destName': ride.destName,
      'departureTime': Timestamp.fromDate(ride.departureTime),
      'completedAt': FieldValue.serverTimestamp(),
    };

    var collected = 0.0;
    for (final r in riders) {
      final fare = fares[r.riderId] ?? 0;
      collected += fare;
      batch.update(rideRef.collection('requests').doc(r.riderId), {
        'status': RequestStatus.dropped,
        'fare': fare,
        'paymentStatus': 'unpaid',
      });
      batch.set(_history(r.riderId).doc(rideId), {
        ...common,
        'role': 'rider',
        'amount': fare,
      });
    }
    batch.set(_history(uid).doc(rideId), {
      ...common,
      'role': 'driver',
      'amount': double.parse(collected.toStringAsFixed(2)),
      'riders': riders.length,
    });
    await batch.commit();
  }

  // ------------------------------------------------------------- RIDER

  /// Rider asks to join. Distance to the destination is stored so the driver
  /// can order pickups farthest-first and so fares can be split later.
  Future<void> requestToJoin({
    required String rideId,
    required String pickupName,
    required double pickupLat,
    required double pickupLng,
  }) async {
    final user = _user;
    final rideRef = _rides.doc(rideId);
    final reqRef = rideRef.collection('requests').doc(user.uid);
    await _db.runTransaction((tx) async {
      final rideSnap = await tx.get(rideRef);
      final reqSnap = await tx.get(reqRef);
      if (!rideSnap.exists) throw RideException('Ride not found.');
      final ride = rideSnap.data()!;
      if (ride['driverId'] == user.uid) {
        throw RideException('You cannot join your own ride.');
      }
      if (ride['status'] != RideStatus.open ||
          ((ride['seatsAvailable'] as num?) ?? 0) <= 0) {
        throw RideException('This ride is full.');
      }
      final old = reqSnap.data()?['status'];
      if (old == RequestStatus.pending || old == RequestStatus.accepted) {
        throw RideException('You already requested this ride.');
      }
      final riderProfile = await tx.get(_db.collection('users').doc(user.uid));
      tx.set(reqRef, {
        'riderId': user.uid,
        'riderName':
            riderProfile.data()?['name'] ?? user.displayName ?? 'Rider',
        'pickupName': pickupName,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'distanceToDestKm': haversineCoordinatesKm(
          pickupLat,
          pickupLng,
          (ride['destLat'] as num).toDouble(),
          (ride['destLng'] as num).toDouble(),
        ),
        'status': RequestStatus.pending,
        'fare': null,
        'paymentStatus': 'unpaid',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Rider cancels. If the driver had accepted, the seat is given back.
  Future<void> cancelRequest(String rideId) async {
    final uid = _user.uid;
    final rideRef = _rides.doc(rideId);
    final reqRef = rideRef.collection('requests').doc(uid);
    await _db.runTransaction((tx) async {
      final rideSnap = await tx.get(rideRef);
      final reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists) return;
      final status = reqSnap.data()!['status'];
      if (status != RequestStatus.pending && status != RequestStatus.accepted) {
        return;
      }
      if (status == RequestStatus.accepted) {
        if (rideSnap.data()?['status'] == RideStatus.inProgress) {
          throw RideException('The ride has already started.');
        }
        tx.update(rideRef, {
          'seatsAvailable': FieldValue.increment(1),
          'riderIds': FieldValue.arrayRemove([uid]),
          'status': RideStatus.open,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      tx.update(reqRef, {'status': RequestStatus.cancelled});
    });
  }

  Future<void> markPaid(
    String rideId,
    String riderId, {
    required String utr,
  }) async {
    final paymentReference = utr.trim();
    if (paymentReference.isEmpty) {
      throw RideException('Enter your UTR or payment reference number.');
    }
    await _rides.doc(rideId).collection('requests').doc(riderId).update({
      'paymentStatus': 'marked_paid',
      'paymentMethod': 'upi_qr',
      'utr': paymentReference,
      'paidAt': FieldValue.serverTimestamp(),
    });
    await _history(riderId)
        .doc(rideId)
        .set({'paymentStatus': 'marked_paid'}, SetOptions(merge: true));
  }

  Future<void> confirmPayment(String rideId, String riderId) async {
    await _rides.doc(rideId).collection('requests').doc(riderId).update({
      'paymentStatus': 'confirmed',
      'confirmedAt': FieldValue.serverTimestamp(),
    });
    await _history(riderId)
        .doc(rideId)
        .set({'paymentStatus': 'confirmed'}, SetOptions(merge: true));
  }

  // ----------------------------------------------------------- STREAMS

  /// Open rides with free seats. Pass the rider's destination to show only
  /// rides ending within [radiusKm] of it.
  Stream<List<Ride>> watchOpenRides({
    double? nearLat,
    double? nearLng,
    double radiusKm = 1,
  }) {
    return _rides.where('status', isEqualTo: RideStatus.open).snapshots().map((
      s,
    ) {
      var list = s.docs.map(Ride.fromDoc).toList();
      if (nearLat != null && nearLng != null) {
        list = list
            .where(
              (r) =>
                  haversineCoordinatesKm(
                    nearLat,
                    nearLng,
                    r.destLat,
                    r.destLng,
                  ) <=
                  radiusKm,
            )
            .toList();
      }
      list.sort((a, b) => a.departureTime.compareTo(b.departureTime));
      return list;
    });
  }

  Stream<Ride?> watchRide(String rideId) => _rides
      .doc(rideId)
      .snapshots()
      .map((d) => d.exists ? Ride.fromDoc(d) : null);

  /// Requests for a ride, farthest from the destination first (pickup order).
  Stream<List<RideRequest>> watchRequests(String rideId) => _rides
      .doc(rideId)
      .collection('requests')
      .orderBy('distanceToDestKm', descending: true)
      .snapshots()
      .map((s) => s.docs.map(RideRequest.fromDoc).toList());

  /// The signed-in rider's own request on a ride (null if none).
  Stream<RideRequest?> watchMyRequest(String rideId) => _rides
      .doc(rideId)
      .collection('requests')
      .doc(_user.uid)
      .snapshots()
      .map((d) => d.exists ? RideRequest.fromDoc(d) : null);

  bool _active(Ride r) =>
      r.status == RideStatus.open ||
      r.status == RideStatus.full ||
      r.status == RideStatus.inProgress;

  /// Upcoming/active rides the signed-in user has been accepted into.
  Stream<List<Ride>> watchMyRidesAsRider() => _rides
      .where('riderIds', arrayContains: _user.uid)
      .snapshots()
      .map(
        (s) =>
            s.docs.map(Ride.fromDoc).where(_active).toList()
              ..sort((a, b) => a.departureTime.compareTo(b.departureTime)),
      );

  /// Upcoming/active rides the signed-in user is driving.
  Stream<List<Ride>> watchMyRidesAsDriver() => _rides
      .where('driverId', isEqualTo: _user.uid)
      .snapshots()
      .map(
        (s) =>
            s.docs.map(Ride.fromDoc).where(_active).toList()
              ..sort((a, b) => a.departureTime.compareTo(b.departureTime)),
      );

  /// The signed-in user's last completed rides, newest first.
  Stream<List<RideHistoryItem>> watchHistory({int limit = 10}) =>
      _history(_user.uid)
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map(RideHistoryItem.fromDoc).toList());
}
