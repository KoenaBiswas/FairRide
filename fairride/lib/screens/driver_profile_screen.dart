part of '../fare_ride_screens.dart';

class FareRideDriverProfileScreen extends StatefulWidget {
  const FareRideDriverProfileScreen({super.key, this.onboardingMode = false});
  final bool onboardingMode;
  @override
  State<FareRideDriverProfileScreen> createState() =>
      _FareRideDriverProfileScreenState();
}

class _FareRideDriverProfileScreenState
    extends State<FareRideDriverProfileScreen> {
  final _upi = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _license = TextEditingController();
  final _expiry = TextEditingController();
  final _vehicleNumber = TextEditingController();
  final _vehicleModel = TextEditingController();
  final Map<String, Uint8List> _images = {};
  bool _busy = false;
  String? _loadedUid;
  @override
  void dispose() {
    _upi.dispose();
    _name.dispose();
    _phone.dispose();
    _license.dispose();
    _expiry.dispose();
    _vehicleNumber.dispose();
    _vehicleModel.dispose();
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
      await user.update({
        'upiId': upi,
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'licenseNumber': _license.text.trim(),
        'licenseExpiry': _expiry.text.trim(),
        'vehicleNumber': _vehicleNumber.text.trim(),
        'vehicleModel': _vehicleModel.text.trim(),
      });
      await RecentStore.instance.savePhone(_phone.text);
      for (final entry in _images.entries) {
        await user.collection('documents').doc(entry.key).set({
          'imageBase64': base64Encode(entry.value),
          'uploadedAt': FieldValue.serverTimestamp(),
        });
      }
      if (widget.onboardingMode) {
        await user.update({'driverOnboardingComplete': true});
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
            _upi.text = data['upiId'] ?? '7291098653@pthdfc';
            _name.text = data['name'] ?? '';
            _phone.text = data['phone'] ?? '';
            _license.text = data['licenseNumber'] ?? '';
            _expiry.text = data['licenseExpiry'] ?? '';
            _vehicleNumber.text = data['vehicleNumber'] ?? '';
            _vehicleModel.text = data['vehicleModel'] ?? '';
            _loadedUid = uid;
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('documents')
                    .snapshots(),
                builder: (context, documents) {
                  final uploaded = const ['licence', 'rc', 'selfie'].every(
                    (key) =>
                        documents.data?.docs.any(
                          (doc) =>
                              doc.id == key &&
                              doc.data()['imageBase64'] is String,
                        ) ==
                        true,
                  );
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Documents: ${uploaded ? 'Submitted' : 'Not uploaded'}',
                    ),
                  );
                },
              ),
              FareRideField(
                label: 'Full name',
                controller: _name,
                autofillHints: const [AutofillHints.name],
              ),
              FareRideField(
                label: 'Phone number',
                controller: _phone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
              FareRideField(label: 'Licence number', controller: _license),
              FareRideField(label: 'Licence expiry', controller: _expiry),
              FareRideField(
                label: 'Vehicle registration',
                controller: _vehicleNumber,
              ),
              FareRideField(label: 'Vehicle model', controller: _vehicleModel),
              ...[
                const SizedBox(height: 12),
                const Text(
                  'Your licence, vehicle and payment details. Your documents are below.',
                ),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('documents')
                      .snapshots(),
                  builder: (context, documents) {
                    if (documents.hasError) {
                      return Text(
                        'Could not load documents: ${documents.error}',
                      );
                    }
                    if (!documents.hasData) {
                      return const LinearProgressIndicator();
                    }
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final document in documents.data!.docs)
                          if (document.data()['imageBase64'] is String)
                            Column(
                              children: [
                                Image.memory(
                                  base64Decode(
                                    document.data()['imageBase64'] as String,
                                  ),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                                Text(document.id),
                              ],
                            ),
                      ],
                    );
                  },
                ),
              ],
              TextField(
                controller: _upi,
                decoration: const InputDecoration(
                  labelText: 'UPI ID',
                  hintText: 'name@bank',
                ),
              ),
              ...[
                const SizedBox(height: 14),
                const Text('Uploaded documents can be replaced individually.'),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('documents')
                      .snapshots(),
                  builder: (context, docsSnap) {
                    final saved = {
                      for (final doc in docsSnap.data?.docs ?? [])
                        doc.id: doc.data()['imageBase64'] as String?,
                    };
                    return Column(
                      children: [
                        for (final item in const {
                          'licence': 'Driving licence',
                          'rc': 'Vehicle RC',
                          'selfie': 'Selfie',
                        }.entries)
                          ListTile(
                            title: Text(item.value),
                            subtitle:
                                _images[item.key] == null &&
                                    saved[item.key] != null
                                ? const Text('Uploaded')
                                : null,
                            leading: _images[item.key] != null
                                ? Image.memory(
                                    _images[item.key]!,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  )
                                : saved[item.key] != null
                                ? Image.memory(
                                    base64Decode(saved[item.key]!),
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image_outlined),
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
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : () => _save(uid, data),
                child: Text(_busy ? 'Saving…' : 'Save profile'),
              ),
            ],
          );
        },
      ),
    );
  }
}
