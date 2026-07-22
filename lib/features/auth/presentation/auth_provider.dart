import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../data/user_model.dart';

class AuthProvider with ChangeNotifier {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _verificationId;
  bool _codeSent = false;
  bool get codeSent => _codeSent;

  AuthProvider() {
    _initAuthListener();
  }

  // Listens to Firebase Auth state changes globally
  void _initAuthListener() {
    _auth.authStateChanges().listen((auth.User? firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        _resetAuthState(); // Clear sensitive states on logout
        notifyListeners();
      } else {
        await _fetchUserData(firebaseUser.uid);
      }
    });
  }

  // Helper to clear errors manually from UI if needed
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Internal helper to reset OTP states
  void _resetAuthState() {
    _codeSent = false;
    _verificationId = null;
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        // Super Admin Bootstrap Logic
        if (data['email'] == 'admin@zenmart.com' || _auth.currentUser?.email == 'admin@zenmart.com') {
          data['role'] = 'super_admin';
        }
        _currentUser = UserModel.fromMap(data, uid);
      } else {
        // Fallback if document is somehow missing
        if (_auth.currentUser?.email == 'admin@zenmart.com') {
          _currentUser = UserModel(
            uid: uid,
            email: 'admin@zenmart.com',
            name: 'Super Admin',
            role: 'super_admin',
          );
        } else {
          _currentUser = UserModel(
            uid: uid,
            email: _auth.currentUser?.email ?? '',
            name: 'Zen User',
            role: AppConstants.roleCustomer,
          );
        }
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      auth.UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await _fetchUserData(credential.user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } on auth.FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? "An error occurred during login.";
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name, String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      auth.UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final newUser = UserModel(
        uid: credential.user!.uid,
        email: email.trim(),
        name: name.trim(),
        role: role,
      );

      // Create user document in Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .set(newUser.toMap());

      _currentUser = newUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } on auth.FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? "An error occurred during sign up.";
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } on auth.FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? "Failed to send reset email.";
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> verifyPhoneNumber(String phoneNumber, Function(String) onCodeSent) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        // Triggered automatically on some Android devices that can read the incoming SMS
        verificationCompleted: (auth.PhoneAuthCredential credential) async {
          auth.UserCredential userCredential = await _auth.signInWithCredential(credential);
          await _checkAndCreatePhoneUser(userCredential.user!);

          _resetAuthState(); // Reset so it doesn't hang on OTP screen
          _isLoading = false;
          notifyListeners();
        },
        verificationFailed: (auth.FirebaseAuthException e) {
          _errorMessage = e.message ?? "Phone verification failed.";
          _isLoading = false;
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _codeSent = true;
          _isLoading = false;
          notifyListeners();
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOTP(String smsCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_verificationId == null) throw Exception('Verification ID is null');

      auth.PhoneAuthCredential credential = auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode.trim(),
      );

      auth.UserCredential userCredential = await _auth.signInWithCredential(credential);
      await _checkAndCreatePhoneUser(userCredential.user!);

      _resetAuthState(); // Crucial: clear OTP states upon successful login
      _isLoading = false;
      notifyListeners();
      return true;
    } on auth.FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? "Invalid OTP code provided.";
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Helper method to ensure Phone Auth users get a Firestore document
  Future<void> _checkAndCreatePhoneUser(auth.User firebaseUser) async {
    DocumentSnapshot doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists) {
      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: '',
        name: 'Zen User', // Default name for phone auth users
        role: AppConstants.roleCustomer, // Default to customer
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set(newUser.toMap());
    }

    await _fetchUserData(firebaseUser.uid);
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    _resetAuthState(); // Clean up states immediately
    notifyListeners();
  }
}