
class Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final String description;
  final String imageUrl;
  final double rating;
  final int deliveryTime;
  final double deliveryFee;
  final bool isOpen;

  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.isOpen,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown Restaurant').toString(),
      cuisine: (json['cuisine'] ?? 'Various').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      deliveryTime: int.tryParse(
  (json['deliveryTime'] ?? '30').toString().split(' ').first.split('-').first,
) ?? 30,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      isOpen: json['isOpen'] as bool? ?? true,
    );
  }
}