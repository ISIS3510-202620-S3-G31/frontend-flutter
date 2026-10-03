import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/screen_header.dart';
import '../view_model/auth_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.viewModel});

  final AuthViewModel? viewModel;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthViewModel _viewModel = widget.viewModel ?? AuthViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;

  @override
  void initState() {
    super.initState();
    _viewModel.loadProfile();
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: AppText.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: AppText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppText.body.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _viewModel.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final user = _viewModel.currentUser;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(
                  title: Text('Profile', style: AppText.h1),
                  subtitle: 'Your account & Firestore data',
                ),
                Expanded(
                  child: _viewModel.isLoading && user == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          children: [
                            // Profile Avatar Header
                            Center(
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.panel,
                                    width: 3,
                                  ),
                                ),
                                child: Center(
                                  child: user != null && user.name.isNotEmpty
                                      ? Text(
                                          user.name.characters.first
                                              .toUpperCase(),
                                          style: AppText.h1.copyWith(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                      : SvgPicture.asset(
                                          'assets/icons/ic_profile.svg',
                                          width: 44,
                                          height: 44,
                                          colorFilter: const ColorFilter.mode(
                                            Colors.white,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name
                                    : 'User Profile',
                                style: AppText.h2.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                user?.email ?? '',
                                style: AppText.bodyMuted,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // User Profile Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.panel,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.surfaceDim,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _ProfileInfoRow(
                                    icon: Icons.person_outline,
                                    label: 'Name',
                                    value: user?.name.isNotEmpty == true
                                        ? user!.name
                                        : 'Not specified',
                                  ),
                                  const Divider(
                                    height: 24,
                                    color: AppColors.surfaceDim,
                                  ),
                                  _ProfileInfoRow(
                                    icon: Icons.cake_outlined,
                                    label: 'Age',
                                    value: user?.age != null
                                        ? '${user!.age} years old'
                                        : 'Not specified',
                                  ),
                                  const Divider(
                                    height: 24,
                                    color: AppColors.surfaceDim,
                                  ),
                                  _ProfileInfoRow(
                                    icon: Icons.email_outlined,
                                    label: 'Email',
                                    value: user?.email.isNotEmpty == true
                                        ? user!.email
                                        : 'Not specified',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Sign Out Button
                            SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _viewModel.isLoading
                                    ? null
                                    : _confirmSignOut,
                                icon: const Icon(
                                  Icons.logout,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                                label: Text(
                                  'Sign Out',
                                  style: AppText.body.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.accent,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.text),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.bodyMuted.copyWith(fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppText.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
