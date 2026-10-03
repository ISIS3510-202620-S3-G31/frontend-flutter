import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/screen_header.dart';
import '../view_model/tear_collection_view_model.dart';
import 'tear_detail_screen.dart';
import 'tear_entry.dart';
import 'tear_jar_illustration.dart';
import 'tear_painter.dart';

/// Screen displaying the jar of preserved tears and the list of past tear entries.
class TearCollectionScreen extends StatefulWidget {
  const TearCollectionScreen({super.key, this.viewModel});

  /// Pass an instance in tests; otherwise the screen manages its own ViewModel.
  final TearCollectionViewModel? viewModel;

  @override
  State<TearCollectionScreen> createState() => _TearCollectionScreenState();
}

class _TearCollectionScreenState extends State<TearCollectionScreen> {
  late final TearCollectionViewModel _viewModel =
      widget.viewModel ?? TearCollectionViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;

  @override
  void initState() {
    super.initState();
    _viewModel.load();
  }

  @override
  void dispose() {
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  void _showPreserveTearSheet(BuildContext context) {
    final titleController = TextEditingController();
    final reasonController = TextEditingController();
    final reflectionController = TextEditingController();
    var reliefLevel = 7;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.text.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Preserve a New Tear',
                      style: AppText.h2.copyWith(color: AppColors.text),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Honor your emotions and observe the relief you felt.',
                      style: AppText.bodyMuted,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ROOT EMOTION / MEMORY TITLE',
                      style: AppText.body.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Overwhelm & Anxiety',
                        hintStyle: AppText.bodyMuted,
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'WHAT CAUSED YOUR TEARS?',
                      style: AppText.body.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Stress after intense exam',
                        hintStyle: AppText.bodyMuted,
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RELIEF LEVEL',
                          style: AppText.body.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Lv. $reliefLevel/10',
                          style: AppText.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: reliefLevel.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.background,
                      onChanged: (val) {
                        setSheetState(() => reliefLevel = val.round());
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'COMPASSION REFLECTION NOTE',
                      style: AppText.body.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reflectionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            'e.g. Releasing this allowed my body to relax.',
                        hintStyle: AppText.bodyMuted,
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.text,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          final title = titleController.text.trim();
                          final reason = reasonController.text.trim();
                          final reflection =
                              reflectionController.text.trim().isEmpty
                                  ? 'You honored your feelings with kindness and care.'
                                  : reflectionController.text.trim();

                          if (title.isNotEmpty || reason.isNotEmpty) {
                            _viewModel.logTear(
                              memoryTitle:
                                  title.isEmpty ? 'Gentle Release' : title,
                              cryingReason:
                                  reason.isEmpty ? 'Release of emotion' : reason,
                              reliefLevel: reliefLevel,
                              reflectionNote: reflection,
                            );
                            Navigator.pop(bottomSheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tear preserved in your jar ✨'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Save to Jar',
                          style: AppText.body.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final collection = _viewModel.tearCollection;
        final entries = collection.tears;

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
                    onBack: () =>
                        Navigator.maybePop(context, _viewModel.isCompleted),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        // Glass jar illustration with floating tears and cute mascot
                        const TearJarIllustration(),
                        const SizedBox(height: 12),

                        // Counter and metrics badge
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
                              '${collection.totalTearsLogged} ${collection.totalTearsLogged == 1 ? "tear" : "tears"} preserved',
                              style: AppText.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            if (collection.totalTearsLogged > 0) ...[
                              Text(
                                ' • ',
                                style: AppText.bodyMuted.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Avg Lv. ${collection.averageReliefLevel.toStringAsFixed(1)}/10',
                                style: AppText.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        // List of tear cards
                        if (entries.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            child: Center(
                              child: Text(
                                'No preserved tears yet.\nTap below to honor your first tear.',
                                textAlign: TextAlign.center,
                                style: AppText.bodyMuted,
                              ),
                            ),
                          )
                        else
                          for (final entry in entries) ...[
                            _TearCard(
                              entry: entry,
                              onTap: () {
                                _viewModel.selectTear(entry);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TearDetailScreen(entry: entry),
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
                        onPressed: () => _showPreserveTearSheet(context),
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
      },
    );
  }
}

class _TearCard extends StatelessWidget {
  const _TearCard({required this.entry, required this.onTap});

  final Tear entry;
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
              Teardrop(width: 16, height: 22, color: entry.color),
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

              // Relief level chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Lv. ${entry.reliefLevel}',
                  style: AppText.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),

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
