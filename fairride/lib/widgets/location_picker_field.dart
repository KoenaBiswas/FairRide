import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

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

/// Online OpenStreetMap place search, biased toward Delhi NCR. Search results
/// are cached and serialized so the public Photon demo endpoint is not hit
/// repeatedly while a user edits the same query.
class _PlaceSearchService {
  _PlaceSearchService._();
  static final instance = _PlaceSearchService._();

  final _client = http.Client();
  final _cache = <String, List<LocationChoice>>{};
  final _inFlight = <String, Future<List<LocationChoice>>>{};
  Future<void> _queue = Future<void>.value();
  DateTime? _lastRequestAt;

  Future<List<LocationChoice>> search(String query) {
    final key = query.trim().toLowerCase();
    final cached = _cache[key];
    if (cached != null) return Future.value(cached);
    final pending = _inFlight[key];
    if (pending != null) return pending;

    final result = Completer<List<LocationChoice>>();
    _inFlight[key] = result.future;
    _queue = _queue.then((_) async {
      final lastRequestAt = _lastRequestAt;
      if (lastRequestAt != null) {
        final elapsed = DateTime.now().difference(lastRequestAt);
        const interval = Duration(milliseconds: 1100);
        if (elapsed < interval) await Future<void>.delayed(interval - elapsed);
      }
      _lastRequestAt = DateTime.now();
      try {
        final places = await _fetch(query);
        _cache[key] = places;
        if (_cache.length > 80) _cache.remove(_cache.keys.first);
        result.complete(places);
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      } finally {
        _inFlight.remove(key);
      }
    });
    return result.future;
  }

  Future<List<LocationChoice>> _fetch(String query) async {
    final uri = Uri.https('photon.komoot.io', '/api/', {
      'q': query,
      'limit': '10',
      'lat': '28.6139',
      'lon': '77.2090',
      'zoom': '9',
      'location_bias_scale': '0.15',
      'countrycode': 'IN',
      'lang': 'en',
    });
    final response = await _client
        .get(uri, headers: {'User-Agent': 'FareRide/1.0'})
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Place search returned ${response.statusCode}.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final features = body['features'] as List? ?? const [];
    final results = <LocationChoice>[];
    final seen = <String>{};
    for (final feature in features) {
      if (feature is! Map<String, dynamic>) continue;
      final properties = feature['properties'];
      final geometry = feature['geometry'];
      if (properties is! Map<String, dynamic> ||
          geometry is! Map<String, dynamic>) {
        continue;
      }
      final coordinates = geometry['coordinates'];
      if (coordinates is! List || coordinates.length < 2) continue;
      final longitude = (coordinates[0] as num?)?.toDouble();
      final latitude = (coordinates[1] as num?)?.toDouble();
      if (latitude == null || longitude == null) continue;

      final parts = <String>[];
      for (final key in const [
        'name',
        'housenumber',
        'street',
        'district',
        'locality',
        'city',
        'county',
        'state',
        'postcode',
        'country',
      ]) {
        final value = properties[key];
        if (value is! String || value.trim().isEmpty) continue;
        final part = value.trim();
        if (!parts.any((existing) => existing.toLowerCase() == part.toLowerCase())) {
          parts.add(part);
        }
      }
      final displayName = properties['name'] is String
          ? (properties['name'] as String).trim()
          : '';
      final name = parts.isNotEmpty
          ? parts.join(', ')
          : (displayName.isNotEmpty ? displayName : query);
      final key =
          '${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';
      if (seen.add(key)) {
        results.add(
          LocationChoice(
            name: name,
            latitude: latitude,
            longitude: longitude,
          ),
        );
      }
    }
    return results;
  }
}

/// Online place search with device-geocoder fallback, map picking, and an
/// explicit current-location action. Values emit only after user selection.
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
      _searching = query.trim().length >= 2;
    });
    if (query.trim().length < 2) {
      setState(() => _searching = false);
      return;
    }
    final version = _queryVersion;
    _debounce = Timer(const Duration(milliseconds: 900), () {
      _search(query.trim(), version);
    });
  }

  Future<void> _search(String query, int version) async {
    List<LocationChoice> results = const [];
    var searchFailed = false;
    try {
      results = await _PlaceSearchService.instance.search(query);
    } catch (_) {
      searchFailed = true;
    }
    if (results.isEmpty) {
      try {
        results = await _searchWithDeviceGeocoder(query, version);
      } catch (_) {
        searchFailed = true;
      }
    }
    if (!mounted || version != _queryVersion) return;
    setState(() {
      _suggestions = results;
      _searching = false;
      _message = results.isNotEmpty
          ? null
          : searchFailed
          ? 'Place search is unavailable right now. Check your internet and try again.'
          : 'No matches found. Try a nearby landmark or add the area name.';
    });
  }

  Future<List<LocationChoice>> _searchWithDeviceGeocoder(
    String query,
    int version,
  ) async {
    final locations = await _geocoding.locationFromAddress(query);
    final results = <LocationChoice>[];
    final seen = <String>{};
    for (final location in locations.take(5)) {
      if (!mounted || version != _queryVersion) return const [];
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
    return results;
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

  Future<void> _pickOnMap() async {
    final choice = await showDialog<LocationChoice>(
      context: context,
      builder: (_) => const _LocationMapDialog(),
    );
    if (choice != null && mounted) _choose(choice);
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
          if (value.trim().length >= 2) _search(value.trim(), ++_queryVersion);
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
      if (_suggestions.isNotEmpty)
        const Padding(
          padding: EdgeInsets.only(left: 8, top: 2),
          child: Text(
            'Place data © OpenStreetMap contributors · Photon',
            style: TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ),
      if (_message != null)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 8),
          child: Text(_message!, style: Theme.of(context).textTheme.bodySmall),
        ),
      TextButton.icon(
        onPressed: _pickOnMap,
        icon: const Icon(Icons.map_outlined),
        label: const Text('Can’t find it? Pick the exact point on a map'),
      ),
    ],
  );
}

class _LocationMapDialog extends StatefulWidget {
  const _LocationMapDialog();

  @override
  State<_LocationMapDialog> createState() => _LocationMapDialogState();
}

class _LocationMapDialogState extends State<_LocationMapDialog> {
  static const _delhiCenter = LatLng(28.6139, 77.2090);
  LatLng? _selected;
  bool _resolving = false;

  Future<void> _useSelection() async {
    final point = _selected;
    if (point == null) return;
    setState(() => _resolving = true);
    var name =
        'Selected location (${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)})';
    try {
      final places = await Geocoding().placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (places.isNotEmpty) {
        final place = places.first;
        final parts = <String?>[
          place.name,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ]
            .whereType<String>()
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toSet()
            .toList();
        if (parts.isNotEmpty) name = parts.join(', ');
      }
    } catch (_) {
      // Exact coordinates still let the user use places the geocoder misses.
    }
    if (!mounted) return;
    Navigator.of(context).pop(
      LocationChoice(
        name: name,
        latitude: point.latitude,
        longitude: point.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: SizedBox(
      width: 520,
      height: 560,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pick a location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Move the map and tap the exact pickup or destination point.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _delhiCenter,
                initialZoom: 10,
                onTap: (_, point) => setState(() => _selected = point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.fairride',
                ),
                if (_selected != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selected!,
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _selected == null || _resolving ? null : _useSelection,
                  icon: _resolving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Use this point'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _LocationFailure implements Exception {
  const _LocationFailure(this.message);
  final String message;
}
