import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

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
      title: "Jayanagar",
      subtitle: "Bengaluru, Karnataka, 560011",
      lat: 12.9308,
      lon: 77.5838,
    ),
    PlaceItem(
      title: "Bandra West",
      subtitle: "Mumbai, Maharashtra, 400050",
      lat: 19.0596,
      lon: 72.8295,
    ),
    PlaceItem(
      title: "Connaught Place",
      subtitle: "New Delhi, Delhi, 110001",
      lat: 28.6304,
      lon: 77.2177,
    ),
    PlaceItem(
      title: "Hitech City",
      subtitle: "Hyderabad, Telangana, 500081",
      lat: 17.4435,
      lon: 78.3772,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    final filtered = popularPlaces.where((p) {
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          p.subtitle.toLowerCase().contains(q);
    }).toList();

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Box
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.mutedLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: (val) => setState(() => _query = val),
                  decoration: InputDecoration(
                    hintText: 'Search place or pincode',
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = "");
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
            Divider(height: 1, color: border),

            // Results List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: border.withValues(alpha: 0.4)),
                itemBuilder: (ctx, idx) {
                  final place = filtered[idx];
                  return ListTile(
                    leading: const Icon(
                      Icons.location_on,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      place.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      place.subtitle,
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
