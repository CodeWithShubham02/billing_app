import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/increase_product.dart';
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

  String category = 'Sandwich';
  File? _image;
  bool _isLoading = false;

  final List<String> categories = ['Sandwich', 'Sevpuri', 'Panipuri','Burger',
  'Pizza',
  'Fries',
  'Hot Dog',
  'Taco',
  'Nuggets',
  'Wrap',
  'Pasta',
  'Dosa',
  'Idli',
  'Vada Pav',
  'Spring Roll'];

  Future<void> pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> saveProduct() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());

    if (name.isEmpty || price == null || _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select an image')),
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
      category: category,
      price: price,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    final success = await _controller.addProduct(product);

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Product added successfully')));
      _nameController.clear();
      _priceController.clear();
      setState(() => _image = null);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to add product')));
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
            DropdownButtonFormField(
              value: category,
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => category = value.toString()),
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
                  : Image.file(_image!, height: 150, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: saveProduct, child: const Text('Add Product')),
          ],
        ),
      ),
    );
  }
}
