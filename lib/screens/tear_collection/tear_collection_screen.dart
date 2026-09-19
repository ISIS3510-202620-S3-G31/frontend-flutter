import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/screen_header.dart';
import 'tear_detail_screen.dart';
import 'tear_entry.dart';
import 'tear_jar_illustration.dart';
import 'tear_painter.dart';

/// Screen displaying the jar of preserved tears and the list of past tear entries.
class TearCollectionScreen extends StatelessWidget {
  const TearCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = TearEntry.samples;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ScreenHeader(
                title: Text('Tear Collection', style: AppText.h1),
                subtitle: 'Your emotional sanctuary',
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // Glass jar illustration with floating tears and cute mascot
                    const TearJarIllustration(),
                    const SizedBox(height: 12),

                    // Counter badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Teardrop(
                          width: 13,
                          height: 17,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entries.length + 2} tears preserved',
                          style: AppText.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // List of tear cards
                    for (final entry in entries) ...[
                      _TearCard(
                        entry: entry,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TearDetailScreen(entry: entry),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Bottom "Preserve a New Tear" button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: SizedBox(
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TearDetailScreen(entry: entries.first),
                        ),
                      );
                    },
                    child: Text(
                      'Preserve a New Tear',
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.text,
                      ),
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

class _TearCard extends StatelessWidget {
  const _TearCard({
    required this.entry,
    required this.onTap,
  });

  final TearEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.text.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Tear drop icon
              Teardrop(
                width: 16,
                height: 22,
                color: entry.color,
              ),
              const SizedBox(width: 16),

              // Title and timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.reasonHonored,
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM d, h:mm a').format(entry.timestamp),
                      style: AppText.bodyMuted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Chevron right icon
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.text,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
