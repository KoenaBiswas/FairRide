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
  final _license = TextEditingController();
  final _vehicleNumber = TextEditingController();
  final _vehicleModel = TextEditingController();
  late String _role = widget.initialRole;
  late bool _signup = widget.initialSignup;
  bool _busy = false;
  String? _error;

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
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
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
          vehicleNumber: _vehicleNumber.text,
          vehicleModel: _vehicleModel.text,
        );
        _showAuthGate();
      } else {
        await AuthService.instance.signIn(
          email: _email.text,
          password: _password.text,
          expectedRole: _role,
        );
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
      FareRideRoutes.authGate,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: _signup ? 'Create account' : 'Welcome back',
    subtitle: _signup
        ? 'Set up your FareRide profile.'
        : 'Sign in to continue to FareRide.',
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
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter your license number'
                    : null,
              ),
              AuthTextField(
                label: 'Vehicle registration number',
                controller: _vehicleNumber,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter your vehicle number'
                    : null,
              ),
              AuthTextField(
                label: 'Vehicle make and model',
                controller: _vehicleModel,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter your vehicle model'
                    : null,
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Driver profiles are saved for pending review. No documents are uploaded.',
                  style: TextStyle(color: FareRideColors.muted, fontSize: 12),
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
                    : 'New to FareRide? Create an account',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
