import 'package:flutter/material.dart';

const kInk = Color(0xFF0B1F1C);
const kPrimary = Color(0xFF0E7C6B);
const kSoft = Color(0xFFDDF1EC);
const kMuted = Color(0xFF4F615D);
const kLine = Color(0xFFE1E8E5);
const kField = Color(0xFFCBD6D2);

// ---------- Logo ----------
class FairRideLogo extends StatelessWidget {
  const FairRideLogo({super.key, this.dark = false, this.size = 22});
  final bool dark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final a = dark ? Colors.white : kInk;
    final b = dark ? const Color(0xFF5ED1BD) : kPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: Size.square(size + 10), painter: _MarkPainter()),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Fair',
                style: TextStyle(color: a),
              ),
              TextSpan(
                text: 'Ride',
                style: TextStyle(color: b),
              ),
            ],
          ),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 56;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(16 * k)),
      Paint()..color = kPrimary,
    );
    final path = Path()
      ..moveTo(13 * k, 38 * k)
      ..cubicTo(19 * k, 38 * k, 20 * k, 28 * k, 28 * k, 28 * k)
      ..cubicTo(36 * k, 28 * k, 37 * k, 38 * k, 43 * k, 38 * k);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * k
        ..strokeCap = StrokeCap.round,
    );
    final dot = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(13 * k, 38 * k), 4 * k, dot);
    canvas.drawCircle(Offset(43 * k, 38 * k), 4 * k, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------- Page shell: dark header + white rounded sheet ----------
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kInk,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (showBack)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      const FairRideLogo(dark: true, size: 24),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFB7C9C4),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Text field ----------
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.obscure = false,
    this.hint,
    this.action = TextInputAction.next,
    this.onSubmitted,
    this.onChanged,
    this.autofillHints,
    this.focusNode,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? hint;
  final TextInputAction action;
  final VoidCallback? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _hidden = widget.obscure;

  @override
  void didUpdateWidget(covariant AuthTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscure != widget.obscure) {
      _hidden = widget.obscure;
    }
  }

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c, width: w),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: kMuted,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            autofillHints: widget.autofillHints,
            obscureText: widget.obscure && _hidden,
            keyboardType: widget.keyboardType,
            textInputAction: widget.action,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: (_) => widget.onSubmitted?.call(),
            style: const TextStyle(fontSize: 15, color: kInk),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: Color(0xFF8FA09B)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              border: _border(kField),
              enabledBorder: _border(kField),
              focusedBorder: _border(kPrimary, 1.8),
              errorBorder: _border(const Color(0xFFB3261E)),
              focusedErrorBorder: _border(const Color(0xFFB3261E), 1.8),
              suffixIcon: widget.obscure
                  ? IconButton(
                      tooltip: _hidden ? 'Show password' : 'Hide password',
                      icon: Icon(
                        _hidden ? Icons.visibility_off : Icons.visibility,
                        color: kMuted,
                      ),
                      onPressed: () => setState(() => _hidden = !_hidden),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Rider / Driver switch ----------
class RoleSwitch extends StatelessWidget {
  const RoleSwitch({super.key, required this.value, required this.onChanged});
  final String value; // 'rider' or 'driver'
  final ValueChanged<String> onChanged;

  Widget _seg(String key, String label) {
    final on = value == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: on
                ? const [
                    BoxShadow(
                      color: Color(0x1F0B1F1C),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: on ? FontWeight.w600 : FontWeight.w500,
              color: on ? kPrimary : kMuted,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kLine,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [_seg('rider', 'Rider'), _seg('driver', 'Driver')]),
    );
  }
}

// ---------- Button ----------
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
  });
  final String text;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kPrimary.withAlpha(160),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(text),
      ),
    );
  }
}

// ---------- Error banner ----------
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF8C1D18), fontSize: 14),
      ),
    );
  }
}

// ---------- Validators ----------
String? validateName(String? v) =>
    (v == null || v.trim().length < 2) ? 'Enter your full name' : null;

String? validateEmail(String? v) {
  final s = v?.trim() ?? '';
  if (s.isEmpty) return 'Enter your email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
    return 'Enter a valid email';
  }
  return null;
}

String? validatePhone(String? v) {
  final s = v?.trim() ?? '';
  if (!RegExp(r'^[0-9]{10}$').hasMatch(s)) {
    return 'Enter a 10-digit phone number';
  }
  return null;
}

String? validatePassword(String? v) =>
    (v == null || v.length < 6) ? 'Use at least 6 characters' : null;
