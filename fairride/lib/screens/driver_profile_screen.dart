part of '../fare_ride_screens.dart';

class FareRideDriverProfileScreen extends StatefulWidget {
  const FareRideDriverProfileScreen({super.key});
  @override
  State<FareRideDriverProfileScreen> createState() =>
      _FareRideDriverProfileScreenState();
}

class _FareRideDriverProfileScreenState
    extends State<FareRideDriverProfileScreen> {
  final _upi = TextEditingController();
  final Map<String, Uint8List> _images = {};
  bool _busy = false;
  String? _loadedUid;
  @override
  void dispose() {
    _upi.dispose();
    super.dispose();
  }

  Uint8List _compress(Uint8List data) {
    final decoded = img.decodeImage(data);
    if (decoded == null) return data;
    final resized = decoded.width > 1000
        ? img.copyResize(decoded, width: 1000)
        : decoded;
    for (final quality in [50, 35, 20, 10, 5]) {
      final bytes = Uint8List.fromList(
        img.encodeJpg(resized, quality: quality),
      );
      if (bytes.length < 680 * 1024) return bytes;
    }
    return Uint8List.fromList(img.encodeJpg(resized, quality: 1));
  }

  Future<void> _pick(String doc, ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1000,
      imageQuality: 50,
    );
    if (file == null) return;
    final data = _compress(await file.readAsBytes());
    if (data.length > 680 * 1024) {
      if (mounted) {
        fareRideSnack(
          context,
          'Image remains too large for Firestore after compression.',
        );
      }
      return;
    }
    setState(() => _images[doc] = data);
  }

  Future<void> _save(
    String uid,
    Map<String, dynamic> profile,
    Set<String> savedDocumentIds,
  ) async {
    final upi = _upi.text.trim();
    if (!RegExp(r'^[\w.-]{2,256}@[\w.-]{2,64}$').hasMatch(upi)) {
      fareRideSnack(context, 'Enter a valid UPI ID.');
      return;
    }
    setState(() => _busy = true);
    try {
      final user = FirebaseFirestore.instance.collection('users').doc(uid);
      await user.update({'upiId': upi});
      for (final entry in _images.entries) {
        await user.collection('documents').doc(entry.key).set({
          'imageBase64': base64Encode(entry.value),
          'uploadedAt': FieldValue.serverTimestamp(),
        });
      }
      const requiredDocuments = {'licence', 'rc', 'selfie'};
      final allDocumentsSubmitted = requiredDocuments.every(
        (key) => savedDocumentIds.contains(key) || _images.containsKey(key),
      );
      if ((profile['verificationStatus'] == 'rejected' ||
              profile['verificationStatus'] == 'pending_documents') &&
          allDocumentsSubmitted) {
        await user.update({
          'verificationStatus': 'pending_review',
          'rejectionReason': FieldValue.delete(),
        });
      }
      if (mounted) fareRideSnack(context, 'Driver profile saved.');
    } catch (e) {
      if (mounted) fareRideSnack(context, 'Could not save profile: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Sign in to continue.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Driver profile')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: AuthService.instance.userDoc(uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Could not load profile: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data() ?? {};
          if (_loadedUid != uid) {
            _upi.text = data['upiId'] ?? '';
            _loadedUid = uid;
          }
          final status = data['verificationStatus'] ?? 'pending_documents';
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('documents')
                .snapshots(),
            builder: (context, documentSnapshot) {
              final Map<String, dynamic> storedDocuments = {
                for (final document in documentSnapshot.data?.docs ?? [])
                  document.id: document.data()['imageBase64'],
              };
              final Set<String> savedDocumentIds = storedDocuments.entries
                  .where(
                    (entry) =>
                        entry.value is String &&
                        (entry.value as String).isNotEmpty,
                  )
                  .map((entry) => entry.key)
                  .toSet();
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    data['name'] ?? 'Driver',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _AccountDetailRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: data['email'] ?? '',
                  ),
                  _AccountDetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: data['phone'] ?? '',
                  ),
                  const Divider(height: 24),
                  Text(
                    'Document review: ${status.toString().replaceAll('_', ' ')}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (status == 'rejected')
                    Text(
                      'Reason: ${data['rejectionReason'] ?? 'Update your documents and resubmit.'}',
                    ),
                  Text(
                    'Licence ${data['licenseNumber'] ?? ''} · expires ${data['licenseExpiry'] ?? ''}',
                  ),
                  Text(
                    'Vehicle ${data['vehicleModel'] ?? ''} · ${data['vehicleNumber'] ?? ''}',
                  ),
                  const SizedBox(height: 14),
                  const FareRideSectionTitle('Driver documents'),
                  const Text(
                    'Submit your driving licence, vehicle RC, and selfie before posting rides. Admin verification is not required to post.',
                    style: TextStyle(color: FareRideColors.muted, fontSize: 12),
                  ),
                  for (final item in const {
                    'licence': 'Driving licence',
                    'rc': 'Vehicle RC',
                    'selfie': 'Selfie',
                  }.entries)
                    Builder(
                      builder: (context) {
                        final stored = storedDocuments[item.key];
                        final image =
                            _images[item.key] ??
                            (stored is String && stored.isNotEmpty
                                ? base64Decode(stored)
                                : null);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.value),
                          subtitle: Text(
                            _images.containsKey(item.key)
                                ? 'Ready to save'
                                : image != null
                                ? 'Uploaded'
                                : 'Required before posting',
                          ),
                          leading: image == null
                              ? const Icon(Icons.image_outlined)
                              : Image.memory(
                                  image,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                          trailing: PopupMenuButton<ImageSource>(
                            tooltip: 'Upload or replace',
                            onSelected: (source) => _pick(item.key, source),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: ImageSource.camera,
                                child: Text('Camera'),
                              ),
                              PopupMenuItem(
                                value: ImageSource.gallery,
                                child: Text('Gallery'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  TextField(
                    controller: _upi,
                    decoration: const InputDecoration(
                      labelText: 'UPI ID',
                      hintText: 'name@bank',
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _save(uid, data, savedDocumentIds),
                    child: Text(
                      _busy ? 'Saving…' : 'Save profile and documents',
                    ),
                  ),
                  const SizedBox(height: 18),
                  const FareRideSectionTitle('Previous rides and transactions'),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const FareRideHistoryScreen(
                          transactionsOnly: false,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.route_outlined),
                    label: const Text('Previous rides'),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const FareRideHistoryScreen(transactionsOnly: true),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Previous transactions'),
                  ),
                  const FareRideHomeInsights(isDriver: true),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => fareRideSignOut(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Log out'),
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
