import 'package:flutter/material.dart';

import '../../../data/models/insight_model.dart';
import '../../check_in/widgets/mood_check_in_sheet.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/circle_icon_button.dart';
import '../../feedback/widgets/tool_feedback_screen.dart';
import '../../home/tool_routes.dart';
import '../view_model/stats_view_model.dart';
import 'emotion_style.dart';
import 'insight_card.dart';
import 'stats_card.dart';
import 'summary_card.dart';
import 'tools_frequency_chart.dart';
import 'weekly_emotion_chart.dart';

/// Leaving a tool sooner than this is a misclick, not a session worth rating.
const _minSecondsForFeedback = 10;

/// Stats tab: how the week went, which tools were used most and what the app learned from the user's history.
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
        _openTool(toolId, screen);
      case OpenToolbox():
        widget.onOpenToolbox();
      case OpenCheckIn():
        _openCheckIn();
    }
  }

  /// Opens a tool from an insight and, once the user comes back from it, asks how it went. The session is logged through the view model.
  Future<void> _openTool(String toolId, WidgetBuilder builder) async {
    final toolName = _viewModel.toolNameOf(toolId);
    final startedAt = DateTime.now();
    await _viewModel.startToolSession(toolId: toolId, toolName: toolName);
    if (!mounted) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: builder,
        settings: RouteSettings(name: '/tools/$toolId'),
      ),
    );

    final seconds = DateTime.now().difference(startedAt).inSeconds;

    if (result == true) {
      await _viewModel.completeToolSession(
        toolId: toolId,
        toolName: toolName,
        durationSeconds: seconds,
      );
    }

    await _viewModel.endToolSession(
      toolId: toolId,
      toolName: toolName,
      durationSeconds: seconds,
      exitReason: 'left_tool',
    );

    if (!mounted || seconds < _minSecondsForFeedback) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ToolFeedbackScreen(
          toolId: toolId,
          toolName: toolName,
          startedAt: startedAt,
          durationSeconds: seconds,
        ),
      ),
    );
  }

  /// A new check-in changes the numbers, so the screen reloads after it.
  Future<void> _openCheckIn() async {
    final saved = await showMoodCheckIn(context);
    if (saved) await _viewModel.load();
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
              Expanded(child: _body()),
            ],
          );
        },
      ),
    );
  }

  Widget _body() {
    if (_viewModel.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_viewModel.isEmpty) {
      return _EmptyStats(
        onCheckIn: _openCheckIn,
        onOpenToolbox: widget.onOpenToolbox,
      );
    }
    final topFeeling = _viewModel.topFeeling;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
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
                badge: const Icon(Icons.check_circle, color: AppColors.primary),
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
        if (_viewModel.insights.isEmpty)
          Text(
            'Keep checking in and using your tools. Insights '
            'show up after a few days.',
            style: AppText.bodyMuted,
          ),
        for (final insight in _viewModel.insights)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InsightCard(insight: insight, onAction: _onInsightAction),
          ),
      ],
    );
  }
}

/// Shown while the user has nothing recorded yet: no charts, no made up  numbers, just the two ways to start filling them.
class _EmptyStats extends StatelessWidget {
  const _EmptyStats({required this.onCheckIn, required this.onOpenToolbox});

  final VoidCallback onCheckIn;
  final VoidCallback onOpenToolbox;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.surfaceDim, width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceDim,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  size: 30,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nothing to show yet',
                style: AppText.h3.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your stats are built from your own check-ins and the tools '
                'you finish. Start with either one and they will show up here.',
                style: AppText.bodyMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: onCheckIn,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.text,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Check in now',
                    style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: onOpenToolbox,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: const BorderSide(
                      color: AppColors.surfaceDim,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Explore the tools',
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
