import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CategoryProductsTab extends StatelessWidget {
  final String categoryId;
  const CategoryProductsTab({required this.categoryId, super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    Stream<QuerySnapshot> productsStream;

    if (categoryId == 'all') {
      productsStream = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      productsStream = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('products')
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: productsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final products = snapshot.data!.docs;
        if (products.isEmpty) return const Center(child: Text("No products found"));

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final doc = products[index];
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              child: Column(
                children: [
                  Expanded(child: Image.network(data['imageUrl'], fit: BoxFit.cover)),
                  Text(data['name']),
                  Text("₹${data['price']}"),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
