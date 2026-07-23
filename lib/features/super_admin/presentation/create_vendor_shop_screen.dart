import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class CreateVendorShopScreen extends StatefulWidget {
  const CreateVendorShopScreen({super.key});

  @override
  State<CreateVendorShopScreen> createState() => _CreateVendorShopScreenState();
}

class _CreateVendorShopScreenState extends State<CreateVendorShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Vendor Controllers
  final _vendorNameController = TextEditingController();
  final _vendorEmailController = TextEditingController();
  final _vendorPhoneController = TextEditingController(text: '+92');
  final _vendorPasswordController = TextEditingController();

  // Shop Controllers
  final _shopNameController = TextEditingController();
  final _shopDescController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _vendorNameController.dispose();
    _vendorEmailController.dispose();
    _vendorPhoneController.dispose();
    _vendorPasswordController.dispose();
    _shopNameController.dispose();
    _shopDescController.dispose();
    super.dispose();
  }

  Future<void> _createVendorAndShop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    FirebaseApp? tempApp;
    try {
      // 1. Initialize a temporary Firebase App to prevent logging out the Admin
      tempApp = await Firebase.initializeApp(
        name: 'tempVendorCreator',
        options: Firebase.app().options,
      );

      // 2. Create the Vendor Auth Account
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
        email: _vendorEmailController.text.trim(),
        password: _vendorPasswordController.text.trim(),
      );

      final String vendorUid = userCredential.user!.uid;

      // 3. Create Vendor User Document in Firestore
      await _firestore.collection(AppConstants.usersCollection).doc(vendorUid).set({
        'uid': vendorUid,
        'email': _vendorEmailController.text.trim(),
        'name': _vendorNameController.text.trim(),
        'phone': _vendorPhoneController.text.trim(),
        'role': AppConstants.roleVendor,
        'isApproved': true, // Admin explicitly creating them, so auto-approved
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Create Shop Document and assign Vendor UID
      await _firestore.collection(AppConstants.shopsCollection).add({
        'vendorUid': vendorUid,
        'name': _shopNameController.text.trim(),
        'description': _shopDescController.text.trim(),
        'isActive': true,
        'bannerUrl': '', // Vendor can update this later
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vendor & Shop created successfully! Credentials ready to share.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context); // Go back to Admin Dashboard
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Auth Error'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // 5. Destroy the temporary app so it doesn't leak memory
      await tempApp?.delete();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Vendor & Shop')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vendor Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _vendorNameController,
                decoration: const InputDecoration(labelText: 'Vendor Name', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _vendorEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Vendor Email', border: OutlineInputBorder()),
                validator: (val) => val == null || !val.contains('@') ? 'Invalid Email' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _vendorPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                validator: (val) => val == null || val.length < 10 ? 'Invalid Phone' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _vendorPasswordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Temporary Password (Share with Vendor)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
              ),

              const Divider(height: 48, thickness: 2),

              const Text('Shop Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _shopNameController,
                decoration: const InputDecoration(labelText: 'Shop Name', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _shopDescController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Shop Description', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  onPressed: _createVendorAndShop,
                  child: const Text('Create Vendor Account & Shop', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}