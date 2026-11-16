import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../fare_ride_screens.dart';
import 'auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) => const FareRideAuthGate();
}

class FareRideAuthGate extends StatelessWidget {
  const FareRideAuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: AuthService.instance.authChanges,
    builder: (context, auth) {
      if (auth.connectionState == ConnectionState.waiting) {
        return const _Loading();
      }
      final user = auth.data;
      if (user == null) return const FareRideLandingScreen();
      final googleUser = user.providerData.any(
        (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
      );
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: AuthService.instance.userDoc(user.uid),
        builder: (context, profile) {
          if (profile.hasError) {
            return _MessageScreen(
              message: 'Unable to load your FareRide profile: ${profile.error}',
              action: TextButton(
                onPressed: AuthService.instance.signOut,
                child: const Text('Log out'),
              ),
            );
          }
          if (!profile.hasData) return const _Loading();
          final role = profile.data?.data()?['role'];
          if (role != 'rider' && role != 'driver') {
            return _RoleRecoveryScreen(
              user: user,
              riderOnly: googleUser && !profile.data!.exists,
            );
          }
          if (!googleUser && !user.emailVerified) {
            return const _VerifyEmailScreen();
          }
          if (role == 'driver' &&
              profile.data?.data()?['driverOnboardingComplete'] == false) {
            return const FareRideDriverProfileScreen(onboardingMode: true);
          }
          if (role == 'rider') return const FareRideRiderDashboardScreen();
          if (role == 'driver') return const FareRideDriverDashboardScreen();
          return const _RoleRecoveryScreen();
        },
      );
    },
  );
}

class _RoleRecoveryScreen extends StatefulWidget {
  const _RoleRecoveryScreen({this.user, this.riderOnly = false});
  final User? user;
  final bool riderOnly;

  @override
  State<_RoleRecoveryScreen> createState() => _RoleRecoveryScreenState();
}

class _RoleRecoveryScreenState extends State<_RoleRecoveryScreen> {
  String _role = 'rider';
  bool _busy = false;
  String? _error;

  Future<void> _continue() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.createProfileForCurrentUser(_role);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Complete your FareRide profile'),
      actions: [
        TextButton.icon(
          onPressed: _busy ? null : AuthService.instance.signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.user?.displayName?.trim().isNotEmpty == true
                    ? 'Welcome, ${widget.user!.displayName}'
                    : 'Welcome to FareRide',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(widget.user?.email ?? ''),
              const SizedBox(height: 24),
              if (widget.riderOnly) ...[
                const Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.check_circle,
                      color: FareRideColors.green,
                    ),
                    title: Text('Rider'),
                    subtitle: Text(
                      'To drive with FareRide, create a driver account with email.',
                    ),
                  ),
                ),
              ] else ...[
                const Text('Choose how you want to use FareRide'),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'rider', label: Text('Rider')),
                    ButtonSegment(value: 'driver', label: Text('Driver')),
                  ],
                  selected: {_role},
                  onSelectionChanged: _busy
                      ? null
                      : (selected) => setState(() => _role = selected.first),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _continue,
                child: Text(
                  _busy
                      ? 'Saving profile…'
                      : 'Continue as ${_role[0].toUpperCase()}${_role.substring(1)}',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _VerifyEmailScreen extends StatefulWidget {
  const _VerifyEmailScreen();
  @override
  State<_VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<_VerifyEmailScreen> {
  bool _busy = false;
  String? _message;

  Future<void> _check() async {
    setState(() => _busy = true);
    await AuthService.instance.reloadUser();
    if (!mounted) return;
    final verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    setState(() {
      _busy = false;
      _message = verified
          ? 'Email confirmed. Loading your account…'
          : 'Email is not confirmed yet. Check your inbox and try again.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Confirm your email')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Confirm your email',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a confirmation link to ${FirebaseAuth.instance.currentUser?.email ?? 'your email address'}.',
              textAlign: TextAlign.center,
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _check,
              child: const Text('I have confirmed'),
            ),
            TextButton(
              onPressed: _busy ? null : AuthService.instance.resendVerification,
              child: const Text('Resend confirmation email'),
            ),
            TextButton(
              onPressed: AuthService.instance.signOut,
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MessageScreen extends StatelessWidget {
  const _MessageScreen({required this.message, this.action});
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            ?action,
          ],
        ),
      ),
    ),
  );
}
