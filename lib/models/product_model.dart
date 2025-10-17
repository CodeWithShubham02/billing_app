import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  String? id;
  final String name;
  final String category;
  final double price;
  final int quantity;
  final String imageUrl;
  final DateTime createdAt;

  Product({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    this.quantity = 0,
    required this.imageUrl,
    required this.createdAt,
  });

  // Convert Product to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
    };
  }

  // Convert Firestore DocumentSnapshot to Product
  factory Product.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'],
      category: data['category'],
      price: (data['price'] as num).toDouble(),
      quantity: data['quantity'] ?? 0,
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
