import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/app_toast.dart';
import '../state/auth_state.dart';
import '../widgets/common/place_search_dialog.dart';
import 'onboarding_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  String _gender = "Prefer not to say";
  bool _isSaving = false;

  /// Coordinates of the chosen city (TanStack `coords` state). Null until a
  /// place is picked or loaded from the existing profile.
  double? _lat;
  double? _lon;

  @override
  void initState() {
    super.initState();
    // Prefill from an existing profile, like TanStack does on load.
    final u = context.read<AuthState>().currentUser;
    if (u != null) {
      if ((u.city ?? '').trim().isNotEmpty) _cityCtrl.text = u.city!.trim();
      if (u.latitude != null && u.longitude != null) {
        _lat = u.latitude;
        _lon = u.longitude;
      }
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _pickCity() {
    PlaceSearchDialog.show(
      context,
      initialValue: _cityCtrl.text,
      onSelect: (p) {
        if (!mounted) return;
        setState(() {
          _cityCtrl.text = p.title;
          _lat = p.lat;
          _lon = p.lon;
        });
      },
    );
  }

  void _save() async {
    if (_isSaving) return;
    final city = _cityCtrl.text.trim();
    if (city.length < 2) {
      AppToast.show(context, 'Pick your city', isError: true);
      return;
    }
    setState(() => _isSaving = true);

    final auth = context.read<AuthState>();
    final success = await auth.updateProfile(
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
      city: city,
      bio: _bioCtrl.text.trim().isNotEmpty ? _bioCtrl.text.trim() : null,
      gender: _gender,
      latitude: _lat,
      longitude: _lon,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else {
      AppToast.show(
        context,
        auth.error ?? 'Could not update profile. Please try again.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complete Profile',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WELCOME TO TRIBEX',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hey ${user?.fullName ?? "there"}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add a few details so squad hosts and players know who they are teaming up with.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.transgender, size: 20),
                ),
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("Male")),
                  DropdownMenuItem(value: "Female", child: Text("Female")),
                  DropdownMenuItem(value: "Other", child: Text("Other")),
                  DropdownMenuItem(
                    value: "Prefer not to say",
                    child: Text("Prefer not to say"),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _gender = v);
                },
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _cityCtrl,
                readOnly: true,
                onTap: _pickCity,
                decoration: const InputDecoration(
                  labelText: 'City / Location *',
                  hintText: 'Search your city or pincode',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  suffixIcon: Icon(Icons.unfold_more, size: 18),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Short Bio',
                  hintText: 'Weekend cricketer, board game enthusiast…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

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
                      : const Text('Continue to Interests'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
