import 'package:flutter/material.dart';
import 'package:frontend/features/auth/services/auth_service.dart';
import 'package:frontend/features/favorites/screens/favorites_screen.dart';
import 'package:frontend/features/favorites/services/favorite_service.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:frontend/features/restaurants/screens/restaurant_details_screen.dart';
import 'package:frontend/features/restaurants/services/restaurant_service.dart';
import '../../restaurants/models/restaurant.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  final TextEditingController _searchController =
      TextEditingController();
      final AuthService _authService = AuthService();

String? currentUserRole;

  late Future<List<Restaurant>> _restaurantsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    _loadUserRole();
  }
  Future<void> _loadUserRole() async {
  final role = await _authService.getUserRole();

  if (!mounted) return;

  setState(() {
    currentUserRole = role;
  });
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRestaurants() {
    _restaurantsFuture = _restaurantService.getRestaurants();
  }

  Future<void> _refreshRestaurants() async {
    final future = _restaurantService.getRestaurants();

    setState(() {
      _restaurantsFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder displays the error.
    }
  }

  void _openRestaurant(Restaurant restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailsScreen(
          restaurant: restaurant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.restaurant_menu_rounded, size: 27),
            SizedBox(width: 9),
            Text(
              'Foodie',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 23,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My Favorites',
            icon: const Icon(Icons.favorite_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FavoritesScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'My Profile',
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: FutureBuilder<List<Restaurant>>(
  future: _restaurantsFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
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
              const Icon(
                Icons.wifi_off_rounded,
                size: 55,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              const Text(
                'Could not load restaurants.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _refreshRestaurants,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final restaurants = snapshot.data ?? [];

    final filteredRestaurants = restaurants.where((restaurant) {
      final name = restaurant.name.toLowerCase();
      final cuisine = restaurant.cuisine.toLowerCase();

      return name.contains(_searchQuery) ||
          cuisine.contains(_searchQuery);
    }).toList();

    return RefreshIndicator(
      color: const Color(0xFFFF6B35),
      onRefresh: _refreshRestaurants,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          // Hungry banner and search bar scroll together
          // with the restaurant list.
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B35),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hungry?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Discover delicious food near you.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search restaurants or cuisine...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFFFF6B35),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Restaurant heading and cards are part of the same scroll.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Popular Restaurants',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF292321),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${filteredRestaurants.length} restaurants available',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),

                if (filteredRestaurants.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 55),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          restaurants.isEmpty
                              ? 'No restaurants available yet.'
                              : 'No matching restaurants found.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                ...filteredRestaurants.map((restaurant) {
                  return _RestaurantCard(
                    restaurant: restaurant,
                    onTap: () => _openRestaurant(restaurant),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  },
),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const _RestaurantCard({
    required this.restaurant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (restaurant.imageUrl.isNotEmpty)
                  Image.network(
                    restaurant.imageUrl,
                    height: 185,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _imagePlaceholder();
                    },
                  )
                else
                  _imagePlaceholder(),

                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          restaurant.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                  Positioned(
                    top: 12,
                    left: 12,
                    child: AnimatedBuilder(
                      animation: FavoriteService.instance,
                      builder: (context, child) {
                        final isFavorite = FavoriteService.instance
                            .isFavorite(restaurant.id);

                        return Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 3,
                          child: IconButton(
                            tooltip: isFavorite
                                ? 'Remove from favorites'
                                : 'Add to favorites',
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavorite ? Colors.red : Colors.black87,
                            ),
                            onPressed: () async {
                              try {
                                await FavoriteService.instance
                                    .toggleFavorite(restaurant.id);

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isFavorite
                                          ? 'Removed from favorites'
                                          : 'Added to favorites',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not update favorites.'),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),

              ],
            ),

            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF292321),
                    ),
                  ),
                  const SizedBox(height: 5),

                  Text(
                    restaurant.cuisine,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),

                  if (restaurant.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      restaurant.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 18,
                        color: Color(0xFFFF6B35),
                      ),
                      const SizedBox(width: 5),
                      Text('${restaurant.deliveryTime} min'),
                      const SizedBox(width: 14),

                      const Icon(
                        Icons.delivery_dining_rounded,
                        size: 19,
                        color: Color(0xFFFF6B35),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant.deliveryFee == 0
                              ? 'Free delivery'
                              : '₹${restaurant.deliveryFee.toStringAsFixed(0)} delivery',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: restaurant.isOpen
                              ? const Color(0xFFE5F6E9)
                              : const Color(0xFFFFE8E8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          restaurant.isOpen ? 'Open' : 'Closed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: restaurant.isOpen
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'View Menu',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 185,
      width: double.infinity,
      color: const Color(0xFFFFE5D9),
      child: const Icon(
        Icons.restaurant_rounded,
        color: Color(0xFFFF6B35),
        size: 60,
      ),
    );
  }
}
