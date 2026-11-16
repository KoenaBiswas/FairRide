import 'package:cloud_firestore/cloud_firestore.dart';

class RideStatus {
  static const open = 'open';
  static const full = 'full';
  static const inProgress = 'in_progress';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
}

class RequestStatus {
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const rejected = 'rejected';
  static const pickedUp = 'picked_up';
  static const dropped = 'dropped';
  static const cancelled = 'cancelled';
}

String requestStatusLabel(String status) => switch (status) {
  RequestStatus.pending => 'Awaiting response',
  RequestStatus.rejected => 'Declined',
  RequestStatus.accepted => 'Accepted',
  RequestStatus.pickedUp => 'Picked up',
  RequestStatus.dropped => 'Dropped off',
  RequestStatus.cancelled => 'Cancelled',
  _ => status.replaceAll('_', ' '),
};

DateTime _dt(dynamic v) =>
    v is Timestamp ? v.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;
int _i(dynamic v) => (v as num?)?.toInt() ?? 0;

/// rides/{rideId}
class Ride {
  const Ride({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.startName,
    required this.startLat,
    required this.startLng,
    required this.destName,
    required this.destLat,
    required this.destLng,
    required this.departureTime,
    required this.seatsTotal,
    required this.seatsAvailable,
    required this.status,
    required this.riderIds,
    required this.totalFare,
    this.roadLegKm = const [],
    this.routeKm = 0,
    this.vehicleModel = '',
    this.vehicleNumber = '',
    this.driverUpiId = '',
    this.routeDurationMin = 0,
    this.routeApproximate = false,
  });

  final String id, driverId, driverName, startName, destName, status;
  final double startLat, startLng, destLat, destLng, totalFare;
  final DateTime departureTime;
  final int seatsTotal, seatsAvailable;
  final List<String> riderIds;
  final List<double> roadLegKm;
  final double routeKm, routeDurationMin;
  final bool routeApproximate;
  final String vehicleModel, vehicleNumber, driverUpiId;

  bool get isFull => seatsAvailable <= 0;

  factory Ride.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Ride(
      id: doc.id,
      driverId: m['driverId'] ?? '',
      driverName: m['driverName'] ?? 'Driver',
      startName: m['startName'] ?? '',
      startLat: _d(m['startLat']),
      startLng: _d(m['startLng']),
      destName: m['destName'] ?? '',
      destLat: _d(m['destLat']),
      destLng: _d(m['destLng']),
      departureTime: _dt(m['departureTime']),
      seatsTotal: _i(m['seatsTotal']),
      seatsAvailable: _i(m['seatsAvailable']),
      status: m['status'] ?? RideStatus.open,
      riderIds: List<String>.from(m['riderIds'] ?? const []),
      totalFare: _d(m['totalFare']),
      roadLegKm: List<num>.from(m['roadLegKm'] ?? const [])
          .map((e) => e.toDouble())
          .toList(),
      routeKm: _d(m['routeKm']),
      routeDurationMin: _d(m['routeDurationMin']),
      routeApproximate: m['routeApproximate'] == true,
      vehicleModel: m['vehicleModel'] ?? '',
      vehicleNumber: m['vehicleNumber'] ?? '',
      driverUpiId: m['driverUpiId'] ?? '',
    );
  }
}

/// rides/{rideId}/requests/{riderId}  (document id = rider's uid)
class RideRequest {
  const RideRequest({
    required this.riderId,
    required this.riderName,
    required this.pickupName,
    required this.pickupLat,
    required this.pickupLng,
    required this.distanceToDestKm,
    required this.status,
    this.fare,
    this.paymentStatus = 'unpaid',
    this.utr = '',
  });

  final String riderId, riderName, pickupName, status;
  final double pickupLat, pickupLng, distanceToDestKm;
  final double? fare;
  final String paymentStatus, utr;

  factory RideRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return RideRequest(
      riderId: doc.id,
      riderName: m['riderName'] ?? 'Rider',
      pickupName: m['pickupName'] ?? '',
      pickupLat: _d(m['pickupLat']),
      pickupLng: _d(m['pickupLng']),
      distanceToDestKm: _d(m['distanceToDestKm']),
      status: m['status'] ?? RequestStatus.pending,
      fare: (m['fare'] as num?)?.toDouble(),
      paymentStatus: m['paymentStatus'] ?? 'unpaid',
      utr: m['utr'] ?? '',
    );
  }
}

/// users/{uid}/rideHistory/{rideId}
class RideHistoryItem {
  const RideHistoryItem({
    required this.rideId,
    required this.role,
    required this.startName,
    required this.destName,
    required this.departureTime,
    required this.amount,
    required this.completedAt,
    this.riders = 0,
    this.paymentStatus = 'unpaid',
  });

  final String rideId, role, startName, destName; // role: 'driver' or 'rider'
  final DateTime departureTime, completedAt;
  final double amount; // rider: fare paid, driver: total collected
  final int riders;
  final String paymentStatus;

  factory RideHistoryItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return RideHistoryItem(
      rideId: doc.id,
      role: m['role'] ?? 'rider',
      startName: m['startName'] ?? '',
      destName: m['destName'] ?? '',
      departureTime: _dt(m['departureTime']),
      amount: _d(m['amount']),
      completedAt: _dt(m['completedAt']),
      riders: _i(m['riders']),
      paymentStatus: m['paymentStatus'] ?? 'unpaid',
    );
  }
}
