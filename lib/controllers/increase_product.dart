import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addToCart(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return; // User not logged in

    final cartDoc = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(product.id);

    final docSnapshot = await cartDoc.get();
    if (docSnapshot.exists) {
      final currentQty = docSnapshot['quantity'] ?? 1;
      final newQty = currentQty + 1;
      final newTotalPrice = product.price * newQty;

      await cartDoc.update({
        'quantity': newQty,
        'totalPrice': newTotalPrice,
      });
    } else {
      await cartDoc.set({
        'name': product.name,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'quantity': 1,
        'totalPrice': product.price,
      });
    }
  }

  /// 🔹 Remove one quantity of product from user's cart
  Future<void> removeItem(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartDoc = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(product.id);

    final docSnapshot = await cartDoc.get();
    if (docSnapshot.exists) {
      final currentQty = docSnapshot['quantity'] ?? 1;

      if (currentQty > 1) {
        final newQty = currentQty - 1;
        final newTotalPrice = product.price * newQty;

        await cartDoc.update({
          'quantity': newQty,
          'totalPrice': newTotalPrice,
        });
      } else {
        // If quantity is 1, remove item completely
        await cartDoc.delete();
      }
    }
  }
}
