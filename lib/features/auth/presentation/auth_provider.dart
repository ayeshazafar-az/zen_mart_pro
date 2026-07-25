import 'dart:io';
import 'dart:convert';
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
        // Case 1: Nobody is logged in
        _currentUser = null;
        _resetAuthState();
        notifyListeners();
      } else if (!firebaseUser.emailVerified &&
          firebaseUser.email != 'admin@zenmart.com') {
        // Case 2: They are logged into Firebase, but HAVEN'T clicked the link.
        // We refuse to set _currentUser, which stops GoRouter from letting them in.
        // Exception made for Super Admin account.
        _currentUser = null;
        notifyListeners();
      } else {
        // Case 3: Logged in AND Verified (or Admin)! Let them through.
        await _fetchUserData(firebaseUser.uid);
      }
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

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

        if (data['email'] == 'admin@zenmart.com' ||
            _auth.currentUser?.email == 'admin@zenmart.com') {
          data['role'] = 'super_admin';
        }
        _currentUser = UserModel.fromMap(data, uid);
      } else {
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

  // UPDATED: Requires email verification to proceed, forces data reload, bypasses Admin
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      auth.UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await credential.user!.reload();
      final auth.User? refreshedUser = _auth.currentUser;

      // Fetch user data first to check role
      await _fetchUserData(credential.user!.uid);

      bool isAdmin = _currentUser?.role == 'super_admin' ||
          email.trim().toLowerCase() == 'admin@zenmart.com';
      bool isVendor = _currentUser?.role == AppConstants.roleVendor;

      // Strict Email Verification Check (Bypassed for Admin and Vendor)
      if (!isAdmin &&
          !isVendor &&
          refreshedUser != null &&
          !refreshedUser.emailVerified) {
        await _auth.signOut();
        _currentUser = null;
        _errorMessage =
            "Please verify your email address before logging in. Check your inbox.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

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

  // UPDATED: Customers auto-approved, everyone else pending
  Future<bool> signUpWithDetails({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Create auth account
      auth.UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // 2. Send verification email immediately
      await credential.user!.sendEmailVerification();

      // 3. Determine Approval Status: ONLY customers are instantly approved
      bool isApproved = role == 'customer' ? true : false;

      // 4. Save comprehensive data to Firestore
      Map<String, dynamic> userData = {
        'uid': credential.user!.uid,
        'email': email.trim(),
        'name': name.trim(),
        'phone': phoneNumber.trim(),
        'role': role,
        'isApproved': isApproved,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .set(userData);

      // 5. Sign out so they cannot access the app until email is verified
      await _auth.signOut();
      _currentUser = null;

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

  Future<bool> signUpRider({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String address,
    required String city,
    required String vehicleType,
    required String bankName,
    required File profileImage,
    required File drivingLicense,
    required File vehicleImage,
    required File cnicFront,
    required File cnicBack,
    required File paymentReceipt,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Create auth account
      auth.UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user!.uid;

      // 2. Base64 Encode heavily compressed images for Firestore Storage
      Future<String> uploadImage(File file, String path) async {
        try {
          final bytes = await file.readAsBytes();
          final base64String = base64Encode(bytes);
          return base64String;
        } catch (e) {
          throw Exception('Failed to process image $path: $e');
        }
      }

      final profileImageUrl =
          await uploadImage(profileImage, 'profile_image.jpg');
      final drivingLicenseUrl =
          await uploadImage(drivingLicense, 'driving_license.jpg');
      final vehicleImageUrl = await uploadImage(vehicleImage, 'vehicle.jpg');
      final cnicFrontUrl = await uploadImage(cnicFront, 'cnic_front.jpg');
      final cnicBackUrl = await uploadImage(cnicBack, 'cnic_back.jpg');
      final paymentReceiptUrl =
          await uploadImage(paymentReceipt, 'payment_receipt.jpg');

      // 3. Save comprehensive data to Firestore
      Map<String, dynamic> userData = {
        'uid': uid,
        'email': email.trim(),
        'name': name.trim(),
        'phone': phoneNumber.trim(),
        'role': 'rider',
        'isApproved': false,
        'address': address.trim(),
        'city': city.trim(),
        'vehicleType': vehicleType,
        'bankName': bankName,
        'profileImageUrl': profileImageUrl,
        'drivingLicenseUrl': drivingLicenseUrl,
        'vehicleImageUrl': vehicleImageUrl,
        'cnicFrontUrl': cnicFrontUrl,
        'cnicBackUrl': cnicBackUrl,
        'paymentReceiptUrl': paymentReceiptUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(userData);

      // 4. Send verification email immediately
      await credential.user!.sendEmailVerification();

      // 5. Sign out so they cannot access the app until email is verified and approved
      await _auth.signOut();
      _currentUser = null;

      _isLoading = false;
      notifyListeners();
      return true;
    } on auth.FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? "An error occurred during rider sign up.";
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (_auth.currentUser != null &&
          _auth.currentUser!.email == email.trim()) {
        try {
          await _auth.currentUser!.delete();
        } catch (_) {}
      }
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

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception("User not logged in");
      }

      // Re-authenticate
      auth.AuthCredential credential = auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } on auth.FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? "Failed to update password.";
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

  Future<bool> updateUserProfile(
      {required String name, required String phone, String? photoUrl}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = _auth.currentUser;
      if (user == null || _currentUser == null) {
        throw Exception("User not logged in");
      }

      final updates = <String, dynamic>{
        'name': name.trim(),
        'phone': phone.trim(),
      };
      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
      }

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update(updates);

      // Refresh local user data
      await _fetchUserData(user.uid);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // NOTE: Phone Auth methods remain intact in case you want to use them for 2FA or Password Resets later.
  Future<void> verifyPhoneNumber(
      String phoneNumber, Function(String) onCodeSent) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        verificationCompleted: (auth.PhoneAuthCredential credential) async {
          auth.UserCredential userCredential =
              await _auth.signInWithCredential(credential);
          await _checkAndCreatePhoneUser(userCredential.user!);

          _resetAuthState();
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

      auth.UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      await _checkAndCreatePhoneUser(userCredential.user!);

      _resetAuthState();
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

  Future<void> _checkAndCreatePhoneUser(auth.User firebaseUser) async {
    DocumentSnapshot doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists) {
      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: '',
        name: 'Zen User',
        role: AppConstants.roleCustomer,
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
    _resetAuthState();
    notifyListeners();
  }
}
