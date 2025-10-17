import 'package:billing_application/views/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Get Device Token (FCM)
  Future<String> _getDeviceToken() async {
    try {
      return await FirebaseMessaging.instance.getToken() ?? '';
    } catch (e) {
      print("Error getting device token: $e");
      return '';
    }
  }

  // 🔹 Get Current Location
  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print("Location error: $e");
      return null;
    }
  }


  // 🔹 Register New User
  Future<String> registerUser({
    required String shopName,
    required String email,
    required String password,
    required String mobile,
  }) async {
    try {
      // 1️⃣ Create user in Firebase Auth
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 2️⃣ Get device token
      final token = await _getDeviceToken();

      // 3️⃣ Get current location
      final pos = await _getCurrentLocation();

      // 4️⃣ Create user model
      UserModel user = UserModel(
        uid: uid,
        shopName: shopName,
        email: email,
        mobile: mobile,
        deviceToken: token,
        latitude:pos?.latitude ?? 0.0,
        longitude: pos?.longitude ?? 0.0,
        status: 'active',
        createdAt: DateTime.now(),
      );

      // 5️⃣ Save user to Firestore
      await _firestore.collection('users').doc(uid).set(user.toMap());

      // 6️⃣ Navigate to HomeScreen
      Get.offAll(() => const HomeScreen(),
          transition: Transition.fadeIn, duration: const Duration(milliseconds: 500));

      return "User Registered Successfully ✅";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        return 'Your password is too weak.';
      } else if (e.code == 'invalid-email') {
        return 'Please enter a valid email.';
      } else {
        return 'FirebaseAuth Error: ${e.message}';
      }
    } catch (e) {
      print("Register Error: $e");
      return "Unexpected error occurred: ${e.toString()}";
    }
  }

  // 🔹 Login Existing User
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // 1️⃣ Sign in with Firebase Auth
      UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final uid = userCredential.user!.uid;

      // 2️⃣ Get new device token and location (update in Firestore)
      final token = await _getDeviceToken();
      final pos = await _getCurrentLocation();

      await _firestore.collection('users').doc(uid).update({
        'deviceToken': token,
        'latitude':pos?.latitude ?? 0.0,
        'longitude': pos?.longitude ?? 0.0,
        'status': 'active',
      });

      // 3️⃣ Navigate to HomeScreen
      Get.offAll(() => const HomeScreen(),
          transition: Transition.fadeIn, duration: const Duration(milliseconds: 500));

      return "Login Successful ✅";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Invalid password. Please try again.';
      } else {
        return 'FirebaseAuth Error: ${e.message}';
      }
    } catch (e) {
      print("Login Error: $e");
      return "Unexpected error occurred: ${e.toString()}";
    }
  }

  // 🔹 Logout User
  Future<void> logoutUser() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
  }
}
