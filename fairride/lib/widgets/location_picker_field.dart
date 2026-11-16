import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../services/recent_store.dart';

class LocationChoice {
  const LocationChoice({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;
}

/// Place search with platform geocoder suggestions and an explicit current
/// location action. A value is emitted only after the user selects a result.
class LocationPickerField extends StatefulWidget {
  const LocationPickerField({
    super.key,
    required this.label,
    required this.onSelected,
    this.hint = 'Search a place or address',
  });

  final String label;
  final String hint;
  final ValueChanged<LocationChoice?> onSelected;

  @override
  State<LocationPickerField> createState() => _LocationPickerFieldState();
}

class _LocationPickerFieldState extends State<LocationPickerField> {
  final _controller = TextEditingController();
  final _geocoding = Geocoding();
  Timer? _debounce;
  List<LocationChoice> _suggestions = const [];
  bool _searching = false;
  bool _locating = false;
  String? _message;
  List<RecentPlace> _recentPlaces = const [];
  bool _focused = false;
  final _focusNode = FocusNode();
  int _queryVersion = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRecentPlaces();
    _focusNode.addListener(
      () => setState(() => _focused = _focusNode.hasFocus),
    );
  }

  Future<void> _loadRecentPlaces() async {
    final values = await RecentStore.instance.recentPlaces();
    if (mounted) setState(() => _recentPlaces = values);
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _queryVersion++;
    widget.onSelected(null);
    setState(() {
      _suggestions = const [];
      _message = null;
      _searching = query.trim().length >= 3;
    });
    if (query.trim().length < 3) {
      setState(() => _searching = false);
      return;
    }
    final version = _queryVersion;
    _debounce = Timer(const Duration(milliseconds: 700), () {
      _search(query.trim(), version);
    });
  }

  Future<void> _search(String query, int version) async {
    try {
      final locations = await _geocoding.locationFromAddress(query);
      final results = <LocationChoice>[];
      final seen = <String>{};
      for (final location in locations.take(5)) {
        if (!mounted || version != _queryVersion) return;
        final placemarks = await _geocoding.placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        final name = placemarks.isEmpty
            ? query
            : _formatPlacemark(placemarks.first);
        final key =
            '${location.latitude.toStringAsFixed(4)},${location.longitude.toStringAsFixed(4)}';
        if (seen.add(key)) {
          results.add(
            LocationChoice(
              name: name.isEmpty ? query : name,
              latitude: location.latitude,
              longitude: location.longitude,
            ),
          );
        }
      }
      if (!mounted || version != _queryVersion) return;
      setState(() {
        _suggestions = results;
        _searching = false;
        _message = results.isEmpty
            ? 'No matches found. Try a nearby landmark or full address.'
            : null;
      });
    } catch (_) {
      if (!mounted || version != _queryVersion) return;
      setState(() {
        _searching = false;
        _message = 'Could not search places right now. Try a fuller address or use your location.';
      });
    }
  }

  String _formatPlacemark(Placemark place) {
    final parts =
        <String?>[
              place.name,
              place.street,
              place.subLocality,
              place.locality,
              place.administrativeArea,
              place.country,
            ]
            .whereType<String>()
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList();
    final unique = <String>[];
    for (final part in parts) {
      if (!unique.contains(part)) unique.add(part);
    }
    return unique.join(', ');
  }

  void _choose(LocationChoice choice) {
    _debounce?.cancel();
    _queryVersion++;
    setState(() {
      _controller.text = choice.name;
      _suggestions = const [];
      _message = null;
    });
    widget.onSelected(choice);
    FocusScope.of(context).unfocus();
  }

  Future<void> _useCurrentLocation() async {
    _debounce?.cancel();
    _queryVersion++;
    widget.onSelected(null);
    setState(() {
      _locating = true;
      _message = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const _LocationFailure(
          'Turn on location services and try again.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const _LocationFailure(
          'Location permission was denied. You can still search for a place.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        throw const _LocationFailure(
          'Location permission is blocked in settings. You can still search for a place.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final placemarks = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final name = placemarks.isEmpty
          ? 'Current location'
          : _formatShortPlacemark(placemarks.first);
      _choose(
        LocationChoice(
          name: name.isEmpty ? 'Current location' : name,
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } on _LocationFailure catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Could not get your location. Search for a place instead.',
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  String _formatShortPlacemark(Placemark place) {
    final parts = <String?>[place.name, place.subLocality, place.locality]
        .whereType<String>()
        .map((part) => part.trim())
        .where(
          (part) =>
              part.isNotEmpty &&
              !RegExp(r'^\d{6}$').hasMatch(part) &&
              !part.contains('+'),
        )
        .toList();
    final unique = <String>[];
    for (final part in parts) {
      if (!unique.contains(part)) unique.add(part);
    }
    final result = unique.join(', ');
    return result.length > 40
        ? '${result.substring(0, 37).trimRight()}…'
        : result;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: _controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        onChanged: _onChanged,
        onSubmitted: (value) {
          _debounce?.cancel();
          if (value.trim().length >= 3) _search(value.trim(), ++_queryVersion);
        },
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.location_on_outlined),
          suffixIcon: _searching
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: 'Use current location',
                  onPressed: _locating ? null : _useCurrentLocation,
                  icon: _locating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                ),
        ),
      ),
      if (_focused &&
          (_controller.text.isEmpty ||
              _recentPlaces.any(
                (place) => place.label.toLowerCase().contains(
                  _controller.text.toLowerCase(),
                ),
              )))
        Card(
          margin: const EdgeInsets.only(top: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_controller.text.isEmpty)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.my_location),
                  title: const Text('Use my current location'),
                  trailing: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _locating ? null : _useCurrentLocation,
                ),
              for (final place in _recentPlaces.where(
                (place) =>
                    _controller.text.isEmpty ||
                    place.label.toLowerCase().contains(
                      _controller.text.toLowerCase(),
                    ),
              ))
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.history),
                  title: Text(place.label),
                  trailing: IconButton(
                    tooltip: 'Remove suggestion',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () async {
                      await RecentStore.instance.removePlace(place.label);
                      await _loadRecentPlaces();
                    },
                  ),
                  onTap: () => _choose(
                    LocationChoice(
                      name: place.label,
                      latitude: place.latitude,
                      longitude: place.longitude,
                    ),
                  ),
                ),
            ],
          ),
        ),
      if (_suggestions.isNotEmpty)
        Card(
          margin: const EdgeInsets.only(top: 4),
          child: Column(
            children: [
              for (final choice in _suggestions)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(choice.name),
                  subtitle: const Text('Tap to use this place'),
                  onTap: () => _choose(choice),
                ),
            ],
          ),
        ),
      if (_message != null)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 8),
          child: Text(_message!, style: Theme.of(context).textTheme.bodySmall),
        ),
    ],
  );
}

class _LocationFailure implements Exception {
  const _LocationFailure(this.message);
  final String message;
}
