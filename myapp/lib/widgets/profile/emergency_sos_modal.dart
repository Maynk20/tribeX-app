import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../services/location_service.dart';

class EmergencySosModal extends StatefulWidget {
  const EmergencySosModal({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const EmergencySosModal());
  }

  @override
  State<EmergencySosModal> createState() => _EmergencySosModalState();
}

class _EmergencySosModalState extends State<EmergencySosModal> {
  bool _isFetchingLocation = false;

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          AppToast.show(
            context,
            'Unable to open phone dialer for $number. Please dial manually.',
            isError: true,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          'Unable to dial $number. Please dial manually.',
          isError: true,
        );
      }
    }
  }

  Future<void> _shareLocation() async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);

    final result = await LocationService.getCurrentPosition();

    if (!mounted) return;
    setState(() => _isFetchingLocation = false);

    if (!result.isSuccess) {
      if (!mounted) return;
      AppToast.show(
        context,
        result.error ?? 'Could not get your location.',
        isError: true,
      );
      return;
    }

    final lat = result.latitude!;
    final lon = result.longitude!;
    final mapsUrl = 'https://maps.google.com/?q=$lat,$lon';
    final text = '🚨 tribeX SOS — I need help. My live location: $mapsUrl';
    final waUri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');

    if (await canLaunchUrl(waUri)) {
      await launchUrl(waUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        AppToast.show(context, 'Could not open WhatsApp. Copy the link and share manually.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.destructive.withValues(alpha: 0.4)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.destructiveMuted,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.destructive,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Emergency SOS',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'India helplines · live location',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.mutedForegroundDark
                                : AppColors.mutedForegroundLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Helplines list
            _HelplineTile(
              label: 'Police',
              hint: 'All-India emergency',
              numbers: const ['112', '100'],
              onCall: _makeCall,
            ),
            const SizedBox(height: 8),
            _HelplineTile(
              label: 'Ambulance',
              hint: 'Medical emergency',
              numbers: const ['108'],
              onCall: _makeCall,
            ),
            const SizedBox(height: 8),
            _HelplineTile(
              label: 'Women Helpline',
              hint: '24×7 safety & support',
              numbers: const ['1091'],
              onCall: _makeCall,
            ),
            const SizedBox(height: 18),

            // Share live location button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isFetchingLocation ? null : _shareLocation,
                icon: _isFetchingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share, size: 16),
                label: Text(_isFetchingLocation ? 'Getting location…' : 'Share My Live Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 12,
                    color: AppColors.mutedForegroundLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Opens WhatsApp with your live GPS coordinates.',
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
          ],
        ),
      ),
    );
  }
}

class _HelplineTile extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> numbers;
  final ValueChanged<String> onCall;

  const _HelplineTile({
    required this.label,
    required this.hint,
    required this.numbers,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.backgroundDark : AppColors.mutedLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                hint,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
            ],
          ),
          Row(
            children: numbers.map((n) {
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ElevatedButton.icon(
                  onPressed: () => onCall(n),
                  icon: const Icon(Icons.phone, size: 12),
                  label: Text(
                    n,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
