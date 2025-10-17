import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utills/app_constant.dart';
import 'package:intl/intl.dart';

class BillsHistory extends StatefulWidget {
  const BillsHistory({super.key});

  @override
  State<BillsHistory> createState() => _BillsHistoryState();
}

class _BillsHistoryState extends State<BillsHistory> {
  DateTime? selectedDate;

  Future<void> _pickDate() async {
    DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? today,
      firstDate: DateTime(2020),
      lastDate: today,
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    String? selectedDateString;
    if (selectedDate != null) {
      selectedDateString = DateFormat('yyyy-MM-dd').format(selectedDate!);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstant.appBarColor,
        title: Text(
          "Bills History",
          style: TextStyle(color: AppConstant.appBarWhiteColor),
        ),
        actions: [
          IconButton(
            icon:  Icon(Icons.date_range,color: AppConstant.appBarWhiteColor,),
            onPressed: _pickDate,
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('bills')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No bills found"));
          }

          // Filter by selected date
          final bills = snapshot.data!.docs.where((doc) {
            if (selectedDateString == null) return true;
            final Timestamp timestamp = doc['createdAt'] as Timestamp;
            final billDate = timestamp.toDate();
            final billDateString = DateFormat('yyyy-MM-dd').format(billDate);
            return billDateString == selectedDateString;
          }).toList();

          if (bills.isEmpty) {
            return const Center(child: Text("No bills on selected date"));
          }

          return ListView.builder(
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              final Timestamp timestamp = bill['createdAt'] as Timestamp;
              final billDate = timestamp.toDate();
              final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(billDate);
              final totalAmount = bill['totalAmount'] ?? 0;
              final shopName = bill['shopName'] ?? "Shop";
              final shopPhone = bill['shopPhone'] ?? "N/A";
              final items = bill['items'] as List<dynamic>? ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ExpansionTile(
                  title: Text("Date : ${formattedDate}",style: TextStyle(fontSize: 12),),
                  trailing: Text(
                    "₹${totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Shop: $shopName"),
                          Text("Phone: $shopPhone"),
                          const SizedBox(height: 8),
                          const Text("Items:", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          ...items.map((item) {
                            final itemName = item['itemName'] ?? 'Unknown';
                            final quantity = item['quantity'] ?? 0;
                            final price = (item['itemPrice'] ?? 0).toDouble();
                            final itemTotal = (item['itemTotal'] ?? 0).toDouble();

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("$itemName ($quantity x ₹${price.toStringAsFixed(2)})"),
                                  Text("₹${itemTotal.toStringAsFixed(2)}"),
                                ],
                              ),
                            );
                          }).toList(),
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
