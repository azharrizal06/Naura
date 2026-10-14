class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String roleLabel;
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.roleLabel,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      roleLabel: (json['role_label'] ?? json['role']) as String,
      isActive: (json['is_active'] ?? true) as bool,
    );
  }

  bool get isCustomer => role == 'customer';
}
