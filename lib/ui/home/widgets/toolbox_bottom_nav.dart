import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../view_model/tool_hub_view_model.dart';

/// Bottom navigation bar with the Stats, Home and Profile tabs.
class ToolboxBottomNav extends StatelessWidget {
  const ToolboxBottomNav({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final HomeTab selectedTab;
  final ValueChanged<HomeTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.06),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                iconAsset: 'assets/icons/ic_stats.svg',
                label: 'Stats',
                isSelected: selectedTab == HomeTab.stats,
                onTap: () => onTabSelected(HomeTab.stats),
              ),
              _NavItem(
                iconAsset: 'assets/icons/ic_tools.svg',
                label: 'Home',
                isSelected: selectedTab == HomeTab.home,
                onTap: () => onTabSelected(HomeTab.home),
              ),
              _NavItem(
                iconAsset: 'assets/icons/ic_profile.svg',
                label: 'Profile',
                isSelected: selectedTab == HomeTab.profile,
                onTap: () => onTabSelected(HomeTab.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.iconAsset,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.secondary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: SvgPicture.asset(iconAsset, width: 20, height: 20),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.body.copyWith(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.text : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
