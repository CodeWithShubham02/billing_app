import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final ProductController _controller = ProductController();

  File? _image;
  bool _isLoading = false;

  // 🔹 Category data from Firestore
  List<Map<String, dynamic>> categories = [];
  String? selectedCategoryId;
  String? selectedCategoryName;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  // 🔹 Fetch categories from Firestore
  Future<void> fetchCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('category')
        .orderBy('createdAt', descending: false)
        .get();

    setState(() {
      categories = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'categoryId': data['categoryId'] ?? doc.id,
          'categoryName': data['categoryName'] ?? 'Unnamed',
        };
      }).toList();

      if (categories.isNotEmpty) {
        selectedCategoryId = categories.first['categoryId'];
        selectedCategoryName = categories.first['categoryName'];
      }
    });
  }

  // 🔹 Pick image from gallery
  Future<void> pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  // 🔹 Save product to Firestore
  Future<void> saveProduct() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());

    if (name.isEmpty ||
        price == null ||
        _image == null ||
        selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text('Please fill all fields, select category, and choose image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final imageUrl = await _controller.uploadImage(_image!, name);

    if (imageUrl == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Image upload failed')));
      return;
    }

    final product = Product(
      name: name,
      price: price,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      categoryId: selectedCategoryId ?? '',
      categoryName: selectedCategoryName ?? '', id: '',
    );

    final userId = FirebaseAuth.instance.currentUser!.uid;

    // 🔹 Store product with categoryId and categoryName
    final success = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('products')
        .add({
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'categoryId': selectedCategoryId,
      'categoryName': selectedCategoryName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() => _isLoading = false);

    if (success.id.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );
      _nameController.clear();
      _priceController.clear();
      setState(() {
        _image = null;
        selectedCategoryId = categories.isNotEmpty ? categories.first['categoryId'] : null;
        selectedCategoryName = categories.isNotEmpty ? categories.first['categoryName'] : null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add product')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            const SizedBox(height: 10),
            categories.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
              value: selectedCategoryId,
              items: categories
                  .map((c) => DropdownMenuItem<String>(
                value: c['categoryId'],
                child: Text(c['categoryName']),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategoryId = value;
                  selectedCategoryName = categories
                      .firstWhere((c) => c['categoryId'] == value)['categoryName'];
                });
              },
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: pickImage,
              child: _image == null
                  ? Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[300],
                child: const Icon(Icons.add_a_photo, size: 50),
              )
                  : Image.file(
                _image!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: saveProduct,
              child: const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}
