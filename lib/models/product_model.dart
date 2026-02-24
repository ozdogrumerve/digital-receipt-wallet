class ProductModel {
  final String id;
  final String name;
  final double price;
  final int quantity;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }
}