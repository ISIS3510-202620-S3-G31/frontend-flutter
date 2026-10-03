import 'package:flutter/material.dart';

import '../../../data/models/insight_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/circle_icon_button.dart';
import '../../home/tool_routes.dart';
import '../view_model/stats_view_model.dart';
import 'emotion_style.dart';
import 'insight_card.dart';
import 'stats_card.dart';
import 'summary_card.dart';
import 'tools_frequency_chart.dart';
import 'weekly_emotion_chart.dart';

/// Stats tab: how the week went, which tools were used most and what the app
/// learned from the user's history.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.onOpenToolbox, this.viewModel});

  /// Goes back to the Tools tab.
  final VoidCallback onOpenToolbox;

  /// Pass one in tests; otherwise the screen builds and disposes its own.
  final StatsViewModel? viewModel;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final StatsViewModel _viewModel = widget.viewModel ?? StatsViewModel();
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

  void _onInsightAction(InsightAction action) {
    switch (action) {
      case OpenTool(:final toolId):
        final screen = toolScreens[toolId];
        if (screen == null) {
          _showMessage('This tool is coming soon!');
          return;
        }
        openToolScreen(
          context,
          toolId: toolId,
          toolName: _viewModel.toolNameOf(toolId),
          builder: screen,
        );
      case OpenToolbox():
        widget.onOpenToolbox();
      case OpenCheckIn():
        _showMessage('Check-ins are coming soon!');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final topFeeling = _viewModel.topFeeling;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Wellbeing Stats',
                        style: AppText.breathingTitle,
                      ),
                    ),
                    CircleIconButton(
                      asset: 'assets/icons/ic_restart.svg',
                      semanticLabel: 'Refresh',
                      background: AppColors.surfaceDim,
                      onPressed: _viewModel.loading ? null : _viewModel.load,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    if (_viewModel.isSample && !_viewModel.loading) ...[
                      const _SampleDataNotice(),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            badge: Text(
                              topFeeling?.emoji ?? '🙂',
                              style: const TextStyle(fontSize: 20),
                            ),
                            badgeColor: topFeeling?.color ?? AppColors.text,
                            label: 'Top Feeling',
                            value: topFeeling?.label ?? 'None yet',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryCard(
                            badge: const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                            ),
                            badgeColor: AppColors.primary,
                            label: 'Check-ins',
                            value: '${_viewModel.weekCheckIns}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StatsCard(
                      title: 'Weekly Emotion Journey',
                      subtitle: 'Dominant emotion per day and its intensity',
                      icon: Icons.calendar_today_outlined,
                      child: WeeklyEmotionChart(days: _viewModel.week),
                    ),
                    const SizedBox(height: 16),
                    StatsCard(
                      title: 'Tools Frequency',
                      subtitle: 'Historical distribution by % of tool usage',
                      icon: Icons.pie_chart,
                      child: ToolsFrequencyChart(shares: _viewModel.toolShares),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Useful Insights',
                      style: AppText.h3.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Patterns found in your own history',
                      style: AppText.bodyMuted.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    if (_viewModel.insights.isEmpty && !_viewModel.loading)
                      Text(
                        'Keep checking in and using your tools. Insights '
                        'show up after a few days.',
                        style: AppText.bodyMuted,
                      ),
                    for (final insight in _viewModel.insights)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InsightCard(
                          insight: insight,
                          onAction: _onInsightAction,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Tells the user these numbers are an example until they answer their first
/// tool feedback.
class _SampleDataNotice extends StatelessWidget {
  const _SampleDataNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDim.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppColors.text),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sample data. Finish a tool and answer its feedback to see your '
              'own numbers here.',
              style: AppText.bodyMuted.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
