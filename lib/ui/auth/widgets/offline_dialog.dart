import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

Future<void> showOfflineDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(
        Icons.wifi_off_rounded,
        color: AppColors.primary,
        size: 32,
      ),
      title: Text(
        'No internet connection',
        textAlign: TextAlign.center,
        style: AppText.h3.copyWith(fontWeight: FontWeight.w700),
      ),
      content: Text(
        'Your account is checked online. Turn on Wi-Fi or mobile data and '
        'try again.',
        textAlign: TextAlign.center,
        style: AppText.body,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.text,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
