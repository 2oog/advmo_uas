import '../services/api_service.dart';

class MenuItem {
  final int id;
  final String name;
  final int price;
  final String? imageAsset;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    this.imageAsset,
    required this.createdAt,
    required this.updatedAt,
  });

  String? get imageUrl {
    if (imageAsset == null) return null;
    String asset = imageAsset!;
    if (asset.startsWith('/')) {
      asset = asset.substring(1);
    }
    return '${ApiService.imageBaseUrl}/$asset';
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as int,
      name: json['name'] as String,
      price: json['price'] as int,
      imageAsset: json['image_asset'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image_asset': imageAsset,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
