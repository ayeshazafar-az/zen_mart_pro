class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'super_admin', 'vendor', 'rider', 'customer'
  final String? phone;
  final bool isApproved; // NEW: Required for Rider pending status

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.isApproved = true, // Defaults to true to protect older accounts
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? 'User',
      role: map['role'] ?? 'customer',
      phone: map['phone'],
      // If the field doesn't exist in Firestore, assume approved
      isApproved: map['isApproved'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'isApproved': isApproved,
    };
  }
}