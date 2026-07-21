import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/user_model.dart';
import '../../../core/constants/app_constants.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchUserData(User firebaseUser) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists) {
        _currentUser = AppUser.fromMap(doc.data() as Map<String, dynamic>, firebaseUser.uid);
      } else {
        _currentUser = AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: 'User',
          role: 'customer',
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await fetchUserData(credential.user!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Login Error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}