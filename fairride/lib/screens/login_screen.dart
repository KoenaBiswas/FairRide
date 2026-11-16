part of '../fare_ride_screens.dart';

class FareRideLoginScreen extends StatefulWidget {
  const FareRideLoginScreen({
    super.key,
    this.initialRole = 'rider',
    this.initialSignup = false,
  });
  final String initialRole;
  final bool initialSignup;
  @override
  State<FareRideLoginScreen> createState() => _FareRideLoginScreenState();
}

class _FareRideLoginScreenState extends State<FareRideLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _license = TextEditingController();
  final _vehicleNumber = TextEditingController();
  final _vehicleModel = TextEditingController();
  final _upiId = TextEditingController(text: '7291098653@pthdfc');
  DateTime? _licenseExpiry;
  final Map<String, Uint8List> _documents = {};
  late String _role = widget.initialRole;
  late bool _signup = widget.initialSignup;
  bool _busy = false;
  String? _error;
  List<String> _emails = const [];
  List<String> _phones = const [];
  final _emailFocus = FocusNode();

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _phone,
      _password,
      _confirmPassword,
      _license,
      _vehicleNumber,
      _vehicleModel,
      _upiId,
    ]) {
      c.dispose();
    }
    _emailFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final store = RecentStore.instance;
    final values = await Future.wait([
      store.recentEmails(),
      store.recentPhones(),
      store.lastRole(),
    ]);
    if (!mounted) return;
    setState(() {
      _emails = values[0] as List<String>;
      _phones = values[1] as List<String>;
      final role = values[2] as String?;
      if (!(widget.initialSignup && widget.initialRole == 'driver') &&
          (role == 'rider' || role == 'driver')) {
        _role = role!;
      }
    });
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
        await RecentStore.instance.saveEmail(_email.text);
        await RecentStore.instance.savePhone(_phone.text);
        await RecentStore.instance.saveRole(_role);
        TextInput.finishAutofillContext(shouldSave: true);
        _showAuthGate();
      } else {
        await AuthService.instance.signIn(
          email: _email.text,
          password: _password.text,
          expectedRole: _role,
        );
        await RecentStore.instance.saveEmail(_email.text);
        await RecentStore.instance.saveRole(_role);
        TextInput.finishAutofillContext(shouldSave: true);
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
      final savedRole = await AuthService.instance.signInWithGoogle();
      if (savedRole != null && savedRole != _role) {
        await AuthService.instance.signOut();
        if (mounted) {
          final registeredRole =
              '${savedRole[0].toUpperCase()}${savedRole.substring(1)}';
          setState(
            () => _error =
                'This account is registered as a $savedRole. Switch to $registeredRole to log in.',
          );
        }
        return;
      }
      final email = FirebaseAuth.instance.currentUser?.email;
      if (email != null) {
        await RecentStore.instance.saveEmail(email);
        await RecentStore.instance.saveRole(_role);
        TextInput.finishAutofillContext(shouldSave: true);
        _showAuthGate();
      }
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
      FareRideRoutes.authGate,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showGoogle = !_signup || _role == 'rider';
    return AuthScaffold(
      title: _signup ? 'Create account' : 'Welcome back',
      subtitle: _signup
          ? 'Set up your FareRide profile.'
          : 'Sign in to continue to FareRide.',
      showBack: true,
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoleSwitch(
                value: _role,
                onChanged: (r) {
                  setState(() => _role = r);
                  RecentStore.instance.saveRole(r);
                },
              ),
              const SizedBox(height: 18),
              if (_signup) ...[
                AuthTextField(
                  label: 'Full name',
                  controller: _name,
                  action: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: validateName,
                ),
                RawAutocomplete<String>(
                  textEditingController: _phone,
                  optionsBuilder: (value) => _phones.where(
                    (v) => value.text.isEmpty || v.contains(value.text),
                  ),
                  onSelected: (value) => _phone.text = value,
                  fieldViewBuilder: (context, controller, focus, submitted) =>
                      AuthTextField(
                        label: 'Phone number',
                        controller: controller,
                        focusNode: focus,
                        keyboardType: TextInputType.phone,
                        action: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        validator: validatePhone,
                      ),
                  optionsViewBuilder: (context, select, options) => Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 5,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final value in options)
                            ListTile(
                              title: Text(value),
                              onTap: () => select(value),
                              trailing: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () async {
                                  await RecentStore.instance.removePhone(value);
                                  final updated = await RecentStore.instance
                                      .recentPhones();
                                  if (mounted) {
                                    setState(() => _phones = updated);
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
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
                          selection: TextSelection.collapsed(
                            offset: upper.length,
                          ),
                        );
                      }
                    },
                    validator: validateIndianLicenseNumber,
                  ),
                  AuthTextField(
                    label: 'Vehicle registration number',
                    controller: _vehicleNumber,
                    onChanged: (v) {
                      final upper = v.toUpperCase();
                      if (v != upper) {
                        _vehicleNumber.value = _vehicleNumber.value.copyWith(
                          text: upper,
                          selection: TextSelection.collapsed(
                            offset: upper.length,
                          ),
                        );
                      }
                    },
                    validator: (v) =>
                        RegExp(
                          r'^[A-Z]{2}[0-9]{1,2}[A-Z]{1,3}[0-9]{4}$',
                        ).hasMatch((v ?? '').replaceAll(' ', '').toUpperCase())
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
                      'Save your profile after uploading all three documents to start posting rides.',
                      style: TextStyle(
                        color: FareRideColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
              AutofillGroup(
                child: Column(
                  children: [
                    RawAutocomplete<String>(
                      textEditingController: _email,
                      focusNode: _emailFocus,
                      optionsBuilder: (value) {
                        final query = value.text.trim().toLowerCase();
                        return _emails.where(
                          (e) => query.isEmpty || e.contains(query),
                        );
                      },
                      onSelected: (value) => _email.text = value,
                      fieldViewBuilder:
                          (context, controller, focus, submitted) =>
                              AuthTextField(
                                label: 'Email',
                                controller: controller,
                                focusNode: focus,
                                keyboardType: TextInputType.emailAddress,
                                action: TextInputAction.next,
                                autofillHints: _signup
                                    ? const [AutofillHints.email]
                                    : const [
                                        AutofillHints.username,
                                        AutofillHints.email,
                                      ],
                                validator: validateEmail,
                              ),
                      optionsViewBuilder: (context, select, options) => Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 5,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              children: [
                                for (final option in options)
                                  ListTile(
                                    title: Text(option),
                                    onTap: () => select(option),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () async {
                                        await RecentStore.instance.removeEmail(
                                          option,
                                        );
                                        final updated = await RecentStore
                                            .instance
                                            .recentEmails();
                                        if (mounted) {
                                          setState(() => _emails = updated);
                                        }
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    AuthTextField(
                      label: 'Password',
                      controller: _password,
                      obscure: true,
                      action: _signup
                          ? TextInputAction.next
                          : TextInputAction.done,
                      autofillHints: _signup
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      validator: validatePassword,
                    ),
                    if (_signup)
                      AuthTextField(
                        label: 'Confirm password',
                        controller: _confirmPassword,
                        obscure: true,
                        action: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (value) => value != _password.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                  ],
                ),
              ),
              if (_error != null) ErrorBanner(_error!),
              PrimaryButton(
                text: _signup
                    ? 'Create account'
                    : 'Sign in as ${_role[0].toUpperCase()}${_role.substring(1)}',
                loading: _busy,
                onPressed: _submit,
              ),
              if (_signup && _role == 'driver')
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Drivers sign up with email so we can collect licence and vehicle details.',
                    style: TextStyle(color: FareRideColors.muted, fontSize: 12),
                  ),
                ),
              if (showGoogle) ...[
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or'),
                    ),
                    Expanded(child: Divider()),
                  ],
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
              ],
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
                        : 'New to FareRide? Create an account',
                  ),
                ),
              ),
              if (_emails.isNotEmpty || _phones.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await RecentStore.instance.clearSuggestions();
                      if (mounted) {
                        setState(() {
                          _emails = const [];
                          _phones = const [];
                        });
                      }
                    },
                    child: const Text('Clear saved suggestions'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

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
          fareRideSnack(
            context,
            'That image is too large after compression. Please choose a smaller image.',
          );
        }
        return;
      }
      setState(() => _documents[key] = compressed);
    } catch (e) {
      if (mounted) fareRideSnack(context, 'Could not load document image: $e');
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
            : 'Required to post rides',
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
