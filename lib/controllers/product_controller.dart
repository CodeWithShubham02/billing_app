import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

import '../models/product_model.dart';

class ProductController {
  final cloudinary = CloudinaryPublic('dg2rc53o1', 'iwa9d1st', cache: false);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload image to Cloudinary
  Future<String?> uploadImage(File imageFile, String productName) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, folder: productName),
      );
      return response.secureUrl;
    } catch (e) {
      print('Cloudinary upload failed: $e');
      return null;
    }
  }

  // Save Product to Firestore
  Future<bool> addProduct(Product product) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('products')
          .add(product.toMap());

      return true;
    } catch (e) {
      print('Error saving product: $e');
      return false;
    }
  }
}
