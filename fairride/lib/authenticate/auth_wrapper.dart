import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../fair_ride_screens.dart';
import 'auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: AuthService.instance.authChanges,
    builder: (context, auth) {
      if (auth.connectionState == ConnectionState.waiting) {
        return const _Loading();
      }
      final user = auth.data;
      if (user == null) return const FairRideLandingScreen();
      if (!user.emailVerified) return const _VerifyEmailScreen();
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: AuthService.instance.userDoc(user.uid),
        builder: (context, profile) {
          final role = profile.data?.data()?['role'];
          if (profile.data?.data()?['isAdmin'] == true) {
            return const FairRideAdminReviewScreen();
          }
          if (role == 'rider') return const FairRideRiderDashboardScreen();
          if (role == 'driver') return const FairRideDriverDashboardScreen();
          if (profile.hasError) {
            return _MessageScreen(
              message: 'Unable to load your FairRide profile. Check your connection and try again.',
              action: TextButton(
                onPressed: AuthService.instance.signOut,
                child: const Text('Sign out'),
              ),
            );
          }
          return const _Loading();
        },
      );
    },
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
          ? 'Email verified. Loading your account…'
          : 'Email is not verified yet. Check your inbox and try again.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Verify your email')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Verify your email',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a verification link to ${FirebaseAuth.instance.currentUser?.email ?? 'your email address'}.',
              textAlign: TextAlign.center,
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _check,
              child: const Text('I have verified'),
            ),
            TextButton(
              onPressed: _busy ? null : AuthService.instance.resendVerification,
              child: const Text('Resend verification email'),
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
