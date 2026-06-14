class StoreItem {
  final String id;
  final String name;
  final String description;
  final int cost;
  final String itemType; // AVATAR, FRAME, THEME, BADGE, LIFE_REFILL
  final int minLevelRequired;
  final String? icon;

  StoreItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.cost,
    required this.itemType,
    this.minLevelRequired = 1,
    this.icon,
  });
}
