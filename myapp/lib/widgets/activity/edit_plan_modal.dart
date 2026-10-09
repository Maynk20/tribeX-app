import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../models/activity.dart';
import '../../services/storage_service.dart';
import '../../state/activities_state.dart';

class EditPlanModal extends StatefulWidget {
  final Activity activity;

  const EditPlanModal({super.key, required this.activity});

  static void show(BuildContext context, {required Activity activity}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditPlanModal(activity: activity),
    );
  }

  @override
  State<EditPlanModal> createState() => _EditPlanModalState();
}

class _EditPlanModalState extends State<EditPlanModal> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locCtrl;
  late TextEditingController _meetingLinkCtrl;
  late TextEditingController _slotsCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _tagsCtrl;
  late DateTime _dateTime;
  late bool _isOnline;
  String? _imageUrl;
  Uint8List? _previewBytes;
  bool _isUploadingCover = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.activity.title);
    _descCtrl = TextEditingController(text: widget.activity.description);
    _locCtrl = TextEditingController(text: widget.activity.location);
    _meetingLinkCtrl = TextEditingController(
      text: widget.activity.meetingLink ?? '',
    );
    _slotsCtrl = TextEditingController(
      text: widget.activity.totalSlots.toString(),
    );
    _costCtrl = TextEditingController(
      text: widget.activity.costPerHead.toStringAsFixed(0),
    );
    _tagsCtrl = TextEditingController(
      text: widget.activity.topicTags.join(", "),
    );
    _dateTime = widget.activity.dateTime;
    _isOnline = widget.activity.isOnline;
    _imageUrl = widget.activity.imageUrl;

    if (widget.activity.imageUrl?.startsWith('data:image') == true) {
      try {
        _previewBytes = base64Decode(widget.activity.imageUrl!.split(',').last);
      } catch (_) {}
    }

    if (_isOnline &&
        (widget.activity.meetingLink == null ||
            widget.activity.meetingLink!.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final link = await context.read<ActivitiesState>().fetchMeetingLink(
          widget.activity.id,
        );
        if (link != null && mounted) {
          setState(() {
            _meetingLinkCtrl.text = link;
          });
        }
      });
    }
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

  void _openCoverPicker() {
    StorageService.showCoverPickerModal(
      context,
      category: widget.activity.category,
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

  bool _isSaving = false;

  void _save() async {
    if (_isSaving) return;

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
    final loc = _locCtrl.text.trim();
    final slots =
        int.tryParse(_slotsCtrl.text.trim()) ?? widget.activity.totalSlots;
    final cost =
        double.tryParse(_costCtrl.text.trim()) ?? widget.activity.costPerHead;
    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final meetingLink = _isOnline ? _meetingLinkCtrl.text.trim() : null;

    if (title.isEmpty) {
      AppToast.show(context, 'Title cannot be empty', isError: true);
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
    } else if (loc.isEmpty) {
      AppToast.show(context, 'Location cannot be empty', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final finalLoc = _isOnline ? (loc.isNotEmpty ? loc : 'Online Event') : loc;

    final updated = widget.activity.copyWith(
      title: title,
      description: desc,
      location: finalLoc,
      dateTime: _dateTime,
      totalSlots: slots,
      costPerHead: cost,
      topicTags: tags,
      imageUrl: _imageUrl,
      isOnline: _isOnline,
      meetingLink: _isOnline ? meetingLink : null,
      clearMeetingLink: !_isOnline,
      clearCoordinates: _isOnline,
    );

    final success = await context.read<ActivitiesState>().updateActivity(
      updated,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      AppToast.show(context, 'Plan updated successfully');
    } else {
      AppToast.show(
        context,
        "Couldn't update plan. Please try again.",
        isError: true,
      );
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) {
      setState(() {
        _dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          _dateTime.hour,
          _dateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time != null) {
      setState(() {
        _dateTime = DateTime(
          _dateTime.year,
          _dateTime.month,
          _dateTime.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: border),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.borderDark : AppColors.borderLight)
                      .withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Edit Plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),

            // Cover photo picker
            GestureDetector(
              onTap: _openCoverPicker,
              child: Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: (_imageUrl == null && _previewBytes == null)
                      ? cardBg.withValues(alpha: 0.5)
                      : null,
                  borderRadius: BorderRadius.circular(20),
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
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryMuted,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.imagePlus,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add a cover photo',
                            style: TextStyle(
                              fontSize: 12,
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
                              fontSize: 10,
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
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Uploading…',
                                      style: TextStyle(
                                        fontSize: 10,
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
                            top: 8,
                            right: 8,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: _openCoverPicker,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.7,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.pencil,
                                          color: Colors.white,
                                          size: 11,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Change',
                                          style: TextStyle(
                                            fontSize: 10,
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
                                  onTap: () => setState(() {
                                    _imageUrl = null;
                                    _previewBytes = null;
                                    _isUploadingCover = false;
                                  }),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.7,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      LucideIcons.x,
                                      color: Colors.white,
                                      size: 14,
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
            const SizedBox(height: 14),

            // Title
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title, size: 20),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            // Date & Time
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, yyyy').format(_dateTime),
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
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('h:mm a').format(_dateTime),
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
            const SizedBox(height: 12),

            // Event Mode Selector: In-Person vs Virtual
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isOnline = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isOnline
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '📍 In-Person',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: !_isOnline
                                ? Colors.white
                                : (isDark
                                      ? AppColors.foregroundDark
                                      : AppColors.foregroundLight),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isOnline = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _isOnline
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '💻 Virtual',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isOnline
                                ? Colors.white
                                : (isDark
                                      ? AppColors.foregroundDark
                                      : AppColors.foregroundLight),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Location / Meeting Link Fields
            if (_isOnline) ...[
              TextField(
                controller: _meetingLinkCtrl,
                decoration: const InputDecoration(
                  labelText: 'Meeting Link',
                  hintText: 'https://meet.google.com/…',
                  prefixIcon: Icon(Icons.video_call_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Icon(LucideIcons.lock, size: 11, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Kept private — only accepted squad members can see this',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _locCtrl,
                decoration: const InputDecoration(
                  labelText: 'Platform Name (Optional)',
                  hintText: 'e.g. Google Meet or Discord',
                  prefixIcon: Icon(Icons.laptop_chromebook, size: 20),
                ),
              ),
            ] else ...[
              TextField(
                controller: _locCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location / Venue',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Slots & Cost
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _slotsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total slots',
                      prefixIcon: Icon(Icons.group_outlined, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _costCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cost / head (₹)',
                      prefixIcon: Icon(Icons.currency_rupee, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tags
            TextField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                prefixIcon: Icon(Icons.tag, size: 20),
              ),
            ),
            const SizedBox(height: 20),

            // Save
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Saving…'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 16),
                          SizedBox(width: 8),
                          Text('Save Changes'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension IterableFilterExtension<T> on Iterable<T> {
  Iterable<T> filter(bool Function(T element) test) => where(test);
}
