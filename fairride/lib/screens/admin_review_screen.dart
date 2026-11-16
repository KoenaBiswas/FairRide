part of '../fare_ride_screens.dart';

class FareRideAdminReviewScreen extends StatelessWidget {
  const FareRideAdminReviewScreen({super.key});
  Future<void> _decision(BuildContext context, String uid, bool approve) async {
    var reason = '';
    if (!approve) {
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reject driver'),
          content: TextField(
            onChanged: (v) => reason = v,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, reason),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (result == null || result.trim().isEmpty) return;
      reason = result.trim();
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'verificationStatus': approve ? 'verified' : 'rejected',
      if (!approve) 'rejectionReason': reason,
      if (approve) 'rejectionReason': FieldValue.delete(),
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Sign in to continue.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Driver review')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: AuthService.instance.userDoc(uid),
        builder: (context, admin) {
          if (!admin.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (admin.data?.data()?['isAdmin'] != true) {
            return const Center(child: Text('Administrator access required.'));
          }
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'driver')
                .where('verificationStatus', isEqualTo: 'pending_review')
                .snapshots(),
            builder: (context, drivers) {
              if (drivers.hasError) {
                return Center(
                  child: Text('Could not load reviews: ${drivers.error}'),
                );
              }
              if (!drivers.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (drivers.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No driver profiles are waiting for review.'),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final driver in drivers.data!.docs)
                    _DriverReviewCard(
                      data: driver.data(),
                      uid: driver.id,
                      onApprove: () => _decision(context, driver.id, true),
                      onReject: () => _decision(context, driver.id, false),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _DriverReviewCard extends StatelessWidget {
  const _DriverReviewCard({
    required this.data,
    required this.uid,
    required this.onApprove,
    required this.onReject,
  });
  final Map<String, dynamic> data;
  final String uid;
  final VoidCallback onApprove, onReject;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['name'] ?? 'Driver',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          Text(
            'Licence: ${data['licenseNumber'] ?? ''} · expires ${data['licenseExpiry'] ?? ''}',
          ),
          Text(
            'Vehicle: ${data['vehicleModel'] ?? ''} · ${data['vehicleNumber'] ?? ''}',
          ),
          Text('UPI: ${data['upiId'] ?? ''}'),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('documents')
                .snapshots(),
            builder: (context, docs) {
              if (!docs.hasData) return const LinearProgressIndicator();
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final doc in docs.data!.docs)
                    if (doc.data()['imageBase64'] is String)
                      Column(
                        children: [
                          Image.memory(
                            base64Decode(doc.data()['imageBase64'] as String),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          Text(doc.id),
                        ],
                      ),
                ],
              );
            },
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onApprove,
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
