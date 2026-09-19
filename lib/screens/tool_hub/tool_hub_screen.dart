import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import 'category_filter_bar.dart';
import 'leave_to_chance_card.dart';
import 'tool_card.dart';
import 'tool_hub_header.dart';
import 'tool_item_model.dart';
import 'toolbox_bottom_nav.dart';

/// Main Toolbox screen that serves as the hub for all wellness tools.
class ToolHubScreen extends StatefulWidget {
  const ToolHubScreen({super.key});

  @override
  State<ToolHubScreen> createState() => _ToolHubScreenState();
}

class _ToolHubScreenState extends State<ToolHubScreen> {
  ToolCategory _selectedCategory = ToolCategory.all;
  int _selectedNavIndex = 0;

  List<ToolItem> get _filteredTools {
    if (_selectedCategory == ToolCategory.all) {
      return defaultTools;
    }
    return defaultTools
        .where((tool) => tool.category == _selectedCategory)
        .toList();
  }

  void _onCategorySelected(ToolCategory category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onToolTapped(ToolItem tool) {
    if (tool.screenBuilder != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: tool.screenBuilder!),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tool.title} is coming soon!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onSurpriseMe() {
    // Pick a random tool
    final random = math.Random();
    final tool = defaultTools[random.nextInt(defaultTools.length)];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Surprise! Opening ${tool.title}...'),
        duration: const Duration(seconds: 1),
      ),
    );

    if (tool.screenBuilder != null) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: tool.screenBuilder!),
        );
      });
    }
  }

  void _onNavTabSelected(int index) {
    if (index == 1) {
      // Random tab
      _onSurpriseMe();
      return;
    }
    if (index == 2) {
      // Stats tab
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stats coming soon!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _selectedNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tools = _filteredTools;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: ToolboxBottomNav(
          selectedIndex: _selectedNavIndex,
          onTabSelected: _onNavTabSelected,
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ToolHubHeader(
                onProfileTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile coming soon!')),
                  );
                },
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    CategoryFilterBar(
                      selectedCategory: _selectedCategory,
                      onCategorySelected: _onCategorySelected,
                    ),
                    LeaveToChanceCard(
                      onSurpriseMe: _onSurpriseMe,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCategory == ToolCategory.all
                                ? 'All tools'
                                : '${_selectedCategory.label} tools',
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
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          for (var i = 0; i < tools.length; i++) ...[
                            if (i > 0) const SizedBox(height: 12),
                            ToolCard(
                              tool: tools[i],
                              onTap: () => _onToolTapped(tools[i]),
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
  }
}
