import 'package:flutter/material.dart';

import '../custom_breathing/custom_breathing_screen.dart';
import '../emotional_detective/emotional_detective_screen.dart';
import '../photo_of_the_day/photo_of_the_day_screen.dart';
import '../scream_tank/scream_tank_screen.dart';
import '../tear_collection/tear_collection_screen.dart';

enum ToolCategory {
  all('All'),
  calmDown('Calm down'),
  release('Release'),
  reflect('Reflect');

  const ToolCategory(this.label);

  final String label;
}

class ToolItem {
  const ToolItem({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.category,
    this.screenBuilder,
  });

  final String id;
  final String title;
  final String description;
  final String iconAsset;
  final ToolCategory category;
  final Widget Function(BuildContext)? screenBuilder;
}

final List<ToolItem> defaultTools = [
  const ToolItem(
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
    screenBuilder: (_) => const PhotoOfTheDayScreen(),
  ),
  ToolItem(
    id: 'breathing',
    title: 'Custom breathing',
    description: 'Build the rhythm that fits you.',
    iconAsset: 'assets/icons/ic_tool_breathing.svg',
    category: ToolCategory.calmDown,
    screenBuilder: (_) => const CustomBreathingScreen(),
  ),
  const ToolItem(
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
    screenBuilder: (_) => const ScreamTankScreen(),
  ),
  ToolItem(
    id: 'tear',
    title: 'Tear it up',
    description: 'Tear away what no longer serves you.',
    iconAsset: 'assets/icons/ic_tool_tear.svg',
    category: ToolCategory.release,
    screenBuilder: (_) => const TearCollectionScreen(),
  ),
  ToolItem(
    id: 'detective',
    title: 'Thought detective',
    description: 'Uncover and reframe unhelpful thoughts.',
    iconAsset: 'assets/icons/ic_tool_detective.svg',
    category: ToolCategory.reflect,
    screenBuilder: (_) => const EmotionalDetectiveScreen(),
  ),
  const ToolItem(
    id: 'body',
    title: 'Body scan',
    description: 'Tune in and release physical tension.',
    iconAsset: 'assets/icons/ic_tool_body.svg',
    category: ToolCategory.calmDown,
  ),
  const ToolItem(
    id: 'contain',
    title: 'Contain the worry',
    description: 'Set aside worries to revisit later.',
    iconAsset: 'assets/icons/ic_tool_contain.svg',
    category: ToolCategory.release,
  ),
];
