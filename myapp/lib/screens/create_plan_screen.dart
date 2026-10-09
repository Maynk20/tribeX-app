import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/categories.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_toast.dart';
import '../models/activity.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../state/activities_state.dart';
import '../state/auth_state.dart';
import '../widgets/common/place_search_dialog.dart';
import 'auth_screen.dart';

class CreatePlanScreen extends StatefulWidget {
  final VoidCallback? onPlanCreated;

  const CreatePlanScreen({super.key, this.onPlanCreated});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _meetingLinkCtrl = TextEditingController();
  final _slotsCtrl = TextEditingController(text: "8");
  final _costCtrl = TextEditingController(text: "0");
  final _tagsCtrl = TextEditingController();

  String _selectedGroup = "Sports & Outdoor";
  String _selectedCategory = "Cricket";
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);

  bool _isOnline = false;
  bool _womenOnly = false;
  bool _verifiedOnly = false;
  final List<String> _selectedAmenities = [];
  String? _imageUrl;
  Uint8List? _previewBytes;
  bool _isUploadingCover = false;
  PlaceItem? _pinnedPlace;
  bool _isPublishing = false;
  bool _isLocating = false;

  void _openCoverPicker() {
    StorageService.showCoverPickerModal(
      context,
      category: _selectedCategory,
      onLocalPreviewReady: (bytes, uploadFuture) {
        setState(() {
          _previewBytes = bytes;
          _isUploadingCover = true;
        });
        uploadFuture
            .then((url) {
              if (!mounted) return;
              setState(() {
                _imageUrl = url;
                _isUploadingCover = false;
              });
            })
            .catchError((_) {
              if (!mounted) return;
              setState(() => _isUploadingCover = false);
              AppToast.show(context, 'Cover upload failed', isError: true);
            });
      },
      onImageSelected: (url) {
        if (url.startsWith('data:image')) {
          try {
            final decoded = base64Decode(url.split(',').last);
            setState(() {
              _previewBytes = decoded;
              _imageUrl = url;
              _isUploadingCover = false;
            });
            return;
          } catch (_) {}
        }
        setState(() {
          _previewBytes = null;
          _imageUrl = url;
          _isUploadingCover = false;
        });
      },
    );
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    final res = await LocationService.getCurrentPosition();
    if (!mounted) return;

    if (!res.isSuccess) {
      setState(() => _isLocating = false);
      AppToast.show(
        context,
        res.error ?? 'Could not determine GPS location.',
        isError: true,
      );
      return;
    }

    final lat = res.latitude!;
    final lon = res.longitude!;

    final placeInfo = await LocationService.reverseGeocode(lat, lon);
    if (!mounted) return;
    setState(() => _isLocating = false);

    final title = placeInfo?['title'] ?? 'Current Location';
    final subtitle =
        placeInfo?['subtitle'] ??
        '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';

    setState(() {
      _pinnedPlace = PlaceItem(
        title: title,
        subtitle: subtitle,
        lat: lat,
        lon: lon,
      );
      _locCtrl.text = subtitle.isNotEmpty && title != 'Current Location'
          ? '$title, $subtitle'
          : title;
    });

    AppToast.show(context, '📍 Location pinned to your GPS position');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    _meetingLinkCtrl.dispose();
    _slotsCtrl.dispose();
    _costCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  void _toggleAmenity(String key) {
    setState(() {
      if (_selectedAmenities.contains(key)) {
        _selectedAmenities.remove(key);
      } else {
        _selectedAmenities.add(key);
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _publish() async {
    if (_isPublishing) return;

    final authState = context.read<AuthState>();
    final user = authState.currentUser;

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }

    if (_isUploadingCover) {
      AppToast.show(
        context,
        'Please wait for cover photo upload to finish',
        isError: true,
      );
      return;
    }

    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final loc = _isOnline
        ? (_locCtrl.text.trim().isNotEmpty
              ? _locCtrl.text.trim()
              : "Online Event")
        : _locCtrl.text.trim();
    final slots = int.tryParse(_slotsCtrl.text.trim()) ?? 8;
    final cost = double.tryParse(_costCtrl.text.trim()) ?? 0.0;
    final meetingLink = _isOnline ? _meetingLinkCtrl.text.trim() : null;

    if (title.length < 4) {
      AppToast.show(
        context,
        'Title must be at least 4 characters',
        isError: true,
      );
      return;
    }
    if (desc.length < 10) {
      AppToast.show(
        context,
        'Please add a bit more description (10+ chars)',
        isError: true,
      );
      return;
    }
    if (!_isOnline && loc.isEmpty) {
      AppToast.show(
        context,
        'Please specify a location or venue',
        isError: true,
      );
      return;
    }
    if (_isOnline) {
      if (meetingLink == null || meetingLink.isEmpty) {
        AppToast.show(
          context,
          'Please add a valid meeting URL (Google Meet, Discord, Zoom…)',
          isError: true,
        );
        return;
      }
      final uri = Uri.tryParse(meetingLink);
      final isWebUrl =
          uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority;
      if (!isWebUrl) {
        AppToast.show(
          context,
          'Meeting link must be a valid URL starting with https:// or http://',
          isError: true,
        );
        return;
      }
    }

    setState(() => _isPublishing = true);

    // Auto-resolve coordinates if the host typed a venue location but didn't manually pin
    if (!_isOnline && _pinnedPlace == null && loc.isNotEmpty) {
      final geocoded = await LocationService.geocodeAddress(loc);
      if (!mounted) return;
      if (geocoded != null) {
        _pinnedPlace = PlaceItem(
          title: geocoded['title'] as String? ?? loc,
          subtitle: geocoded['subtitle'] as String? ?? '',
          lat: (geocoded['lat'] as num).toDouble(),
          lon: (geocoded['lon'] as num).toDouble(),
        );
      }
    }

    // Venue coordinates come only from the pinned/geocoded venue. Never use
    // the host's own profile location as the venue (wrong check-in point).
    final double? actLat = _pinnedPlace?.lat;
    final double? actLon = _pinnedPlace?.lon;

    if (!_isOnline &&
        (actLat == null ||
            actLon == null ||
            (actLat == 0.0 && actLon == 0.0))) {
      setState(() => _isPublishing = false);
      AppToast.show(
        context,
        'Please pin the venue or tap the GPS icon so attendees can find and check in to your event.',
        isError: true,
      );
      return;
    }

    final combinedDateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final newAct = Activity(
      id: const Uuid().v4(),
      hostId: user.id,
      title: title,
      description: desc,
      category: _selectedCategory,
      dateTime: combinedDateTime,
      location: loc,
      totalSlots: slots,
      slotsLeft: slots,
      costPerHead: cost,
      imageUrl: _imageUrl ?? "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800&auto=format&fit=crop&q=80",
      latitude: _isOnline ? null : actLat,
      longitude: _isOnline ? null : actLon,
      womenOnly: _womenOnly,
      verifiedOnly: _verifiedOnly,
      isOnline: _isOnline,
      meetingLink: meetingLink,
      amenities: _isOnline ? [] : _selectedAmenities,
      topicTags: tags,
      host: user,
    );

    if (!mounted) return;
    final success = await context.read<ActivitiesState>().createActivity(
      newAct,
    );

    if (!mounted) return;
    setState(() => _isPublishing = false);

    if (success) {
      AppToast.show(context, 'Plan published — your squad will find you!');
      widget.onPlanCreated?.call();
    } else {
      AppToast.show(
        context,
        "Couldn't publish plan. Please try again.",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final authState = context.watch<AuthState>();

    if (!authState.isAuthenticated) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign in to host a plan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a free account so your squad can find and join your plans.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header matching TanStack: p.uppercase tracking-[0.18em] + h1 text-3xl font-bold
              Text(
                'NEW PLAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.8,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Post a plan',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Fill in the essentials. Your squad will find you.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 18),

              // Cover photo picker: h-36 w-full rounded-3xl border border-dashed border-border
              GestureDetector(
                onTap: _openCoverPicker,
                child: Container(
                  height: 148,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: (_imageUrl == null && _previewBytes == null)
                        ? cardBg.withValues(alpha: 0.5)
                        : null,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: (_imageUrl != null || _previewBytes != null)
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : border.withValues(alpha: 0.8),
                      width: (_imageUrl != null || _previewBytes != null)
                          ? 1.5
                          : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (_imageUrl == null && _previewBytes == null)
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryMuted,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.imagePlus,
                                size: 22,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add a cover photo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.foregroundDark
                                    : AppColors.foregroundLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Camera · Gallery · Curated Templates',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForegroundLight,
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_previewBytes != null)
                              Image.memory(
                                _previewBytes!,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              )
                            else if (_imageUrl != null)
                              Image.network(
                                _imageUrl!,
                                fit: BoxFit.cover,
                                cacheWidth: 800,
                                cacheHeight: 400,
                                gaplessPlayback: true,
                                errorBuilder: (_, _, _) => Container(
                                  color: AppColors.primaryMuted,
                                  child: const Center(
                                    child: Icon(
                                      LucideIcons.image,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            if (_isUploadingCover)
                              Positioned(
                                bottom: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Uploading cover…',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Top overlay with Change & Remove buttons
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: _openCoverPicker,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.7,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.pencil,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Change',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _imageUrl = null;
                                        _previewBytes = null;
                                        _isUploadingCover = false;
                                      });
                                    },
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.7,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        LucideIcons.x,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Title: rounded-2xl border bg-card px-4 py-3
              _FormFieldWrapper(
                label: 'TITLE',
                hint: '${_titleCtrl.text.length}/80',
                child: TextField(
                  controller: _titleCtrl,
                  maxLength: 80,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Box cricket at Turf Arena',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              _FormFieldWrapper(
                label: 'DESCRIPTION',
                hint: '${_descCtrl.text.length}/500',
                child: TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  maxLength: 500,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText:
                        'Chill 6-a-side, all levels welcome. Bring water.',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),

              // Category Picker
              Text(
                'CATEGORY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 8),

              // Groups horizontal
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: AppCategories.groups.map((g) {
                    final isSelected = _selectedGroup == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedGroup = g;
                            final firstInGroup = AppCategories.all.firstWhere(
                              (c) => c.group == g,
                            );
                            _selectedCategory = firstInGroup.key;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : cardBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : border.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              g.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                          ? AppColors.mutedForegroundDark
                                          : AppColors.mutedForegroundLight),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // Categories in selected group
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: AppCategories.all
                      .where((c) => c.group == _selectedGroup)
                      .map((c) {
                        final isSelected = _selectedCategory == c.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = c.key;
                                if (c.defaultMode == 'online') {
                                  _isOnline = true;
                                }
                                if (c.defaultMode == 'in_person') {
                                  _isOnline = false;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : cardBg,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : border.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    c.emoji,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    c.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                                ? AppColors.foregroundDark
                                                : AppColors.foregroundLight),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: _FormFieldWrapper(
                      label: 'DATE',
                      child: InkWell(
                        onTap: _pickDate,
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.calendar,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMM d, yyyy').format(_date),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FormFieldWrapper(
                      label: 'TIME',
                      child: InkWell(
                        onTap: _pickTime,
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.clock,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _time.format(context),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Where does it happen?
              Text(
                'WHERE DOES IT HAPPEN?',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ModeOptionCard(
                      label: 'In-Person Venue',
                      emoji: '📍',
                      isSelected: !_isOnline,
                      onTap: () => setState(() => _isOnline = false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ModeOptionCard(
                      label: 'Online / Virtual',
                      emoji: '💻',
                      isSelected: _isOnline,
                      onTap: () => setState(() => _isOnline = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Mode Specific Inputs
              if (_isOnline) ...[
                _FormFieldWrapper(
                  label: 'MEETING LINK',
                  hint: 'Google Meet, Discord, Zoom…',
                  child: TextField(
                    controller: _meetingLinkCtrl,
                    decoration: const InputDecoration(
                      hintText: 'https://meet.google.com/xyz-abcd-efg',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 10),
                _FormFieldWrapper(
                  label: 'PLATFORM NAME (OPTIONAL)',
                  hint: 'e.g. Google Meet, Discord, Zoom',
                  child: TextField(
                    controller: _locCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Google Meet or Discord Server',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.lock,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Link stays private — only accepted squad members can see it.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                _FormFieldWrapper(
                  label: 'VENUE / LOCATION',
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _locCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Turf Arena, Indiranagar',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (_isLocating)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.my_location, size: 18),
                          tooltip: 'Use current GPS location',
                          onPressed: _useCurrentLocation,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Pin venue chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _pinnedPlace != null
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : border.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'PIN THE VENUE (FOR GPS CHECK-IN)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: isDark
                                    ? AppColors.mutedForegroundDark
                                    : AppColors.mutedForegroundLight,
                              ),
                            ),
                          ),
                          if (_pinnedPlace != null)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _pinnedPlace = null;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: isDark
                                      ? AppColors.mutedForegroundDark
                                      : AppColors.mutedForegroundLight,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _pinnedPlace != null
                                  ? '📍 ${_pinnedPlace!.title} · ${_pinnedPlace!.lat.toStringAsFixed(4)}, ${_pinnedPlace!.lon.toStringAsFixed(4)}'
                                  : 'Needed so attendees can check in on arrival.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: _pinnedPlace != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: _pinnedPlace != null
                                    ? (isDark ? Colors.white : Colors.black)
                                    : AppColors.mutedForegroundLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Wrap(
                            spacing: 6,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _isLocating
                                    ? null
                                    : _useCurrentLocation,
                                icon: _isLocating
                                    ? const SizedBox(
                                        width: 10,
                                        height: 10,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                        ),
                                      )
                                    : const Icon(Icons.my_location, size: 12),
                                label: const Text(
                                  'GPS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  PlaceSearchDialog.show(
                                    context,
                                    initialValue: _locCtrl.text,
                                    onSelect: (p) {
                                      setState(() {
                                        _pinnedPlace = p;
                                        if (_locCtrl.text.isEmpty) {
                                          _locCtrl.text = p.title;
                                        }
                                      });
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  _pinnedPlace != null
                                      ? 'Change'
                                      : 'Search Place',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Venue amenities
                Text(
                  'VENUE AMENITIES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: AppCategories.amenities.map((a) {
                    final isSelected = _selectedAmenities.contains(a.key);
                    return GestureDetector(
                      onTap: () => _toggleAmenity(a.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : cardBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : border.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              a.icon,
                              size: 13,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.mutedForegroundLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              a.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                          ? AppColors.foregroundDark
                                          : AppColors.foregroundLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),

              // Topic / skill tags
              _FormFieldWrapper(
                label: 'TOPIC / SKILL TAGS',
                hint: 'Comma separated',
                child: TextField(
                  controller: _tagsCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Beginners welcome, casual, turf',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),

              // Slots & Cost
              Row(
                children: [
                  Expanded(
                    child: _FormFieldWrapper(
                      label: 'TOTAL SLOTS',
                      child: TextField(
                        controller: _slotsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FormFieldWrapper(
                      label: 'COST / HEAD',
                      child: Row(
                        children: [
                          const Text(
                            '₹ ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.mutedForegroundLight,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _costCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Safety Controls Card: rounded-3xl border border-border/60 bg-card p-5
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          LucideIcons.shield,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'SAFETY CONTROLS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Restricted plans are hidden from non-matching users, and venue is masked until you approve joiners.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.mutedForegroundDark
                            : AppColors.mutedForegroundLight,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Women-only switch
                    _SafetySwitchTile(
                      iconText: '♀︎',
                      label: 'Women-only plan',
                      hint: 'Visible & joinable only by female users.',
                      value: _womenOnly,
                      onChanged: (val) => setState(() => _womenOnly = val),
                    ),
                    const SizedBox(height: 8),

                    // Verified only switch
                    _SafetySwitchTile(
                      icon: LucideIcons.badgeCheck,
                      label: 'Verified users only',
                      hint: 'Requires a verified profile.',
                      value: _verifiedOnly,
                      onChanged: (val) => setState(() => _verifiedOnly = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit button: rounded-2xl bg-primary py-4 text-sm font-semibold
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isPublishing ? null : _publish,
                  icon: _isPublishing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.check, size: 18),
                  label: Text(_isPublishing ? 'Publishing…' : 'Publish plan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormFieldWrapper extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;

  const _FormFieldWrapper({
    required this.label,
    this.hint,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              if (hint != null)
                Text(
                  hint!,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _ModeOptionCard extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeOptionCard({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : border.withValues(alpha: 0.6),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.foregroundDark
                          : AppColors.foregroundLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetySwitchTile extends StatelessWidget {
  final String? iconText;
  final IconData? icon;
  final String label;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SafetySwitchTile({
    this.iconText,
    this.icon,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.mutedLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: iconText != null
                ? Text(
                    iconText!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
