import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import 'tool_item_model.dart';

/// Horizontal scrollable bar with category pills.
class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final ToolCategory selectedCategory;
  final ValueChanged<ToolCategory> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < ToolCategory.values.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _CategoryPill(
              category: ToolCategory.values[i],
              isSelected: ToolCategory.values[i] == selectedCategory,
              onTap: () => onCategorySelected(ToolCategory.values[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final ToolCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? AppColors.secondary : Colors.transparent,
        shape: StadiumBorder(
          side: isSelected
              ? BorderSide.none
              : BorderSide(
                  color: AppColors.text.withValues(alpha: 0.25),
                  width: 1.2,
                ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  SvgPicture.asset(
                    'assets/icons/ic_check_small.svg',
                    width: 14,
                    height: 14,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  category.label,
                  style: AppText.body.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: AppColors.text,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
