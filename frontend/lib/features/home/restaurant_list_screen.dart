
import 'package:flutter/material.dart';
import 'package:frontend/features/favorites/screens/favorites_screen.dart';
import 'package:frontend/features/favorites/services/favorite_service.dart';
import 'package:frontend/features/restaurants/models/restaurant.dart';
import 'package:frontend/features/restaurants/screens/add_restaurant_screen.dart';
import 'package:frontend/features/restaurants/screens/restaurant_details_screen.dart';
import 'package:frontend/features/restaurants/services/restaurant_service.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() =>
      _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  final RestaurantService _service = RestaurantService();
  final TextEditingController _searchController =
      TextEditingController();

  late Future<List<Restaurant>> _restaurantsFuture;

  String _searchQuery = '';
  String _selectedCuisine = 'All';
  String _selectedAvailability = 'All';
  String _sortBy = 'Recommended';

 @override
void initState() {
  super.initState();
  _restaurantsFuture = _service.getRestaurants();
  _initializeFavorites();
}

Future<void> _initializeFavorites() async {
  await FavoriteService.instance.initialize();

  if (mounted) {
    setState(() {});
  }
}
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    final future = _service.getRestaurants();

    setState(() {
      _restaurantsFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder displays the error.
    }
  }

  List<Restaurant> _filterRestaurants(
    List<Restaurant> restaurants,
  ) {
    final filtered = restaurants.where((restaurant) {
      final query = _searchQuery.trim().toLowerCase();

      final matchesSearch =
          restaurant.name.toLowerCase().contains(query) ||
          restaurant.cuisine.toLowerCase().contains(query) ||
          restaurant.description.toLowerCase().contains(query);

      final matchesCuisine = _selectedCuisine == 'All' ||
          restaurant.cuisine.toLowerCase() ==
              _selectedCuisine.toLowerCase();

      final matchesAvailability =
          _selectedAvailability == 'All' ||
          (_selectedAvailability == 'Open' && restaurant.isOpen) ||
          (_selectedAvailability == 'Closed' && !restaurant.isOpen);

      return matchesSearch &&
          matchesCuisine &&
          matchesAvailability;
    }).toList();

    if (_sortBy == 'Highest Rated') {
      filtered.sort(
        (a, b) => b.rating.compareTo(a.rating),
      );
    } else if (_sortBy == 'Lowest Delivery Fee') {
      filtered.sort(
        (a, b) => a.deliveryFee.compareTo(b.deliveryFee),
      );
    } else if (_sortBy == 'Fastest Delivery') {
      filtered.sort(
        (a, b) => a.deliveryTime.compareTo(b.deliveryTime),
      );
    }

    return filtered;
  }

  List<String> _getCuisines(List<Restaurant> restaurants) {
    final cuisines = restaurants
        .map((restaurant) => restaurant.cuisine.trim())
        .where((cuisine) => cuisine.isNotEmpty)
        .toSet()
        .toList();

    cuisines.sort(
      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );

    return ['All', ...cuisines];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Restaurants',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'My Favorites',
            icon: const Icon(Icons.favorite),
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
            icon: const Icon(Icons.add),
            tooltip: 'Add Restaurant',
            onPressed: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddRestaurantScreen(),
                ),
              );

              if (!mounted) return;

              if (added == true) {
                await _retry();
              }
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
                    const Icon(
                      Icons.cloud_off,
                      size: 55,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load restaurants',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please check the backend connection.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _retry,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final restaurants = snapshot.data ?? [];
          final cuisines = _getCuisines(restaurants);
          final filteredRestaurants =
              _filterRestaurants(restaurants);

          return RefreshIndicator(
            onRefresh: _retry,
            child: ListView(
              padding: const EdgeInsets.all(12),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search restaurants or cuisine...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.deepOrange,
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
                    fillColor: Colors.orange.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Cuisine filters
                const Text(
                  'Explore Cuisines',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cuisines.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cuisine = cuisines[index];
                      final selected =
                          _selectedCuisine == cuisine;

                      return ChoiceChip(
                        label: Text(cuisine),
                        selected: selected,
                        selectedColor: Colors.deepOrange,
                        backgroundColor: Colors.orange.shade50,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedCuisine = cuisine;
                          });
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Availability filter
                const Text(
                  'Availability',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  children: ['All', 'Open', 'Closed'].map((value) {
                    return ChoiceChip(
                      label: Text(value),
                      selected: _selectedAvailability == value,
                      selectedColor: Colors.deepOrange,
                      labelStyle: TextStyle(
                        color: _selectedAvailability == value
                            ? Colors.white
                            : Colors.black87,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedAvailability = value;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Sorting dropdown
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Restaurants',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DropdownButton<String>(
                      value: _sortBy,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'Recommended',
                          child: Text('Recommended'),
                        ),
                        DropdownMenuItem(
                          value: 'Highest Rated',
                          child: Text('Top Rated'),
                        ),
                        DropdownMenuItem(
                          value: 'Lowest Delivery Fee',
                          child: Text('Lowest Fee'),
                        ),
                        DropdownMenuItem(
                          value: 'Fastest Delivery',
                          child: Text('Fastest'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _sortBy = value;
                        });
                      },
                    ),
                  ],
                ),

                Text(
                  '${filteredRestaurants.length} restaurant(s) found',
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 12),

                if (filteredRestaurants.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 45,
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 65,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No restaurants found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try another search or change your filters.',
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedCuisine = 'All';
                              _selectedAvailability = 'All';
                              _sortBy = 'Recommended';
                            });
                          },
                          child: const Text('Clear all filters'),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredRestaurants.map(
                    (restaurant) => _restaurantCard(restaurant),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _restaurantCard(Restaurant restaurant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantDetailsScreen(
                restaurant: restaurant,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (restaurant.imageUrl.isNotEmpty)
                  Image.network(
                    restaurant.imageUrl,
                    height: 175,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _imagePlaceholder(),
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
                      color: restaurant.isOpen
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      restaurant.isOpen ? 'OPEN' : 'CLOSED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: AnimatedBuilder(
                    animation: FavoriteService.instance,
                    builder: (context, _) {
                      final isFavorite = FavoriteService.instance
                          .isFavorite(restaurant.id);

                      return IconButton.filled(
                        tooltip: isFavorite
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: isFavorite
                              ? Colors.red
                              : Colors.grey.shade700,
                        ),
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                        ),
                        onPressed: () async {
                          try {
                            await FavoriteService.instance
                                .toggleFavorite(restaurant.id);

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isFavorite
                                        ? '${restaurant.name} removed from favorites'
                                        : '${restaurant.name} added to favorites',
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
                      fontSize: 20,
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

                  if (restaurant.description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(restaurant.description),
                  ],

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _infoItem(
                        Icons.star,
                        restaurant.rating.toString(),
                        iconColor: Colors.amber.shade800,
                      ),
                      _infoItem(
                        Icons.access_time,
                        '${restaurant.deliveryTime} min',
                      ),
                      _infoItem(
                        Icons.delivery_dining,
                        '₹${restaurant.deliveryFee.toStringAsFixed(0)} delivery',
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'View Menu',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.deepOrange,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(
    IconData icon,
    String text, {
    Color? iconColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: iconColor ?? Colors.grey.shade700,
        ),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 175,
      width: double.infinity,
      color: Colors.orange.shade50,
      child: const Icon(
        Icons.restaurant,
        size: 65,
        color: Colors.deepOrange,
      ),
    );
  }
}
