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

  Future<void> _save(String uid, Map<String, dynamic> profile) async {
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
      if ((profile['verificationStatus'] == 'rejected' ||
              profile['verificationStatus'] == 'pending_documents') &&
          _images.length == 3) {
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
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Verification: ${status.toString().replaceAll('_', ' ')}',
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
              TextField(
                controller: _upi,
                decoration: const InputDecoration(
                  labelText: 'UPI ID',
                  hintText: 'name@bank',
                ),
              ),
              if (status == 'rejected' || status == 'pending_documents') ...[
                const SizedBox(height: 14),
                const Text(
                  'Upload all three documents to submit for administrator review',
                ),
                for (final item in const {
                  'licence': 'Driving licence',
                  'rc': 'Vehicle RC',
                  'selfie': 'Selfie',
                }.entries)
                  ListTile(
                    title: Text(item.value),
                    leading: _images[item.key] == null
                        ? const Icon(Icons.image_outlined)
                        : Image.memory(
                            _images[item.key]!,
                            width: 44,
                            height: 44,
                          ),
                    trailing: PopupMenuButton<ImageSource>(
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
                  ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : () => _save(uid, data),
                child: Text(
                  _busy
                      ? 'Saving…'
                      : (status == 'rejected' || status == 'pending_documents')
                      ? 'Save UPI and submit documents'
                      : 'Save UPI ID',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
