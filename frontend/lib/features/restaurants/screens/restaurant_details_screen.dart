
import 'package:flutter/material.dart';
import 'package:frontend/features/cart/screens/cart_screen.dart';
import 'package:frontend/features/cart/services/cart_service.dart';
import 'package:frontend/features/reviews/services/review_service.dart';
import 'package:intl/intl.dart';

import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../services/menu_service.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailsScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState
    extends State<RestaurantDetailsScreen> {
  final MenuService _menuService = MenuService();
  final TextEditingController _searchController =
      TextEditingController();

      final ReviewService _reviewService = ReviewService();

late Future<Map<String, dynamic>> _reviewsFuture;

int _selectedRating = 5;
final TextEditingController _reviewController =
    TextEditingController();
bool _isSubmittingReview = false;

  late Future<List<MenuItem>> _menuFuture;

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'Recommended';

  @override
  void initState() {
    super.initState();
    _menuFuture = _menuService.getMenu(widget.restaurant.id);
     _reviewsFuture =
      _reviewService.getReviews(widget.restaurant.id);
  }

  @override
  void dispose() {
    _searchController.dispose();
     _reviewController.dispose();
    super.dispose();
  }

  void _retryMenu() {
    setState(() {
      _menuFuture = _menuService.getMenu(widget.restaurant.id);
    });
  }

  
  void _reloadReviews() {
    setState(() {
      _reviewsFuture =
          _reviewService.getReviews(widget.restaurant.id);
    });
  }

  Future<void> _submitReview() async {
    if (_isSubmittingReview) return;

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      await _reviewService.submitReview(
        restaurantId: widget.restaurant.id,
        rating: _selectedRating,
        comment: _reviewController.text.trim(),
      );

      if (!mounted) return;

      _reviewController.clear();
      _reloadReviews();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your review was submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReview = false;
        });
      }
    }
  }

  String _formatReviewDate(dynamic value) {
  if (value == null) return '';

  final date = DateTime.tryParse(value.toString());

  if (date == null) return '';

  return DateFormat('dd MMM yyyy').format(date.toLocal());
}

  Widget _buildReviewsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final reviews = data?['reviews'] is List
            ? List<Map<String, dynamic>>.from(
                (data!['reviews'] as List).map(
                  (item) => Map<String, dynamic>.from(item as Map),
                ),
              )
            : <Map<String, dynamic>>[];

        final averageRating =
            (data?['averageRating'] as num?)?.toDouble() ?? 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            const Text(
              'Reviews & Ratings',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (snapshot.hasError)
              Card(
                child: ListTile(
                  title: const Text('Could not load reviews'),
                  subtitle: Text('${snapshot.error}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _reloadReviews,
                  ),
                ),
              )
            else ...[
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 38,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('${reviews.length} review(s)'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

                ...reviews.map((review) {
                  final rating =
                      (review['rating'] as num?)?.toInt() ?? 0;

                  final comment =
                      (review['comment'] ?? '').toString();

                  final user = review['userId'];

                  String reviewerName = 'Customer';

                  if (user is Map) {
                    final name = (user['name'] ??
                            user['fullName'] ??
                            user['username'] ??
                            '')
                        .toString()
                        .trim();

                    if (name.isNotEmpty) {
                      reviewerName = name;
                    } else {
                      final firstName =
                          (user['firstName'] ?? '').toString().trim();

                      final lastName =
                          (user['lastName'] ?? '').toString().trim();

                      final fullName =
                          '$firstName $lastName'.trim();

                      if (fullName.isNotEmpty) {
                        reviewerName = fullName;
                      }
                    }
                  }

                  final reviewDate =
                      _formatReviewDate(review['createdAt']);

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ...List.generate(
                                5,
                                (index) => Icon(
                                  index < rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$rating/5',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 18,
                                color: Colors.deepOrange,
                              ),
                              const SizedBox(width: 6),

                              Expanded(
                                child: Text(
                                  reviewerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              if (reviewDate.isNotEmpty) ...[
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  reviewDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          if (comment.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(comment),
                          ],
                        ],
                      ),
                    ),
                  );
                }),

              if (reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'No reviews yet. Be the first to review!',
                  ),
                ),
            ],

            const SizedBox(height: 16),
            const Text(
              'Write a Review',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select your rating'),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(
                        5,
                        (index) => IconButton(
                          tooltip: '${index + 1} star(s)',
                          onPressed: _isSubmittingReview
                              ? null
                              : () {
                                  setState(() {
                                    _selectedRating = index + 1;
                                  });
                                },
                          icon: Icon(
                            index < _selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _reviewController,
                      maxLines: 3,
                      maxLength: 1000,
                      decoration: InputDecoration(
                        hintText: 'Share your experience (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmittingReview
                            ? null
                            : _submitReview,
                        icon: _isSubmittingReview
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _isSubmittingReview
                              ? 'Submitting...'
                              : 'Submit Review',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  List<String> _getCategories(List<MenuItem> items) {
    final categories = items
        .map((item) => item.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();

    categories.sort(
      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );

    return ['All', ...categories];
  }

  List<MenuItem> _filterAndSortItems(List<MenuItem> items) {
    final filteredItems = items.where((item) {
      final query = _searchQuery.trim().toLowerCase();

      final matchesSearch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);

      final matchesCategory = _selectedCategory == 'All' ||
          item.category.toLowerCase() ==
              _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();

    if (_sortBy == 'Price: Low to High') {
      filteredItems.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Price: High to Low') {
      filteredItems.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'Name: A to Z') {
      filteredItems.sort(
        (a, b) => a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            ),
      );
    }

    return filteredItems;
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = 'All';
      _sortBy = 'Recommended';
    });
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Restaurant Details'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          AnimatedBuilder(
            animation: CartService.instance,
            builder: (context, _) {
              final totalItems = CartService.instance.totalItems;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Badge(
                  label: Text('$totalItems'),
                  isLabelVisible: totalItems > 0,
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    tooltip: 'My Cart',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: restaurant.imageUrl.isNotEmpty
                ? Image.network(
                    restaurant.imageUrl,
                    height: 210,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _placeholder(height: 210),
                  )
                : _placeholder(height: 210),
          ),

          const SizedBox(height: 16),

          Text(
            restaurant.name,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            restaurant.cuisine,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
            ),
          ),

          if (restaurant.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              restaurant.description,
              style: const TextStyle(fontSize: 14),
            ),
          ],

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _infoRow(
                  Icons.star,
                  '${restaurant.rating} Rating',
                  Colors.orange,
                ),
                const Divider(height: 20),
                _infoRow(
                  Icons.delivery_dining,
                  '${restaurant.deliveryTime} min delivery',
                  Colors.deepOrange,
                ),
                const Divider(height: 20),
                _infoRow(
                  Icons.currency_rupee,
                  'Delivery fee: ₹${restaurant.deliveryFee.toStringAsFixed(2)}',
                  Colors.green,
                ),
                const Divider(height: 20),
                _infoRow(
                  Icons.circle,
                  restaurant.isOpen
                      ? 'Currently Open'
                      : 'Currently Closed',
                  restaurant.isOpen ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Our Menu',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // Search food by name, description or category.
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search food...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Colors.deepOrange,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Menu and filters.
          FutureBuilder<List<MenuItem>>(
            future: _menuFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Menu load nahi hua.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _retryMenu,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Abhi menu available nahi hai.\n'
                        'Please check back later.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }

              final categories = _getCategories(items);
              final filteredItems = _filterAndSortItems(items);

              // Keep selected category valid if menu data changes.
              if (!categories.contains(_selectedCategory)) {
                _selectedCategory = 'All';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final selected =
                            _selectedCategory == category;

                        return ChoiceChip(
                          label: Text(category),
                          selected: selected,
                          selectedColor: Colors.deepOrange,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${filteredItems.length} food item(s)',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DropdownButton<String>(
                        value: _sortBy,
                        isDense: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: 'Recommended',
                            child: Text('Recommended'),
                          ),
                          DropdownMenuItem(
                            value: 'Price: Low to High',
                            child: Text('Price: Low to High'),
                          ),
                          DropdownMenuItem(
                            value: 'Price: High to Low',
                            child: Text('Price: High to Low'),
                          ),
                          DropdownMenuItem(
                            value: 'Name: A to Z',
                            child: Text('Name: A to Z'),
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

                  if (_searchQuery.isNotEmpty ||
                      _selectedCategory != 'All' ||
                      _sortBy != 'Recommended')
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear filters'),
                      ),
                    ),

                  const SizedBox(height: 8),

                  if (filteredItems.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 42,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No food items found.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try another search or category.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear filters'),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredItems.map((item) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(12),
                                child: item.imageUrl.isNotEmpty
                                    ? Image.network(
                                        item.imageUrl,
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _placeholder(
                                          height: 90,
                                          width: 90,
                                        ),
                                      )
                                    : _placeholder(
                                        height: 90,
                                        width: 90,
                                      ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    Text(
                                      item.description.isEmpty
                                          ? item.category
                                          : item.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      '₹${item.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.deepOrange,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    if (item.isAvailable)
                                      SizedBox(
                                        height: 38,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            try {
                                              CartService.instance
                                                  .addItem(item);

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '${item.name} Added to cart!',
                                                  ),
                                                  duration:
                                                      const Duration(
                                                    seconds: 1,
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    e.toString()
                                                        .replaceFirst(
                                                      'Exception: ',
                                                      '',
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          style:
                                              ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.deepOrange,
                                            foregroundColor:
                                                Colors.white,
                                          ),
                                          child: const Text(
                                            'Add to Cart',
                                          ),
                                        ),
                                      ),

                                    if (!item.isAvailable)
                                      const Text(
                                        'Currently unavailable',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
          _buildReviewsSection(),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String text,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }

  Widget _placeholder({
    double height = 100,
    double width = double.infinity,
  }) {
    return Container(
      height: height,
      width: width,
      color: Colors.orange.shade50,
      child: const Icon(
        Icons.restaurant,
        size: 40,
        color: Colors.deepOrange,
      ),
    );
  }
}
