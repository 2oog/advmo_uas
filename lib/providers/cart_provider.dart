import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});

  int get subtotal => menuItem.price * quantity;
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get count => _items.fold(0, (sum, item) => sum + item.quantity);

  int get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);

  int get tax => (subtotal * 0.1).round();

  int get total => subtotal + tax;

  void addToCart(MenuItem menuItem, int quantity) {
    if (quantity <= 0) return;

    // Check if item already exists
    try {
      final existingItem = _items.firstWhere(
        (item) => item.menuItem.id == menuItem.id,
      );
      existingItem.quantity += quantity;
    } catch (e) {
      // Not found, add new
      _items.add(CartItem(menuItem: menuItem, quantity: quantity));
    }
    notifyListeners();
  }

  void removeFromCart(int menuItemId) {
    _items.removeWhere((item) => item.menuItem.id == menuItemId);
    notifyListeners();
  }

  void updateQuantity(int menuItemId, int delta) {
    try {
      final item = _items.firstWhere((item) => item.menuItem.id == menuItemId);
      item.quantity += delta;
      if (item.quantity <= 0) {
        removeFromCart(menuItemId);
      } else {
        notifyListeners();
      }
    } catch (e) {
      // Item not found, ignore
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
