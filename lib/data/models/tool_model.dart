enum ToolCategory {
  all('All'),
  calmDown('Calm down'),
  release('Release'),
  reflect('Reflect');

  const ToolCategory(this.label);

  final String label;
}


enum ToolEntryPoint {
  /// The list in the Tools tab.
  toolbox,

  /// The personal "Suggested for today" card on the home.
  recommendation,

  /// The "Because of the weather" card on the home.
  weather,

  /// The "Your last recommendation" card on the home.
  lastRecommendation,

  /// "Leave it to chance": the app picks a tool at random.
  random,

  /// An insight in the Stats tab.
  stats,
}

class ToolItem {
  const ToolItem({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.category,
  });

  final String id;
  final String title;
  final String description;
  final String iconAsset;
  final ToolCategory category;
}
