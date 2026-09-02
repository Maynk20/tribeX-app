import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../state/auth_state.dart';
import 'onboarding_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: "Bengaluru, Karnataka");
  final _bioCtrl = TextEditingController();
  String _gender = "Prefer not to say";
  bool _isSaving = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final auth = context.read<AuthState>();
    await auth.updateProfile(
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
      city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
      bio: _bioCtrl.text.trim().isNotEmpty ? _bioCtrl.text.trim() : null,
      gender: _gender,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
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
                decoration: const InputDecoration(
                  labelText: 'City / Location',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
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
