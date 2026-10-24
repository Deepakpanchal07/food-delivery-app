
import 'package:flutter/material.dart';
import 'package:frontend/features/restaurants/models/menu_item.dart';
import 'package:frontend/features/restaurants/models/restaurant.dart';
import 'package:frontend/features/restaurants/screens/add_food_screen.dart';
import 'package:frontend/features/restaurants/services/menu_service.dart';
import 'package:frontend/features/restaurants/services/restaurant_service.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  final MenuService _menuService = MenuService();

  List<Restaurant> _restaurants = [];
  List<MenuItem> _menuItems = [];

  String? _selectedRestaurantId;
  bool _loadingRestaurants = true;
  bool _loadingMenu = false;
  bool _saving = false;

  static const Color _orange = Color(0xFFFF6B35);

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    try {
      final restaurants = await _restaurantService.getRestaurants();

      if (!mounted) return;

      setState(() {
        _restaurants = restaurants;
        _loadingRestaurants = false;

        if (restaurants.isNotEmpty) {
          _selectedRestaurantId = restaurants.first.id;
        }
      });

      if (_selectedRestaurantId != null) {
        await _loadMenu(_selectedRestaurantId!);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingRestaurants = false);
      _showMessage('Failed to load restaurants: $e');
    }
  }

  Future<void> _loadMenu(String restaurantId) async {
    setState(() {
      _loadingMenu = true;
      _menuItems = [];
    });

    try {
      final items = await _menuService.getMenu(restaurantId);

      if (!mounted) return;

      setState(() {
        _menuItems = items;
        _loadingMenu = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingMenu = false);
      _showMessage('Failed to load menu: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _addFood() async {
    final restaurantId = _selectedRestaurantId;

    if (restaurantId == null) {
      _showMessage('Please select a restaurant first.');
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddFoodScreen(
          restaurantId: restaurantId,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadMenu(restaurantId);
    }
  }

  Future<void> _editFood(MenuItem item) async {
    final nameController = TextEditingController(text: item.name);
    final descriptionController =
        TextEditingController(text: item.description);
    final priceController =
        TextEditingController(text: item.price.toString());
    final imageController = TextEditingController(text: item.imageUrl);

    final categories = [
      'Fast Food',
      'Pizza',
      'Burger',
      'Indian',
      'Chinese',
      'Drinks',
      'Dessert',
      'Main Course',
    ];

    String selectedCategory = categories.contains(item.category)
        ? item.category
        : 'Main Course';

    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Food Item'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Food Name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter food name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      TextFormField(
                        controller: priceController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Price (₹)',
                        ),
                        validator: (value) {
                          final price = double.tryParse(value ?? '');

                          if (price == null || price < 0) {
                            return 'Enter a valid price';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: imageController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true || !mounted) {
      nameController.dispose();
      descriptionController.dispose();
      priceController.dispose();
      imageController.dispose();
      return;
    }

    setState(() => _saving = true);

    try {
      await _menuService.updateMenuItem(
        id: item.id,
        name: nameController.text,
        description: descriptionController.text,
        price: double.parse(priceController.text),
        imageUrl: imageController.text,
        category: selectedCategory,
      );

      if (!mounted) return;

      _showMessage('Food item updated successfully!');
      await _loadMenu(_selectedRestaurantId!);
    } catch (e) {
      _showMessage('Update failed: $e');
    } finally {
      nameController.dispose();
      descriptionController.dispose();
      priceController.dispose();
      imageController.dispose();

      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteFood(MenuItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Food Item?'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _saving = true);

    try {
      await _menuService.deleteMenuItem(item.id);

      if (!mounted) return;

      _showMessage('Food item deleted successfully!');
      await _loadMenu(_selectedRestaurantId!);
    } catch (e) {
      _showMessage('Delete failed: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _toggleAvailability(MenuItem item) async {
    setState(() => _saving = true);

    try {
      await _menuService.updateAvailability(
        id: item.id,
        isAvailable: !item.isAvailable,
      );

      if (!mounted) return;

      _showMessage(
        item.isAvailable
            ? 'Food marked unavailable'
            : 'Food marked available',
      );

      await _loadMenu(_selectedRestaurantId!);
    } catch (e) {
      _showMessage('Availability update failed: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        backgroundColor: _orange,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving || _selectedRestaurantId == null
            ? null
            : _addFood,
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Food'),
      ),
      body: _loadingRestaurants
          ? const Center(child: CircularProgressIndicator())
          : _restaurants.isEmpty
              ? const Center(
                  child: Text('No restaurants found. Add a restaurant first.'),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<String>(
                        value: _selectedRestaurantId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Select Restaurant',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _restaurants.map((restaurant) {
                          return DropdownMenuItem<String>(
                            value: restaurant.id,
                            child: Text(
                              restaurant.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _saving
                            ? null
                            : (restaurantId) async {
                                if (restaurantId == null) return;

                                setState(() {
                                  _selectedRestaurantId = restaurantId;
                                });

                                await _loadMenu(restaurantId);
                              },
                      ),
                    ),
                    Expanded(
                      child: _loadingMenu
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : _menuItems.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No food items found for this restaurant.',
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: () => _loadMenu(
                                    _selectedRestaurantId!,
                                  ),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      0,
                                      12,
                                      90,
                                    ),
                                    itemCount: _menuItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _menuItems[index];

                                      return Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: item.imageUrl.isNotEmpty
                                                    ? Image.network(
                                                        item.imageUrl,
                                                        width: 76,
                                                        height: 76,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return _foodPlaceholder();
                                                        },
                                                      )
                                                    : _foodPlaceholder(),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.name,
                                                      style:
                                                          const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      item.category,
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '₹${item.price.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    if (item.description
                                                        .isNotEmpty)
                                                      Text(
                                                        item.description,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          item.isAvailable
                                                              ? Icons
                                                                  .check_circle
                                                              : Icons
                                                                  .cancel,
                                                          size: 16,
                                                          color:
                                                              item.isAvailable
                                                                  ? Colors.green
                                                                  : Colors.red,
                                                        ),
                                                        const SizedBox(
                                                          width: 5,
                                                        ),
                                                        Text(
                                                          item.isAvailable
                                                              ? 'Available'
                                                              : 'Unavailable',
                                                          style: TextStyle(
                                                            color:
                                                                item.isAvailable
                                                                    ? Colors.green
                                                                    : Colors.red,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuButton<String>(
                                                enabled: !_saving,
                                                onSelected: (value) {
                                                  if (value == 'edit') {
                                                    _editFood(item);
                                                  } else if (value ==
                                                      'availability') {
                                                    _toggleAvailability(item);
                                                  } else if (value == 'delete') {
                                                    _deleteFood(item);
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit),
                                                        SizedBox(width: 8),
                                                        Text('Edit'),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'availability',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          item.isAvailable
                                                              ? Icons
                                                                  .visibility_off
                                                              : Icons.visibility,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          item.isAvailable
                                                              ? 'Mark Unavailable'
                                                              : 'Mark Available',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('Delete'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    ),
                    if (_saving) const LinearProgressIndicator(),
                  ],
                ),
    );
  }

  Widget _foodPlaceholder() {
    return Container(
      width: 76,
      height: 76,
      color: Colors.orange.shade50,
      alignment: Alignment.center,
      child: const Icon(
        Icons.fastfood,
        color: _orange,
        size: 32,
      ),
    );
  }
}
