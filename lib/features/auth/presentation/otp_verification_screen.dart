import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  // Removed the required phoneNumber parameter so it matches AppRouter
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  // Added phone controller with default country code
  final _phoneController = TextEditingController(text: '+92');
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // Use codeSent to toggle between Phone Input UI and OTP Input UI
    final isCodeSent = authProvider.codeSent;

    return Scaffold(
      appBar: AppBar(title: const Text('Phone Authentication')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isCodeSent ? 'Enter Verification Code' : 'Enter Phone Number',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isCodeSent
                    ? 'We have sent a 6-digit code to ${_phoneController.text}'
                    : 'We will send an SMS to verify your number.',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Error Message Display
              if (authProvider.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    authProvider.errorMessage!,
                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Conditional UI: Show Phone Input OR OTP Input
              if (!isCodeSent) ...[
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+92 3XX XXXXXXX',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                  value == null || value.length < 10 ? 'Enter a valid phone number with country code' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () {
                    if (_formKey.currentState!.validate()) {
                      authProvider.verifyPhoneNumber(
                        _phoneController.text,
                            (id) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Verification code sent via SMS!')),
                          );
                        },
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: authProvider.isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Send Code', style: TextStyle(fontSize: 16)),
                ),
              ] else ...[
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: '6-Digit OTP Code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_clock),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (value) =>
                  value == null || value.length < 6 ? 'Enter valid 6-digit OTP' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                    if (_formKey.currentState!.validate()) {
                      // Note: No Navigator routing needed here.
                      // If successful, AppRouter detects state change and redirects automatically.
                      await authProvider.verifyOTP(_otpController.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: authProvider.isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Verify & Proceed', style: TextStyle(fontSize: 16)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}