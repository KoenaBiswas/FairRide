part of 'fare_ride_screens.dart';

class FareRideBrand extends StatelessWidget {
  const FareRideBrand({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compact ? 36 : 44,
        height: compact ? 36 : 44,
        decoration: BoxDecoration(
          color: FareRideColors.green,
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
        'FareRide',
        style: TextStyle(
          color: FareRideColors.ink,
          fontSize: compact ? 20 : 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -.6,
        ),
      ),
    ],
  );
}

class FareRidePrimaryButton extends StatelessWidget {
  const FareRidePrimaryButton({
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
        backgroundColor: FareRideColors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
  );
}

class FareRideSectionTitle extends StatelessWidget {
  const FareRideSectionTitle(this.title, {super.key, this.trailing});
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
            color: FareRideColors.ink,
          ),
        ),
      ),
      ?trailing,
    ],
  );
}

class FareRideCard extends StatelessWidget {
  const FareRideCard({
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
      border: Border.all(color: FareRideColors.line),
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

class FareRidePage extends StatelessWidget {
  const FareRidePage({
    super.key,
    required this.title,
    required this.child,
    this.bottom,
    this.showBack = true,
    this.navigationIndex,
  });
  final String title;
  final Widget child;
  final Widget? bottom;
  final bool showBack;
  final int? navigationIndex;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: showBack
          ? IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            )
          : null,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
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
          fareRideBottomNav(context, selected: navigationIndex!),
      ],
    ),
  );
}

class FareRideField extends StatelessWidget {
  const FareRideField({
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
      prefixIcon: icon == null ? null : Icon(icon, color: FareRideColors.muted),
      prefixText: prefixText,
    ),
  );
}

/// Recent-value picker that reuses FareRideField's controller and visual style.
class FareRideSuggestField extends StatefulWidget {
  const FareRideSuggestField({
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
  State<FareRideSuggestField> createState() => _FareRideSuggestFieldState();
}

class _FareRideSuggestFieldState extends State<FareRideSuggestField> {
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
        FareRideField(
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

void fareRideSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}

String? fareRideRequired(String? value) =>
    (value == null || value.trim().isEmpty)
    ? 'Please fill out this field'
    : null;

Widget fareRideBottomNav(BuildContext context, {required int selected}) =>
    NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (index) {
        if (index == selected) return;
        final route = switch (index) {
          0 => FareRideRoutes.riderDashboard,
          1 => FareRideRoutes.requestRide,
          _ => FareRideRoutes.fareSplit,
        };
        Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
      },
      destinations: const [
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
