import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/tool_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../stats/widgets/stats_screen.dart';
import '../../usage_flow/widgets/usage_flow_screen.dart';
import '../tool_routes.dart';
import '../view_model/tool_hub_view_model.dart';
import 'category_filter_bar.dart';
import 'leave_to_chance_card.dart';
import 'tool_card.dart';
import 'tool_hub_header.dart';
import 'toolbox_bottom_nav.dart';
import '../../auth/widgets/profile_screen.dart';

/// Toolbox: the home screen that lists every wellness tool.
class ToolHubScreen extends StatefulWidget {
  const ToolHubScreen({super.key, this.viewModel});

  /// Pass one in tests; otherwise the screen builds and disposes its own.
  final ToolHubViewModel? viewModel;

  @override
  State<ToolHubScreen> createState() => _ToolHubScreenState();
}

class _ToolHubScreenState extends State<ToolHubScreen> {
  late final ToolHubViewModel _viewModel =
      widget.viewModel ?? ToolHubViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;

  @override
  void dispose() {
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  void _openTool(ToolItem tool) {
    final screen = toolScreens[tool.id];
    if (screen == null) {
      _showMessage('${tool.title} is coming soon!');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UsageFlowScreen(tool: tool, toolScreen: screen),
      ),
    );
  }

  Future<void> _openRandomTool() async {
    final tool = _viewModel.randomTool();
    _showMessage('Surprise! Opening ${tool.title}...', seconds: 1);
    // Let the user read the message before the screen changes.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || toolScreens[tool.id] == null) return;
    _openTool(tool);
  }

  void _onTabSelected(int index) {
    switch (index) {
      case 1:
        _openRandomTool();
      default:
        _viewModel.selectTab(index);
    }
  }

  void _showMessage(String message, {int seconds = 2}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: seconds),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final tools = _viewModel.tools;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: AppColors.background,
            bottomNavigationBar: ToolboxBottomNav(
              selectedIndex: _viewModel.selectedTab,
              onTabSelected: _onTabSelected,
            ),
            body: _viewModel.selectedTab == 2
                ? StatsScreen(onOpenToolbox: () => _viewModel.selectTab(0))
                : SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        ToolHubHeader(
                          onProfileTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              CategoryFilterBar(
                                selectedCategory: _viewModel.selectedCategory,
                                onCategorySelected: _viewModel.selectCategory,
                              ),
                              LeaveToChanceCard(onSurpriseMe: _openRandomTool),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  12,
                                  24,
                                  12,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _viewModel.listTitle,
                                      style: AppText.h3.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    Text(
                                      '${tools.length}',
                                      style: AppText.body.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Column(
                                  children: [
                                    for (var i = 0; i < tools.length; i++) ...[
                                      if (i > 0) const SizedBox(height: 12),
                                      ToolCard(
                                        tool: tools[i],
                                        onTap: () => _openTool(tools[i]),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
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
