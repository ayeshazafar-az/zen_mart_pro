import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_provider.dart';
import 'order_confirmation_screen.dart';
import '../../../core/services/notification_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CheckoutScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> cartItems;
  final double subtotal;

  const CheckoutScreen(
      {super.key, required this.cartItems, required this.subtotal});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _couponController = TextEditingController();
  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isLoading = false;
  double _discountAmount = 0.0;
  String _appliedCoupon = '';
  double _deliveryFee = 50.0;
  bool _fetchingFee = true;

  @override
  void initState() {
    super.initState();
    _fetchDeliveryFee();
  }

  Future<void> _fetchDeliveryFee() async {
    if (widget.cartItems.isNotEmpty) {
      final data = widget.cartItems.first.data() as Map<String, dynamic>;
      final shopId = data['shopId'];
      if (shopId != null) {
        try {
          final shopDoc = await FirebaseFirestore.instance
              .collection('shops')
              .doc(shopId)
              .get();
          if (shopDoc.exists) {
            final shopData = shopDoc.data() as Map<String, dynamic>;
            if (shopData['deliveryFee'] != null) {
              setState(() {
                _deliveryFee = (shopData['deliveryFee'] as num).toDouble();
              });
            }
          }
        } catch (e) {
          debugPrint('Failed to get delivery fee: $e');
        }
      }
    }
    if (mounted) {
      setState(() {
        _fetchingFee = false;
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    // Simulate static coupons
    if (code == 'ZENVYRO20') {
      setState(() {
        _discountAmount = widget.subtotal * 0.20;
        _appliedCoupon = code;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('20% discount applied!')));
    } else if (code == 'WELCOME10') {
      setState(() {
        _discountAmount = widget.subtotal * 0.10;
        _appliedCoupon = code;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('10% discount applied!')));
    } else {
      setState(() {
        _discountAmount = 0.0;
        _appliedCoupon = '';
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid coupon code')));
    }
  }

  Future<void> _placeOrder(
      String userId, String userEmail, double finalTotal) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String shopId = '';
      List<Map<String, dynamic>> itemsList = [];

      for (var doc in widget.cartItems) {
        final data = doc.data() as Map<String, dynamic>;
        if (shopId.isEmpty && data['shopId'] != null) {
          shopId = data['shopId'];
        }
        itemsList.add(data);

        // Decrease stock
        final productId = data['productId'];
        final itemShopId = data['shopId'];
        final qty = data['quantity'] ?? 1;

        if (productId != null && itemShopId != null) {
          try {
            await FirebaseFirestore.instance
                .collection('shops')
                .doc(itemShopId)
                .collection('products')
                .doc(productId)
                .update({
              'stock': FieldValue.increment(-qty),
            });
          } catch (e) {
            debugPrint('Failed to decrease stock: $e');
          }
        }
      }

      final orderRef =
          await FirebaseFirestore.instance.collection('orders').add({
        'customerId': userId,
        'customerEmail': userEmail,
        'shopId': shopId.isNotEmpty ? shopId : 'unknown_shop',
        'items': itemsList,
        'subtotal': widget.subtotal,
        'deliveryFee': _deliveryFee,
        'discount': _discountAmount,
        'appliedCoupon': _appliedCoupon,
        'totalAmount': finalTotal,
        'shippingAddress': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'paymentMethod': _selectedPaymentMethod,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // --- FCM TRIGGER: Notify Customer ---
      try {
        await NotificationService().sendMockNotificationToUser(
          userId,
          "Order Confirmed! \u{1F389}",
          "Your order #${orderRef.id.characters.take(6)} has been placed successfully.",
        );
      } catch (e) {
        debugPrint('Failed to send notification: \$e');
      }

      // Clear cart
      final cartDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      for (var doc in cartDocs.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(orderId: orderRef.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processCheckout(
      String userId, String userEmail, double finalTotal) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPaymentMethod == 'Online Wallet / QR Code') {
      final proceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
                title:
                    const Text('Scan QR to Pay', textAlign: TextAlign.center),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: QrImageView(
                        data:
                            'https://zenmartpro.web.app/checkout/pay?amount=${finalTotal.toStringAsFixed(2)}',
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Total Amount: Rs. ${finalTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                        'Scan using your mobile banking app to complete payment.',
                        textAlign: TextAlign.center),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false), // Cancel
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true), // Done
                    child: const Text('Payment Complete'),
                  ),
                ],
              ));

      if (proceed == true) {
        _placeOrder(userId, userEmail, finalTotal);
      }
    } else {
      _placeOrder(userId, userEmail, finalTotal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid ?? '';
    final userEmail = authProvider.currentUser?.email ?? 'Customer';
    final finalTotal = widget.subtotal + _deliveryFee - _discountAmount > 0
        ? widget.subtotal + _deliveryFee - _discountAmount
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout & Payment')),
      body: _fetchingFee
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Shipping Address',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                          labelText: 'Delivery Address',
                          border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter delivery address'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                          labelText: 'Contact Phone Number',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter phone number'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    const Text('Discount & Coupons',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _couponController,
                            decoration: const InputDecoration(
                                hintText: 'Enter Coupon Code',
                                border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _applyCoupon,
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Payment Method',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPaymentMethod,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(
                            value: 'Cash on Delivery',
                            child: Text('Cash on Delivery')),
                        DropdownMenuItem(
                            value: 'Credit / Debit Card',
                            child: Text('Credit / Debit Card')),
                        DropdownMenuItem(
                            value: 'Online Wallet / QR Code',
                            child: Text('Online Wallet / QR Code')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedPaymentMethod = value);
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    const Text('Order Summary',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:',
                                    style: TextStyle(fontSize: 16)),
                                Text(
                                    'Rs. ${widget.subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                            if (_discountAmount > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Discount:',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.green)),
                                  Text(
                                      '- Rs. ${_discountAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.green)),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Delivery Fee:',
                                    style: TextStyle(fontSize: 16)),
                                Text('Rs. ${_deliveryFee.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Amount:',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Text('Rs. ${finalTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () =>
                                _processCheckout(userId, userEmail, finalTotal),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Place Order',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
