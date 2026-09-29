import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
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

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performLiveSearch(trimmed);
    });
  }

  Future<void> _performLiveSearch(String q) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isPincode = RegExp(r'^\d{6}$').hasMatch(q);
      final List<PlaceItem> items = [];

      if (isPincode) {
        final pinResults = await _searchNominatimPincode(q);
        items.addAll(pinResults);
      }

      final photonResults = await _searchPhoton(q);
      items.addAll(photonResults);

      // Remove duplicates by title & lat/lon proximity
      final Map<String, PlaceItem> uniqueMap = {};
      for (final item in items) {
        final key =
            '${item.title.toLowerCase()}_${item.lat.toStringAsFixed(3)}';
        if (!uniqueMap.containsKey(key)) {
          uniqueMap[key] = item;
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = uniqueMap.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Couldn't reach place search service.";
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
      setState(() {
        _isLocatingCurrent = false;
        _error = res.error ?? "Couldn't detect your GPS location.";
      });
      return;
    }

    final lat = res.latitude!;
    final lon = res.longitude!;

    final placeInfo = await LocationService.reverseGeocode(lat, lon);
    if (!mounted) return;
    setState(() => _isLocatingCurrent = false);

    final title = placeInfo?['title'] ?? 'Current GPS Location';
    final subtitle = placeInfo?['subtitle'] ??
        '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';

    widget.onSelect(
      PlaceItem(
        title: title,
        subtitle: subtitle,
        lat: lat,
        lon: lon,
      ),
    );
    Navigator.of(context).pop();
  }

  Future<List<PlaceItem>> _searchPhoton(String q) async {
    final uri = Uri.parse(
      'https://photon.komoot.io/api/?q=${Uri.encodeComponent(q)}&lang=en&limit=12&lat=22.35&lon=78.66&location_bias_scale=0.4',
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
            props['state'] ??
            '';
        final title = props['name'] ?? props['street'] ?? locality ?? city ?? q;

        final subtitleParts = [
          if (locality.toString().isNotEmpty && locality != title)
            locality.toString(),
          if (city.toString().isNotEmpty && city != locality) city.toString(),
          if (props['state'] != null && props['state'] != city)
            props['state'].toString(),
        ];
        final subtitle = subtitleParts.join(', ');

        list.add(
          PlaceItem(
            title: title.toString(),
            subtitle: subtitle.isNotEmpty
                ? subtitle
                : (props['country']?.toString() ?? 'India'),
            lat: lat,
            lon: lon,
          ),
        );
      }

      return list;
    }
    return [];
  }

  Future<List<PlaceItem>> _searchNominatimPincode(String pin) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&countrycodes=in&limit=8&accept-language=en&postalcode=${Uri.encodeComponent(pin)}',
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
        final address = map['address'] as Map<String, dynamic>? ?? {};
        final locality =
            address['suburb'] ??
            address['village'] ??
            address['hamlet'] ??
            address['town'] ??
            '';
        final city =
            address['city'] ??
            address['town'] ??
            address['village'] ??
            address['state'] ??
            '';

        final title = locality.toString().isNotEmpty
            ? '${locality.toString()} ($pin)'
            : (city.toString().isNotEmpty ? '${city.toString()} ($pin)' : pin);

        list.add(
          PlaceItem(
            title: title,
            subtitle: map['display_name']?.toString() ?? '',
            lat: double.tryParse(map['lat']?.toString() ?? '0') ?? 0.0,
            lon: double.tryParse(map['lon']?.toString() ?? '0') ?? 0.0,
          ),
        );
      }
      return list;
    }
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
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
                                      title: geocoded['title'] as String? ?? text,
                                      subtitle: geocoded['subtitle'] as String? ??
                                          'Custom Location',
                                      lat: (geocoded['lat'] as num).toDouble(),
                                      lon: (geocoded['lon'] as num).toDouble(),
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                  return;
                                }

                                // Fallback: try device GPS
                                final gps =
                                    await LocationService.getCurrentPosition();
                                if (!context.mounted) return;
                                if (gps.isSuccess) {
                                  widget.onSelect(
                                    PlaceItem(
                                      title: text,
                                      subtitle: 'GPS Location',
                                      lat: gps.latitude!,
                                      lon: gps.longitude!,
                                    ),
                                  );
                                } else {
                                  widget.onSelect(
                                    PlaceItem(
                                      title: text,
                                      subtitle: 'Custom Location',
                                      lat: 0.0,
                                      lon: 0.0,
                                    ),
                                  );
                                }
                                Navigator.of(context).pop();
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
