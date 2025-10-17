import 'dart:math';

import 'package:billing_application/utills/app_constant.dart';
import 'package:billing_application/views/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/fetch_product_controller.dart';
import '../controllers/increase_product.dart';
import '../models/product_model.dart';
import '../widgets/drawer_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _authController = AuthController();
  final ProductController _productController = ProductController();
  final CartService _cartService = CartService();

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Get.offAll(() => const LoginScreen());
              await _authController.logoutUser();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
  Future<String> getAddressFromLatLong(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // You can customize which parts you want to show
        return "${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea}";
      } else {
        return "Unknown Location";
      }
    } catch (e) {
      print("Error in reverse geocoding: $e");
      return "Unknown Location";
    }
  }


  Future<void> _generateBill(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      // 1. 🌐 Fetch Shop Details from Firestore (using the user's ID)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User details not found!')),
        );
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      final String shopName = userData['shopName'] ?? 'Unnamed Shop';
      final String shopPhone = userData['mobile'] ?? 'N/A';
      final shopLatValue = userData['latitude'];
      final String shopLat = shopLatValue is num ? shopLatValue.toString() : '0.0';
      final shopLongValue = userData['longitude'];
      final String shopLong = shopLongValue is num ? shopLongValue.toString() : '0.0';
      final random = Random();

      // 2. Define the range (10 to 99)
      const min = 10;
      const max = 100; // nextInt() is exclusive of the upper bound, so we use 100 for 99

      // 3. Generate a random integer within the range: [min, max)
      final twoDigitNumber = random.nextInt(max - min) + min;
      String shopLocation = "Unknown Location";
      if (shopLat is num && shopLong is num) {
        shopLocation = await getAddressFromLatLong(shopLat as double, shopLong as double);
      }
      print("----------------");
      print(shopLocation);
      print("------------------");
      // Current date and time
      final String currentDateTime = DateTime.now().toString().substring(0, 16);


      // 2. 🛒 Fetch Cart Items
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      if (cartSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart is empty!')),
        );
        return;
      }

      double totalAmount = 0;
      List<Map<String, dynamic>> items = [];

      for (var doc in cartSnapshot.docs) {
        final data = doc.data();
        final itemName = data['itemName'] ?? data['name'] ?? 'Unknown';
        final itemPrice = (data['price'] ?? 0).toDouble();
        final quantity = (data['quantity'] ?? 0).toInt();
        final itemTotal = itemPrice * quantity;

        totalAmount += itemTotal;

        items.add({
          'itemName': itemName,
          'quantity': quantity,
          'itemPrice': itemPrice,
          'itemTotal': itemTotal,
        });
      }

      // 🧾 Optional: Save bill in Firestore (for history)
      final billData = {
        'items': items,
        'totalAmount': totalAmount,
        'createdAt': FieldValue.serverTimestamp(),
        // Shop details can also be saved in the bill history
        'shopName': shopName,
        'shopPhone': shopPhone,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bills')
          .add(billData);

      // 3. ✅ Show Bill in Dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. 🖼 Logo & Shop Name (Top Center)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0,left: 8.0,right: 8.0),
                  child: Center(
                    child: Column(
                      children: [
                        // Replace with your actual logo Image.network or Image.asset
                        Icon(Icons.store, size: 48, color: AppConstant.appMainColor),
                        const SizedBox(height: 5),
                        // Dynamically fetched Shop Name
                        Center(
                            child: Text(
                              shopName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(thickness: 1, indent: 16, endIndent: 16),

                // 2. 📞 Contact & LatLong & DateTime Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dynamically fetched DateTime
                      Text("Date/Time: $currentDateTime",
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      // Dynamically fetched Phone Number
                      Text("Phone: $shopPhone",
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      // Dynamically fetched LatLong
                      Text("Address: $shopLocation",
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),


                Padding(
                  padding:  EdgeInsets.all(8.0),
                  child: Text(
                    "*** Bill No - $twoDigitNumber ***",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Divider(thickness: 1, indent: 16, endIndent: 16),
                // 3. 🛒 Bill Items (List View)
                // 3. 🛒 Bill Items (Table Format with Dashed Line Effect)

// ➡️ Header Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      // Item Name and Qty Column
                      Expanded(
                        flex: 3,
                        child: Text(
                          "ITEM NAME (QTY x PRICE)",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      // Total Column
                      Expanded(
                        flex: 1,
                        child: Text(
                          "TOTAL",
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

// ➖ Dashed Line Separator (using text)

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "--------------------------------------------------",
                    style: TextStyle(fontSize: 10, height: 0.5),
                    maxLines: 1,
                  ),
                ),

// ➡️ Items List
                ...items.map((item) {
                  // item['itemPrice'] और item['itemTotal'] को double मानते हुए
                  final String price = item['itemPrice'].toStringAsFixed(2);
                  final String total = item['itemTotal'].toStringAsFixed(2);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Details Column (Item Name, Qty, Price)
                        Expanded(
                          flex: 3,
                          child: Text(
                            // Format: Product Name (3x @ ₹100.00)
                            "${item['itemName']} (${item['quantity']}x @ ₹$price)",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        // Total Amount Column
                        Expanded(
                          flex: 1,
                          child: Text(
                            "₹$total",
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

// ➖ Dashed Line Separator before Total
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Text(
                    "--------------------------------------------------",
                    style: TextStyle(fontSize: 10, height: 0.5),
                    maxLines: 1,
                  ),
                ),

                const Divider(thickness: 2, indent: 16, endIndent: 16, height: 20),

                // 4. 💰 Total Amount
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    "TOTAL AMOUNT: ₹${totalAmount.toStringAsFixed(2)}",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppConstant.appMainColor,
                    ),
                  ),
                ),


                const Divider(thickness: 1, indent: 16, endIndent: 16),

                // 5. 🙏 Thank You Message (Bottom Center)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    " Thank You !!! Visit Us Again ",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating bill: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: AppConstant.appBarWhiteColor),
        backgroundColor: AppConstant.appBarColor,
        title: Text(
          "Billing App",
          style: TextStyle(color: AppConstant.appBarWhiteColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: AppConstant.appBarWhiteColor),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      drawer: AdminDrawerWidget(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppConstant.appMainColor,
        onPressed: () async {
          await _generateBill(context);
        },
        child: const Icon(Icons.print, color: Colors.white),
      ),
      body: StreamBuilder<List<Product>>(
        stream: _productController.getUserProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No products found"));
          }

          final products = snapshot.data!;

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
              final product = products[index];

              return Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor: Colors.grey.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🖼 Product Image
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // 🧾 Product Info + Buttons
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Product Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "₹${product.price.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 6),

                          // 🔄 Quantity Controls
                          Flexible(
                            child: StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .collection('cart')
                                  .doc(product.id)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                int quantity = 0;
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final data = snapshot.data!.data() as Map<String, dynamic>;
                                  quantity = data['quantity'] ?? 0;
                                }
                                return Container(
                                  height: 28, // smaller height
                                  constraints: const BoxConstraints(minWidth: 70), // optional min width
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // ➖ Remove button
                                      if (quantity > 0)
                                        SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: IconButton(
                                            icon: const Icon(Icons.remove, size: 14),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () async {
                                              await _cartService.removeItem(product);
                                            },
                                          ),
                                        ),

                                      // 🔢 Quantity text
                                      if (quantity > 0)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 3),
                                          child: Text(
                                            "$quantity",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: AppConstant.appMainColor,
                                            ),
                                          ),
                                        ),

                                      // ➕ Add button
                                      SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: IconButton(
                                          icon: const Icon(Icons.add, color: Colors.redAccent, size: 14),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () async {
                                            await _cartService.addToCart(product);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
