import 'package:billing_application/views/home_screen.dart';
import 'package:billing_application/views/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BillMate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Checking connection state
          if (snapshot.connectionState == ConnectionState.active) {
            User? user = snapshot.data;

            // ✅ User is logged in
            if (user != null) {
              // Check Firestore status
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get(),
                builder: (context, statusSnapshot) {
                  if (statusSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!statusSnapshot.hasData || !statusSnapshot.data!.exists) {
                    // User doc not found → logout
                    FirebaseAuth.instance.signOut();
                    return const LoginScreen();
                  }

                  final userData = statusSnapshot.data!.data() as Map<String, dynamic>;
                  final status = (userData['status'] ?? 'inactive').toString().toLowerCase();

                  if (status == 'active') {
                    return const HomeScreen();
                  } else {
                    // Inactive user → logout and show login screen
                    FirebaseAuth.instance.signOut();
                    return const LoginScreen();
                  }
                },
              );
            } else {
              // ❌ User not logged in
              return const LoginScreen();
            }
          }

          // While checking auth state
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
