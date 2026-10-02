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
  });

  final String id;
  final String title;
  final String description;
  final String iconAsset;
  final ToolCategory category;
}
