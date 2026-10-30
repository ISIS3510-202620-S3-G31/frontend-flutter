import 'dart:math';

import '../models/tool_model.dart';

class ToolRepository {
  const ToolRepository();

  List<ToolItem> allTools() => _tools;

  List<ToolItem> toolsIn(ToolCategory category) => category == ToolCategory.all
      ? _tools
      : _tools.where((tool) => tool.category == category).toList();

  ToolItem randomTool() => _tools[Random().nextInt(_tools.length)];
}

const _tools = [
  ToolItem(
    id: 'photo',
    title: 'Photo of the day',
    description: 'One photo a day, one new memory.',
    iconAsset: 'assets/icons/ic_tool_photo.svg',
    category: ToolCategory.reflect,
  ),
  ToolItem(
    id: 'breathing',
    title: 'Custom breathing',
    description: 'Build the rhythm that fits you.',
    iconAsset: 'assets/icons/ic_tool_breathing.svg',
    category: ToolCategory.calmDown,
  ),
  ToolItem(
    id: 'scream',
    title: 'Scream tank',
    description: 'Let it all out in a safe space.',
    iconAsset: 'assets/icons/ic_tool_scream.svg',
    category: ToolCategory.release,
  ),
];
