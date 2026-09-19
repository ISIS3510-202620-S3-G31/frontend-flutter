import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/screen_header.dart';
import 'tear_entry.dart';
import 'tear_mascot.dart';
import 'tear_painter.dart';

/// Screen displaying the details, root emotion, and compassion reflection for a preserved tear.
class TearDetailScreen extends StatelessWidget {
  const TearDetailScreen({super.key, required this.entry});

  final TearEntry entry;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ScreenHeader(title: Text('Tear Detail', style: AppText.h1)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const FloatingHeroTeardrop(),
                      const SizedBox(height: 6),

                      Text(
                        DateFormat(
                          'MMM d, yyyy — h:mm a',
                        ).format(entry.timestamp),
                        style: AppText.bodyMuted.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 18),

                      // Detail Card
                      _DetailCard(entry: entry),
                      const SizedBox(height: 24),

                      // Action Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.text,
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Navigating to recommended tool...',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Text(
                            'Go to Recommended Tool',
                            style: AppText.body.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Save to My Insights & Finish',
                          style: AppText.body.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
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

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.entry});

  final TearEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // Soft outer warm glow
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.85),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. REASON HONORED
          _SectionHeader(title: 'REASON HONORED'),
          const SizedBox(height: 4),
          Text(
            entry.reasonHonored,
            style: AppText.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          _CardDivider(),

          // 2. ROOT EMOTION IDENTIFIED
          _SectionHeader(title: 'ROOT EMOTION IDENTIFIED'),
          const SizedBox(height: 4),
          Text(
            entry.rootEmotion,
            style: AppText.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          _CardDivider(),

          // 3. RELIEF LEVEL
          _SectionHeader(title: 'RELIEF LEVEL'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (entry.reliefLevel / 10.0).clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFEADBCE),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Lv. ${entry.reliefLevel}/10',
                style: AppText.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          _CardDivider(),

          // 4. COMPASSION REFLECTION
          _SectionHeader(title: 'COMPASSION REFLECTION'),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  entry.compassionReflection,
                  style: AppText.body.copyWith(
                    fontSize: 13.5,
                    height: 1.45,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const SproutMascot(width: 56, height: 68),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppText.body.copyWith(
        color: AppColors.secondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        color: AppColors.text.withValues(alpha: 0.1),
        height: 1,
        thickness: 1,
      ),
    );
  }
}
