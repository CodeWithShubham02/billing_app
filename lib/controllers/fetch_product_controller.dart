import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class ProductController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch all products of current user
  Stream<List<Product>> getUserProducts() {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('products')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList());
  }


}
