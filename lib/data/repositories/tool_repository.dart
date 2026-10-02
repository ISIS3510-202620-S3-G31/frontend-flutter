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
    id: 'blow',
    title: 'Blow it out',
    description: 'Blow out the tension, one breath at a time.',
    iconAsset: 'assets/icons/ic_tool_blow.svg',
    category: ToolCategory.calmDown,
  ),
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
    id: 'jar',
    title: 'Achievement jar',
    description: 'Save and celebrate your daily wins.',
    iconAsset: 'assets/icons/ic_tool_jar.svg',
    category: ToolCategory.reflect,
  ),
  ToolItem(
    id: 'scream',
    title: 'Scream tank',
    description: 'Let it all out in a safe space.',
    iconAsset: 'assets/icons/ic_tool_scream.svg',
    category: ToolCategory.release,
  ),
  ToolItem(
    id: 'tear',
    title: 'Tear it up',
    description: 'Tear away what no longer serves you.',
    iconAsset: 'assets/icons/ic_tool_tear.svg',
    category: ToolCategory.release,
  ),
  ToolItem(
    id: 'detective',
    title: 'Thought detective',
    description: 'Uncover and reframe unhelpful thoughts.',
    iconAsset: 'assets/icons/ic_tool_detective.svg',
    category: ToolCategory.reflect,
  ),
  ToolItem(
    id: 'body',
    title: 'Body scan',
    description: 'Tune in and release physical tension.',
    iconAsset: 'assets/icons/ic_tool_body.svg',
    category: ToolCategory.calmDown,
  ),
  ToolItem(
    id: 'contain',
    title: 'Contain the worry',
    description: 'Set aside worries to revisit later.',
    iconAsset: 'assets/icons/ic_tool_contain.svg',
    category: ToolCategory.release,
  ),
];
