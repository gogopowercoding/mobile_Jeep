class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? avatar;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'pelanggan',
        phone: json['phone'],
        avatar: json['avatar'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'avatar': avatar,
      };
}