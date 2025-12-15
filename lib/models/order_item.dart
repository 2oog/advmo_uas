class OrderItem {
  final int id;
  final int orderId;
  final int menuItemId;
  final String menuName;
  final int quantity;
  final int priceAtTime;
  final int subtotal;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.menuName,
    required this.quantity,
    required this.priceAtTime,
    required this.subtotal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      menuItemId: json['menu_item_id'] as int,
      menuName: json['menu_name'] as String,
      quantity: json['quantity'] as int,
      priceAtTime: json['price_at_time'] as int,
      subtotal: json['subtotal'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'menu_item_id': menuItemId,
      'menu_name': menuName,
      'quantity': quantity,
      'price_at_time': priceAtTime,
      'subtotal': subtotal,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
