import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/location_feedback.dart';
import '../../services/location_service.dart';

class PlaceItem {
  final String title;
  final String subtitle;
  final double lat;
  final double lon;

  const PlaceItem({
    required this.title,
    required this.subtitle,
    required this.lat,
    required this.lon,
  });
}

class PlaceSearchDialog extends StatefulWidget {
  final String initialValue;
  final ValueChanged<PlaceItem> onSelect;

  const PlaceSearchDialog({
    super.key,
    required this.initialValue,
    required this.onSelect,
  });

  static void show(
    BuildContext context, {
    required String initialValue,
    required ValueChanged<PlaceItem> onSelect,
  }) {
    showDialog(
      context: context,
      builder: (ctx) =>
          PlaceSearchDialog(initialValue: initialValue, onSelect: onSelect),
    );
  }

  @override
  State<PlaceSearchDialog> createState() => _PlaceSearchDialogState();
}

class _PlaceSearchDialogState extends State<PlaceSearchDialog> {
  static final Map<String, List<PlaceItem>> _searchCache = {};
  late TextEditingController _searchCtrl;
  String _query = "";
  List<PlaceItem> _searchResults = [];
  bool _isLoading = false;
  bool _isLocatingCurrent = false;
  String? _error;
  Timer? _debounceTimer;

