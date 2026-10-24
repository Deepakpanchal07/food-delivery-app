
import 'package:flutter/foundation.dart';
import '../../restaurants/models/menu_item.dart';

class CartEntry {
  final MenuItem item;
  int quantity;

  CartEntry({
    required this.item,
    this.quantity = 1,
  });

  double get total => item.price * quantity;
}

class CartService extends ChangeNotifier {
  CartService._();

  static final CartService instance = CartService._();

  final Map<String, CartEntry> _items = {};

  List<CartEntry> get items => _items.values.toList();

  int get totalItems =>
      _items.values.fold(0, (sum, entry) => sum + entry.quantity);

  double get subtotal =>
      _items.values.fold(0.0, (sum, entry) => sum + entry.total);

  void addItem(MenuItem item) {
    if (!item.isAvailable) return;


    if (_items.isNotEmpty &&
        _items.values.first.item.restaurantId != item.restaurantId) {
      throw Exception(
        'Ek time par ek hi restaurant se order kar sakte ho.',
      );
    }

    if (_items.containsKey(item.id)) {
      _items[item.id]!.quantity++;
    } else {
      _items[item.id] = CartEntry(item: item);
    }

    notifyListeners();
  }

  void decreaseQuantity(String itemId) {
    final entry = _items[itemId];
    if (entry == null) return;

    if (entry.quantity > 1) {
      entry.quantity--;
    } else {
      _items.remove(itemId);
    }

    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.remove(itemId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  int quantityOf(String itemId) => _items[itemId]?.quantity ?? 0;
}
