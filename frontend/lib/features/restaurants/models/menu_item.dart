
class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isAvailable;

  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.isAvailable,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final restaurant = json['restaurantId'];

    return MenuItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      restaurantId: restaurant is Map
          ? (restaurant['_id'] ?? restaurant['id'] ?? '').toString()
          : (restaurant ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: double.tryParse(
            (json['price'] ?? 0).toString(),
          ) ??
          0.0,
      imageUrl: (json['imageUrl'] ?? '').toString(),
      category: (json['category'] ?? 'Main Course').toString(),
      isAvailable: json['isAvailable'] != false,
    );
  }
}
