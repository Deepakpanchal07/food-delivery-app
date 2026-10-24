
import 'package:flutter/material.dart';

import '../../restaurants/models/restaurant.dart';
import '../../restaurants/screens/restaurant_details_screen.dart';
import '../../restaurants/services/restaurant_service.dart';
import '../services/favorite_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  final FavoriteService _favoriteService = FavoriteService.instance;

  late Future<List<Restaurant>> _restaurantsFuture;

  @override
  void initState() {
    super.initState();
    _restaurantsFuture = _loadRestaurants();
  }

  Future<List<Restaurant>> _loadRestaurants() async {
    await _favoriteService.initialize();
    return _restaurantService.getRestaurants();
  }

  Future<void> _refresh() async {
    setState(() {
      _restaurantsFuture = _loadRestaurants();
    });

    try {
      await _restaurantsFuture;
    } catch (_) {
      // FutureBuilder displays the error.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Restaurant>>(
        future: _restaurantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.deepOrange,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 50),
                    const SizedBox(height: 12),
                    const Text('Could not load restaurants.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final restaurants = snapshot.data ?? [];

          return AnimatedBuilder(
            animation: _favoriteService,
            builder: (context, _) {
              final favorites = restaurants
                  .where(
                    (restaurant) =>
                        _favoriteService.isFavorite(restaurant.id),
                  )
                  .toList();

              if (favorites.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: const [
                      SizedBox(height: 100),
                      Icon(
                        Icons.favorite_border,
                        size: 70,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          'No favorites yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Tap the heart on a restaurant to save it here.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final restaurant = favorites[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 170,
                                child: restaurant.imageUrl.isNotEmpty
                                    ? Image.network(
                                        restaurant.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _imagePlaceholder(),
                                      )
                                    : _imagePlaceholder(),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton.filled(
                                  tooltip: 'Remove from favorites',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red,
                                  ),
                                  icon: const Icon(Icons.favorite),
                                  onPressed: () async {
                                    await _favoriteService
                                        .toggleFavorite(restaurant.id);

                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${restaurant.name} removed from favorites',
                                          ),
                                          duration:
                                              const Duration(seconds: 1),
                                        ),
                                      );
                                  },
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  restaurant.name,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  restaurant.cuisine,
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${restaurant.rating} ★  •  '
                                  '${restaurant.deliveryTime} min  •  '
                                  '₹${restaurant.deliveryFee.toStringAsFixed(0)} delivery',
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              RestaurantDetailsScreen(
                                            restaurant: restaurant,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.restaurant_menu,
                                      color: Colors.deepOrange,
                                    ),
                                    label: const Text(
                                      'View Menu',
                                      style: TextStyle(
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.orange.shade50,
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant,
        size: 60,
        color: Colors.deepOrange,
      ),
    );
  }
}
