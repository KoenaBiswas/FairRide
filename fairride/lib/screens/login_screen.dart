part of '../fair_ride_screens.dart';

class FairRideLoginScreen extends StatefulWidget {
  const FairRideLoginScreen({
    super.key,
    this.initialRole = 'rider',
    this.initialSignup = false,
  });
  final String initialRole;
  final bool initialSignup;
  @override
  State<FairRideLoginScreen> createState() => _FairRideLoginScreenState();
}

class _FairRideLoginScreenState extends State<FairRideLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _license = TextEditingController();
  final _vehicleNumber = TextEditingController();
  final _vehicleModel = TextEditingController();
  final _upiId = TextEditingController();
  DateTime? _licenseExpiry;
  final Map<String, Uint8List> _documents = {};
  late String _role = widget.initialRole;
  late bool _signup = widget.initialSignup;
  bool _busy = false;
  String? _error;
  List<String> _recentEmails = const [];

  @override
  void initState() {
    super.initState();
    _loadRecentEmails();
  }

  Future<void> _loadRecentEmails() async {
    try {
      final emails = await RecentStore.instance.recentEmails();
      if (mounted) setState(() => _recentEmails = emails);
    } catch (_) {
      // Email suggestions are optional; login remains available without them.
    }
  }

  Future<void> _rememberEmail(String email) async {
    try {
      await RecentStore.instance.saveEmail(email);
      await _loadRecentEmails();
    } catch (_) {
      // Do not interrupt a successful authentication for local suggestion storage.
    }
  }

  Future<void> _removeRecentEmail(String email) async {
    try {
      await RecentStore.instance.removeEmail(email);
      await _loadRecentEmails();
    } catch (_) {
      if (mounted) {
        setState(
          () => _recentEmails = _recentEmails
              .where((savedEmail) => savedEmail != email)
              .toList(),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _phone,
      _password,
      _license,
      _vehicleNumber,
      _vehicleModel,
      _upiId,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_signup && _role == 'driver') {
      if (_licenseExpiry == null || !_licenseExpiry!.isAfter(DateTime.now())) {
        setState(() => _error = 'Choose a licence expiry date in the future.');
        return;
      }
      if (!const ['licence', 'rc', 'selfie'].every(_documents.containsKey)) {
        setState(
          () => _error =
              'Add the licence, RC and selfie images before submitting.',
        );
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_signup) {
        await AuthService.instance.signUp(
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          password: _password.text,
          role: _role,
          licenseNumber: _license.text,
          vehicleNumber: _vehicleNumber.text.replaceAll(' ', ''),
          vehicleModel: _vehicleModel.text,
          licenseExpiry: _licenseExpiry?.toIso8601String() ?? '',
          upiId: _upiId.text,
          documentsBase64: {
            for (final e in _documents.entries)
              e.key: base64Encode(_compressDocument(e.value)),
          },
        );
        await _rememberEmail(_email.text);
        _showAuthGate();
      } else {
        await AuthService.instance.signIn(
          email: _email.text,
          password: _password.text,
          expectedRole: _role,
        );
        await _rememberEmail(_email.text);
        _showAuthGate();
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = 'Could not complete sign-in. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.signInWithGoogle(newUserRole: _role);
      if (FirebaseAuth.instance.currentUser != null) _showAuthGate();
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Google sign-in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showAuthGate() {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      FairRideRoutes.authGate,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: _signup ? 'Create account' : 'Welcome back',
    subtitle: _signup
        ? 'Set up your FairRide profile.'
        : 'Sign in to continue to FairRide.',
    showBack: true,
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoleSwitch(value: _role, onChanged: (r) => setState(() => _role = r)),
          const SizedBox(height: 18),
          if (_signup) ...[
            AuthTextField(
              label: 'Full name',
              controller: _name,
              validator: validateName,
            ),
            AuthTextField(
              label: 'Phone number',
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: validatePhone,
            ),
            if (_role == 'driver') ...[
              AuthTextField(
                label: 'License number',
                controller: _license,
                onChanged: (v) {
                  final upper = v.toUpperCase();
                  if (v != upper) {
                    _license.value = _license.value.copyWith(
                      text: upper,
                      selection: TextSelection.collapsed(offset: upper.length),
                    );
                  }
                },
                validator: (v) =>
                    RegExp(r'^[A-Z]{2}[0-9]{2}\s?[0-9]{11}$')
                        .hasMatch((v ?? '').trim())
                    ? null
                    : 'Use Indian DL format, for example DL01 12345678901',
              ),
              AuthTextField(
                label: 'Vehicle registration number',
                controller: _vehicleNumber,
                onChanged: (v) {
                  final upper = v.toUpperCase();
                  if (v != upper) {
                    _vehicleNumber.value = _vehicleNumber.value.copyWith(
                      text: upper,
                      selection: TextSelection.collapsed(offset: upper.length),
                    );
                  }
                },
                validator: (v) =>
                    RegExp(r'^[A-Z]{2}[0-9]{1,2}[A-Z]{1,3}[0-9]{4}$')
                        .hasMatch((v ?? '').replaceAll(' ', '').toUpperCase())
                    ? null
                    : 'Enter a valid Indian vehicle registration number',
              ),
              AuthTextField(
                label: 'Vehicle make and model',
                controller: _vehicleModel,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter your vehicle model'
                    : null,
              ),
              AuthTextField(
                label: 'UPI ID',
                controller: _upiId,
                hint: 'name@bank',
                validator: (v) =>
                    RegExp(r'^[\w.-]{2,256}@[\w.-]{2,64}$')
                        .hasMatch((v ?? '').trim())
                    ? null
                    : 'Enter a valid UPI ID',
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(
                  _licenseExpiry == null
                      ? 'Choose licence expiry date'
                      : 'Licence expires ${DateFormat.yMMMd().format(_licenseExpiry!)}',
                ),
                onTap: _chooseExpiry,
              ),
              for (final doc in const {
                'licence': 'Driving licence front',
                'rc': 'Vehicle registration (RC)',
                'selfie': 'Driver selfie',
              }.entries)
                _documentTile(doc.key, doc.value),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Driver profiles stay pending until an administrator checks the details and documents.',
                  style: TextStyle(color: FairRideColors.muted, fontSize: 12),
                ),
              ),
            ],
          ],
          AuthTextField(
            label: 'Email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail,
          ),
          if (!_signup && _recentEmails.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Previous emails · tap to fill',
              style: TextStyle(fontSize: 12, color: FairRideColors.muted),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final email in _recentEmails)
                  InputChip(
                    label: Text(email),
                    onPressed: () {
                      _email.value = TextEditingValue(
                        text: email,
                        selection: TextSelection.collapsed(offset: email.length),
                      );
                    },
                    onDeleted: () => _removeRecentEmail(email),
                  ),
              ],
            ),
          ],
          AuthTextField(
            label: 'Password',
            controller: _password,
            obscure: true,
            action: TextInputAction.done,
            validator: validatePassword,
          ),
          if (_error != null) ErrorBanner(_error!),
          PrimaryButton(
            text: _signup
                ? 'Create account'
                : 'Sign in as ${_role[0].toUpperCase()}${_role.substring(1)}',
            loading: _busy,
            onPressed: _submit,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _google,
              icon: const Icon(Icons.login),
              label: const Text('Continue with Google'),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _signup = !_signup;
                      _error = null;
                    }),
              child: Text(
                _signup
                    ? 'Already have an account? Sign in'
                    : 'New to FairRide? Create an account',
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _chooseExpiry() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) setState(() => _licenseExpiry = date);
  }

  Future<void> _pickDocument(String key, ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1000,
        imageQuality: 50,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final compressed = _compressDocument(bytes);
      if (compressed.length > 680 * 1024) {
        if (mounted) {
          fairRideSnack(
            context,
            'That image is too large after compression. Please choose a smaller image.',
          );
        }
        return;
      }
      setState(() => _documents[key] = compressed);
    } catch (e) {
      if (mounted) fairRideSnack(context, 'Could not load document image: $e');
    }
  }

  Uint8List _compressDocument(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final resized = decoded.width > 1000
        ? img.copyResize(decoded, width: 1000)
        : decoded;
    for (final quality in [50, 35, 20, 10]) {
      final out = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
      if (out.length <= 680 * 1024) return out;
    }
    return Uint8List.fromList(img.encodeJpg(resized, quality: 5));
  }

  Widget _documentTile(String key, String label) => Card(
    child: ListTile(
      leading: _documents[key] == null
          ? const Icon(Icons.add_a_photo_outlined)
          : ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(
                _documents[key]!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
      title: Text(label),
      subtitle: Text(
        _documents.containsKey(key)
            ? 'Image ready · replace or remove'
            : 'Required for driver review',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<ImageSource>(
            onSelected: (source) => _pickDocument(key, source),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: ImageSource.camera,
                child: Text('Take photo'),
              ),
              PopupMenuItem(
                value: ImageSource.gallery,
                child: Text('Choose from gallery'),
              ),
            ],
            child: const Icon(Icons.upload),
          ),
          if (_documents.containsKey(key))
            IconButton(
              tooltip: 'Remove image',
              onPressed: () => setState(() => _documents.remove(key)),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
    ),
  );
}
