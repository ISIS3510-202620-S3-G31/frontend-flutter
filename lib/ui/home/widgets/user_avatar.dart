import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// Placeholder avatar showing the first letter of [name].
///
/// The real avatar (picture chosen by the user) is not built yet; when it
/// lands, only the body of this widget has to change.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.name, this.size = 40});

  /// Null while the profile is still loading.
  final String? name;
  final double size;

  String get _initial {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: name == null ? 'Your profile' : 'Profile of $name',
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            _initial,
            style: AppText.h3.copyWith(
              fontSize: size * 0.45,
              fontWeight: FontWeight.w700,
              color: AppColors.background,
            ),
          ),
        ),
      ),
    );
  }
}
