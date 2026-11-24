part of 'fair_ride_screens.dart';

class FairRideBrand extends StatelessWidget {
  const FairRideBrand({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compact ? 36 : 44,
        height: compact ? 36 : 44,
        decoration: BoxDecoration(
          color: FairRideColors.green,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.alt_route_rounded,
          color: Colors.white,
          size: compact ? 21 : 26,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        'FairRide',
        style: TextStyle(
          color: FairRideColors.ink,
          fontSize: compact ? 20 : 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -.6,
        ),
      ),
    ],
  );
}

class FairRidePrimaryButton extends StatelessWidget {
  const FairRidePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 54,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      style: FilledButton.styleFrom(
        backgroundColor: FairRideColors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
  );
}

class FairRideSectionTitle extends StatelessWidget {
  const FairRideSectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: FairRideColors.ink,
          ),
        ),
      ),
      ?trailing,
    ],
  );
}

class FairRideCard extends StatelessWidget {
  const FairRideCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: FairRideColors.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080D352B),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class FairRidePage extends StatelessWidget {
  const FairRidePage({
    super.key,
    required this.title,
    required this.child,
    this.bottom,
    this.showBack = true,
    this.navigationIndex,
    this.role = 'rider',
  });
  final String title;
  final Widget child;
  final Widget? bottom;
  final bool showBack;
  final int? navigationIndex;
  final String role;
  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: FairRideAccountDrawer(isDriver: role == 'driver'),
    appBar: AppBar(
      leading: showBack
          ? IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            )
          : null,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      actions: [
        Builder(
          builder: (scaffoldContext) => IconButton(
            tooltip: 'Open menu',
            onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
            icon: const Icon(Icons.menu_rounded),
          ),
        ),
      ],
    ),
    body: SafeArea(child: child),
    bottomNavigationBar: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bottom != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: bottom,
            ),
          ),
        if (navigationIndex != null)
          fairRideBottomNav(
            context,
            selected: navigationIndex!,
            role: role,
          ),
      ],
    ),
  );
}

class FairRideField extends StatelessWidget {
  const FairRideField({
    super.key,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.controller,
    this.validator,
    this.initialValue,
    this.onChanged,
    this.prefixText,
    this.autofillHints,
    this.textInputAction,
    this.focusNode,
  });
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? prefixText;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    initialValue: initialValue,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    focusNode: focusNode,
    autofillHints: autofillHints,
    validator: validator,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: FairRideColors.muted),
      prefixText: prefixText,
    ),
  );
}

/// Recent-value picker that reuses FairRideField's controller and visual style.
class FairRideSuggestField extends StatefulWidget {
  const FairRideSuggestField({
    super.key,
    required this.label,
    required this.controller,
    required this.suggestions,
    this.onSelected,
    this.onRemove,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.hint,
  });
  final String label;
  final String? hint;
  final TextEditingController controller;
  final List<String> suggestions;
  final ValueChanged<String>? onSelected;
  final ValueChanged<String>? onRemove;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;

  @override
  State<FairRideSuggestField> createState() => _FairRideSuggestFieldState();
}

class _FairRideSuggestFieldState extends State<FairRideSuggestField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawAutocomplete<String>(
    textEditingController: widget.controller,
    focusNode: _focus,
    displayStringForOption: (option) => option,
    optionsBuilder: (value) {
      final query = value.text.trim().toLowerCase();
      return widget.suggestions.where(
        (item) => query.isEmpty || item.toLowerCase().contains(query),
      );
    },
    onSelected: (value) {
      widget.controller.text = value;
      widget.onSelected?.call(value);
    },
    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) =>
        FairRideField(
          label: widget.label,
          hint: widget.hint,
          controller: controller,
          focusNode: focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          validator: widget.validator,
        ),
    optionsViewBuilder: (context, onSelected, options) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220, maxWidth: 420),
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              for (final option in options)
                ListTile(
                  dense: true,
                  title: Text(option),
                  trailing: widget.onRemove == null
                      ? null
                      : IconButton(
                          tooltip: 'Remove suggestion',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => widget.onRemove!(option),
                        ),
                  onTap: () => onSelected(option),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

void fairRideSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}

Future<void> fairRideSignOut(BuildContext context) async {
  await AuthService.instance.signOut();
  if (!context.mounted) return;
  Navigator.pushNamedAndRemoveUntil(
    context,
    FairRideRoutes.authGate,
    (_) => false,
  );
}

String? fairRideRequired(String? value) =>
    (value == null || value.trim().isEmpty)
    ? 'Please fill out this field'
    : null;

Widget fairRideBottomNav(
  BuildContext context, {
  required int selected,
  String role = 'rider',
}) => NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (index) {
        if (index == selected) return;
        final route = role == 'driver'
            ? (index == 0 ? FairRideRoutes.driverDashboard : FairRideRoutes.postRide)
            : switch (index) {
                0 => FairRideRoutes.riderDashboard,
                1 => FairRideRoutes.requestRide,
                _ => FairRideRoutes.fareSplit,
              };
        Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
      },
      destinations: role == 'driver'
          ? const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_road_outlined),
                selectedIcon: Icon(Icons.add_road),
                label: 'Post ride',
              ),
            ]
          : const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_rounded),
                label: 'Find ride',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                label: 'Fare split',
              ),
            ],
    );