  static const List<PlaceItem> popularPlaces = [
    PlaceItem(
      title: "Indiranagar",
      subtitle: "Bengaluru, Karnataka, 560038",
      lat: 12.9784,
      lon: 77.6408,
    ),
    PlaceItem(
      title: "Koramangala",
      subtitle: "Bengaluru, Karnataka, 560034",
      lat: 12.9352,
      lon: 77.6245,
    ),
    PlaceItem(
      title: "HSR Layout",
      subtitle: "Bengaluru, Karnataka, 560102",
      lat: 12.9121,
      lon: 77.6446,
    ),
    PlaceItem(
      title: "Whitefield",
      subtitle: "Bengaluru, Karnataka, 560066",
      lat: 12.9698,
      lon: 77.7500,
    ),
    PlaceItem(
      title: "Madhapar",
      subtitle: "Bhuj, Kutch, Gujarat, 370020",
      lat: 23.2304,
      lon: 69.6588,
    ),
    PlaceItem(
      title: "Bandra West",
      subtitle: "Mumbai, Maharashtra, 400050",
      lat: 19.0596,
      lon: 72.8295,
    ),
    PlaceItem(
      title: "Andheri West",
      subtitle: "Mumbai, Maharashtra, 400053",
      lat: 19.1363,
      lon: 72.8277,
    ),
    PlaceItem(
      title: "Connaught Place",
      subtitle: "New Delhi, Delhi, 110001",
      lat: 28.6304,
      lon: 77.2177,
    ),
    PlaceItem(
      title: "Hauz Khas",
      subtitle: "New Delhi, Delhi, 110016",
      lat: 28.5494,
      lon: 77.2001,
    ),
    PlaceItem(
      title: "Jubilee Hills",
      subtitle: "Hyderabad, Telangana, 500033",
      lat: 17.4319,
      lon: 78.4073,
    ),
    PlaceItem(
      title: "SG Highway",
      subtitle: "Ahmedabad, Gujarat, 380054",
      lat: 23.0396,
      lon: 72.5065,
    ),
    PlaceItem(
      title: "Koregaon Park",
      subtitle: "Pune, Maharashtra, 411001",
      lat: 18.5362,
      lon: 73.8940,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String val) {
    setState(() {
      _query = val;
    });

    _debounceTimer?.cancel();
    final trimmed = val.trim();
    if (trimmed.length < 2) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _error = null;
      });
      return;
    }

    final cacheKey = trimmed.toLowerCase();
    if (_searchCache.containsKey(cacheKey)) {
      setState(() {
        _searchResults = _searchCache[cacheKey]!;
        _isLoading = false;
        _error = null;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performLiveSearch(trimmed);
    });
  }

  Future<void> _performLiveSearch(String q) async {
    final cacheKey = q.toLowerCase();
    if (_searchCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _searchResults = _searchCache[cacheKey]!;
          _isLoading = false;
          _error = null;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pinMatch = RegExp(r'\b\d{6}\b').firstMatch(q);
      final List<PlaceItem> items = [];

      // 1. If query contains a 6-digit PIN code, query Nominatim postal code endpoint first
      if (pinMatch != null) {
        final pinResults = await _searchNominatimPincode(pinMatch.group(0)!);
        items.addAll(pinResults);
      }

      // 2. Query Photon with strict India bounding box
      final photonResults = await _searchPhoton(q);
      items.addAll(photonResults);

      // 3. If results are still sparse (< 3) or empty, fall back to Nominatim freeform search for India
      if (items.length < 3) {
        final nominatimResults = await _searchNominatimFreeform(q);
        items.addAll(nominatimResults);
      }

      // 4. Remove duplicates by title & lat/lon proximity (within India only)
      final Map<String, PlaceItem> uniqueMap = {};
      for (final item in items) {
        if (!LocationService.isInIndia(item.lat, item.lon)) {
          continue;
        }
        final key =
            '${item.title.trim().toLowerCase()}_${item.lat.toStringAsFixed(3)}_${item.lon.toStringAsFixed(3)}';
        if (!uniqueMap.containsKey(key)) {
          uniqueMap[key] = item;
        }
      }

      final results = uniqueMap.values.toList();
      if (_searchCache.length > 50) {
        _searchCache.remove(_searchCache.keys.first);
      }
      _searchCache[cacheKey] = results;

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
          _error = results.isEmpty ? null : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Couldn't reach place search service. Tap to retry.";
        });
      }
    }
  }

  Future<void> _useCurrentGpsLocation() async {
    if (_isLocatingCurrent) return;
    setState(() {
      _isLocatingCurrent = true;
      _error = null;
    });

    final res = await LocationService.getCurrentPosition();
    if (!mounted) return;

    if (!res.isSuccess) {
      final errorMsg = res.error ?? "Couldn't detect your GPS location.";
      setState(() {
        _isLocatingCurrent = false;
        _error = errorMsg;
      });
      showLocationError(context, errorMsg);
      return;
    }

    final lat = res.latitude!;
    final lon = res.longitude!;

    final placeInfo = await LocationService.reverseGeocode(lat, lon);
    if (!mounted) return;
    setState(() => _isLocatingCurrent = false);

    final title = placeInfo?['title'] ?? 'Current GPS Location';
    final subtitle =
        placeInfo?['subtitle'] ??
        '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';

    widget.onSelect(
      PlaceItem(title: title, subtitle: subtitle, lat: lat, lon: lon),
    );
    Navigator.of(context).pop();
  }

  Future<List<PlaceItem>> _searchPhoton(String q) async {
    try {
      final uri = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(q)}&lang=en&limit=15&lat=22.35&lon=78.66&bbox=68.0,6.5,97.5,37.5',
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = (data['features'] as List<dynamic>?) ?? [];
        final List<PlaceItem> list = [];

        for (final f in features) {
          final props = f['properties'] as Map<String, dynamic>? ?? {};
          final coords = (f['geometry']['coordinates'] as List<dynamic>);
          final lon = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();

          final countryCode = props['countrycode']?.toString();
          final country = props['country']?.toString();

          if (!LocationService.isInIndia(
            lat,
            lon,
            countryCode: countryCode,
            country: country,
          )) {
            continue;
          }

          final locality =
              props['suburb'] ??
              props['locality'] ??
              props['district'] ??
              props['village'] ??
              props['hamlet'] ??
              props['town'] ??
              '';
          final city =
              props['city'] ??
              props['town'] ??
              props['village'] ??
              props['county'] ??
              props['district'] ??
              '';
          final state = props['state']?.toString() ?? '';
          final postcode = props['postcode']?.toString() ?? '';
          final name = props['name']?.toString() ?? props['street']?.toString();

          final title = (name != null && name.trim().isNotEmpty)
              ? name.trim()
              : (locality.toString().isNotEmpty
                    ? locality.toString()
                    : (city.toString().isNotEmpty ? city.toString() : q));

          final subtitleParts = <String>[];
          if (locality.toString().isNotEmpty && locality.toString() != title) {
            subtitleParts.add(locality.toString());
          }
          if (city.toString().isNotEmpty &&
              city.toString() != locality.toString() &&
              city.toString() != title) {
            subtitleParts.add(city.toString());
          }
          if (state.isNotEmpty && state != city.toString()) {
            subtitleParts.add(state);
          }
          if (postcode.isNotEmpty) {
            subtitleParts.add(postcode);
          }

          final subtitle = subtitleParts.isNotEmpty
              ? subtitleParts.join(', ')
              : (state.isNotEmpty ? state : 'India');

          list.add(
            PlaceItem(title: title, subtitle: subtitle, lat: lat, lon: lon),
          );
        }

        return list;
      }
    } catch (_) {}
    return [];
  }

  Future<List<PlaceItem>> _searchNominatimPincode(String pin) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&countrycodes=in&limit=10&accept-language=en&postalcode=${Uri.encodeComponent(pin)}',
      );
      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'tribeX-app/1.0.0 (contact@tribex.app)',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final List<PlaceItem> list = [];

        for (final item in data) {
          final map = item as Map<String, dynamic>;
          final lat = double.tryParse(map['lat']?.toString() ?? '0') ?? 0.0;
          final lon = double.tryParse(map['lon']?.toString() ?? '0') ?? 0.0;

          if (!LocationService.isInIndia(lat, lon)) continue;

          final address = map['address'] as Map<String, dynamic>? ?? {};
          final locality =
              address['suburb'] ??
              address['neighbourhood'] ??
              address['village'] ??
              address['hamlet'] ??
              address['town'] ??
              '';
          final city =
              address['city'] ?? address['town'] ?? address['village'] ?? '';
          final district = address['state_district'] ?? address['county'] ?? '';
          final state = address['state']?.toString() ?? '';
          final displayName = map['display_name']?.toString() ?? '';
          final firstPart = displayName.split(',').first.trim();

          final title = locality.toString().isNotEmpty
              ? locality.toString()
              : (city.toString().isNotEmpty
                    ? city.toString()
                    : (firstPart.isNotEmpty ? firstPart : 'PIN $pin'));

          final subtitleParts = <String>[];
          if (district.toString().isNotEmpty && district.toString() != title) {
            subtitleParts.add(district.toString());
          }
          if (city.toString().isNotEmpty && city.toString() != title) {
            subtitleParts.add(city.toString());
          }
          if (state.isNotEmpty) subtitleParts.add(state);
          subtitleParts.add(pin);

          list.add(
            PlaceItem(
              title: title,
              subtitle: subtitleParts.join(', '),
              lat: lat,
              lon: lon,
            ),
          );
        }
        return list;
      }
    } catch (_) {}
    return [];
  }

  Future<List<PlaceItem>> _searchNominatimFreeform(String q) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&countrycodes=in&limit=10&accept-language=en&q=${Uri.encodeComponent(q)}',
      );
      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'tribeX-app/1.0.0 (contact@tribex.app)',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final List<PlaceItem> list = [];

        for (final item in data) {
          final map = item as Map<String, dynamic>;
          final lat = double.tryParse(map['lat']?.toString() ?? '0') ?? 0.0;
          final lon = double.tryParse(map['lon']?.toString() ?? '0') ?? 0.0;

          if (!LocationService.isInIndia(lat, lon)) continue;

          final address = map['address'] as Map<String, dynamic>? ?? {};
          final locality =
              address['suburb'] ??
              address['neighbourhood'] ??
              address['village'] ??
              address['hamlet'] ??
              address['town'] ??
              '';
          final city =
              address['city'] ?? address['town'] ?? address['village'] ?? '';
          final district = address['state_district'] ?? address['county'] ?? '';
          final state = address['state']?.toString() ?? '';
          final postcode = address['postcode']?.toString() ?? '';
          final displayName = map['display_name']?.toString() ?? '';
          final firstPart = displayName.split(',').first.trim();

          final title = firstPart.isNotEmpty
              ? firstPart
              : (locality.toString().isNotEmpty
                    ? locality.toString()
                    : (city.toString().isNotEmpty ? city.toString() : q));

          final subtitleParts = <String>[];
          if (district.toString().isNotEmpty && district.toString() != title) {
            subtitleParts.add(district.toString());
          }
          if (city.toString().isNotEmpty &&
              city.toString() != district.toString() &&
              city.toString() != title) {
            subtitleParts.add(city.toString());
          }
          if (state.isNotEmpty && state != city.toString()) {
            subtitleParts.add(state);
          }
          if (postcode.isNotEmpty) subtitleParts.add(postcode);

          final subtitle = subtitleParts.isNotEmpty
              ? subtitleParts.join(', ')
              : displayName;

          list.add(
            PlaceItem(title: title, subtitle: subtitle, lat: lat, lon: lon),
          );
        }
        return list;
      }
    } catch (_) {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    final trimmed = _query.trim().toLowerCase();
    List<PlaceItem> displayList;

    if (trimmed.length < 2) {
      displayList = popularPlaces;
    } else {
      displayList = _searchResults;
    }

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.mutedLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border.withValues(alpha: 0.6)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: _onQueryChanged,
                  decoration: InputDecoration(
                    hintText:
                        'Search place, village, landmark or 6-digit pincode',
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onQueryChanged("");
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: border.withValues(alpha: 0.6)),

            // Quick Action: Use Current GPS Location
            InkWell(
              onTap: _isLocatingCurrent ? null : _useCurrentGpsLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  border: Border(
                    bottom: BorderSide(color: border.withValues(alpha: 0.4)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: _isLocatingCurrent
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(
                              LucideIcons.locateFixed,
                              size: 16,
                              color: AppColors.primary,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLocatingCurrent
                                ? 'Detecting current GPS location...'
                                : 'Use Current GPS Location',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.foregroundDark
                                  : AppColors.foregroundLight,
                            ),
                          ),
                          Text(
                            'Pins venue to your live coordinates for check-in',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),

            // Loading / Error / Header Info Bar
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Searching India…',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else if (_error != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_error == LocationService.msgDeniedForever) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => LocationService.openAppSettings(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Open Settings',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ] else if (_error ==
                        LocationService.msgServiceDisabled) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              LocationService.openLocationSettings(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Turn on GPS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _performLiveSearch(_query.trim()),
                          icon: const Icon(
                            LucideIcons.refreshCw,
                            size: 12,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Retry',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else if (trimmed.length < 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'POPULAR CITIES & HUB LOCATIONS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                  ),
                ),
              ),

            // Results List
            Flexible(
              child: displayList.isEmpty && !_isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.mapPinOff,
                            size: 32,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "No matching places found.",
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                          ),
                          if (trimmed.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final text = _query.trim();
                                // Try geocoding the custom address first
                                final geocoded =
                                    await LocationService.geocodeAddress(text);
                                if (!context.mounted) return;
                                if (geocoded != null) {
                                  widget.onSelect(
                                    PlaceItem(
                                      title:
                                          geocoded['title'] as String? ?? text,
                                      subtitle:
                                          geocoded['subtitle'] as String? ??
                                          'Custom Location',
                                      lat: (geocoded['lat'] as num).toDouble(),
                                      lon: (geocoded['lon'] as num).toDouble(),
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                  return;
                                }

                                // Never attach the device GPS or 0,0 to a
                                // typed name: that stores wrong coordinates.
                                // TanStack only returns places with real
                                // coordinates, so ask for a better search.
                                setState(() {
                                  _error =
                                      "Couldn't find '$text' on the map. Try a nearby landmark, area or 6-digit pincode.";
                                });
                                return;
                              },
                              icon: const Icon(LucideIcons.mapPin, size: 14),
                              label: Text("Use '$_query'"),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: displayList.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: border.withValues(alpha: 0.4),
                      ),
                      itemBuilder: (ctx, idx) {
                        final place = displayList[idx];
                        return ListTile(
                          leading: Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryMuted,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              LucideIcons.mapPin,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            place.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.foregroundDark
                                  : AppColors.foregroundLight,
                            ),
                          ),
                          subtitle: Text(
                            place.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                          ),
                          onTap: () {
                            widget.onSelect(place);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
