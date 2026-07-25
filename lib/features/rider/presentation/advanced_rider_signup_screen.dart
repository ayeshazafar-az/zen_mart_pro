import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';

class AdvancedRiderSignupScreen extends StatefulWidget {
  const AdvancedRiderSignupScreen({super.key});

  @override
  State<AdvancedRiderSignupScreen> createState() =>
      _AdvancedRiderSignupScreenState();
}

class _AdvancedRiderSignupScreenState extends State<AdvancedRiderSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController(text: '+92');

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  String? _selectedVehicleType;
  String? _selectedBank;

  // Images
  File? _profileImage;
  File? _drivingLicense;
  File? _vehicleImage;
  File? _cnicFront;
  File? _cnicBack;
  File? _paymentReceipt;

  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(void Function(File) onPicked) async {
    try {
      final pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 30,
          maxWidth: 800,
          maxHeight: 800);
      if (pickedFile != null) {
        setState(() {
          onPicked(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVehicleType == null || _selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select vehicle and bank.')));
      return;
    }

    if (_profileImage == null ||
        _drivingLicense == null ||
        _vehicleImage == null ||
        _cnicFront == null ||
        _cnicBack == null ||
        _paymentReceipt == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Please upload all required images, including your Driving License & profile picture!')));
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success = await authProvider.signUpRider(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
      phoneNumber: _phoneController.text,
      address: _addressController.text,
      city: _cityController.text,
      vehicleType: _selectedVehicleType!,
      bankName: _selectedBank!,
      profileImage: _profileImage!,
      drivingLicense: _drivingLicense!,
      vehicleImage: _vehicleImage!,
      cnicFront: _cnicFront!,
      cnicBack: _cnicBack!,
      paymentReceipt: _paymentReceipt!,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Application Submitted'),
            content: const Text(
                'Your rider application, verification images, and payment receipt have been uploaded. Please verify your email via the link sent. Admins will review your account soon.'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('OK'))
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(authProvider.errorMessage ?? 'Submission failed.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildImagePickerTile(
      String title, File? imageFile, void Function(File) onPicked) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
            imageFile == null ? Icons.image_not_supported : Icons.check_circle,
            color: imageFile == null ? Colors.grey : Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            imageFile == null ? 'Required: Tap to upload' : 'Image Selected'),
        trailing: ElevatedButton(
          onPressed: () => _pickImage(onPicked),
          style: ElevatedButton.styleFrom(
              backgroundColor: imageFile == null ? Colors.orange : Colors.grey),
          child: const Text('Upload', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rider Registration')),
      body: _isLoading
          ? const Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text('Uploading Documents...')
                ]))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Basic Information',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange)),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => _pickImage((f) => _profileImage = f),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.orange.shade100,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? const Icon(Icons.add_a_photo,
                                  size: 40, color: Colors.orange)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                        child: Text('Profile Photo',
                            style: TextStyle(color: Colors.grey))),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          labelText: 'Full Name', border: OutlineInputBorder()),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Email', border: OutlineInputBorder()),
                      validator: (val) => val == null || !val.contains('@')
                          ? 'Valid email required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (val.length < 8) {
                          return 'Must be at least 8 characters long';
                        }
                        if (!RegExp(r'(?=.*[A-Z])').hasMatch(val)) {
                          return 'Must contain at least one uppercase letter';
                        }
                        if (!RegExp(r'(?=.*[0-9])').hasMatch(val)) {
                          return 'Must contain at least one number';
                        }
                        if (!RegExp(r'(?=.*[!@#\$&*~])').hasMatch(val)) {
                          return 'Must contain at least one special character (!@#\$&*~)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (val != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'Contact Number',
                          border: OutlineInputBorder()),
                      validator: (val) =>
                          val == null || val.length < 5 ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                          labelText: 'Street Address',
                          border: OutlineInputBorder()),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                          labelText: 'City', border: OutlineInputBorder()),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const Text('Vehicle & Verification',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                          labelText: 'Vehicle Type',
                          border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Bike', child: Text('Bike')),
                        DropdownMenuItem(value: 'Car', child: Text('Car')),
                        DropdownMenuItem(
                            value: 'Auto', child: Text('Auto (Rickshaw)')),
                        DropdownMenuItem(value: 'Van', child: Text('Van')),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedVehicleType = val),
                    ),
                    const SizedBox(height: 16),
                    _buildImagePickerTile('Vehicle Photo (Show Number)',
                        _vehicleImage, (f) => _vehicleImage = f),
                    const SizedBox(height: 8),
                    _buildImagePickerTile('Driving License', _drivingLicense,
                        (f) => _drivingLicense = f),
                    const SizedBox(height: 8),
                    _buildImagePickerTile(
                        'CNIC Front', _cnicFront, (f) => _cnicFront = f),
                    const SizedBox(height: 8),
                    _buildImagePickerTile(
                        'CNIC Back', _cnicBack, (f) => _cnicBack = f),
                    const SizedBox(height: 24),
                    const Divider(),
                    const Text('Bank & Registration Fee',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange)),
                    const SizedBox(height: 8),
                    const Text(
                        'A one-time registration fee of PKR 1,500 is required. Please transfer to:\n\nBank: Meezan Bank\nTitle: Zen Mart Services\nAccount: 0101-2345678-09\n\nOnce paid, upload the receipt below.',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                          labelText: 'Your Payout Bank/Wallet',
                          border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'HBL', child: Text('HBL')),
                        DropdownMenuItem(
                            value: 'SadaPay', child: Text('SadaPay')),
                        DropdownMenuItem(
                            value: 'EasyPaisa', child: Text('EasyPaisa')),
                        DropdownMenuItem(
                            value: 'JazzCash', child: Text('JazzCash')),
                        DropdownMenuItem(
                            value: 'Meezan Bank', child: Text('Meezan Bank')),
                      ],
                      onChanged: (val) => setState(() => _selectedBank = val),
                    ),
                    const SizedBox(height: 16),
                    _buildImagePickerTile('Payment Receipt', _paymentReceipt,
                        (f) => _paymentReceipt = f),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submitApplication,
                        child: const Text('Submit Application',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
