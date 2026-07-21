class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role; // 'super_admin', 'vendor', 'customer', 'rider'
  final String? assignedShopId; // Specifically used for vendors

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.assignedShopId,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'customer',
      assignedShopId: map['assignedShopId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'assignedShopId': assignedShopId,
    };
  }
}