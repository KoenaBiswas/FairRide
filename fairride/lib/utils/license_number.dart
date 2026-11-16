String normalizeIndianLicenseNumber(String value) =>
    value.replaceAll(RegExp(r'[\s-]+'), '').toUpperCase();

String? validateIndianLicenseNumber(String? value) {
  final normalized = normalizeIndianLicenseNumber(value ?? '');
  return RegExp(r'^[A-Z]{2}[0-9]{2}[0-9]{11}$').hasMatch(normalized)
      ? null
      : 'Enter a valid Indian licence number, e.g. DL0420190045821';
}
