// ─── USER MODEL ──────────────────────────────────────────────
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
    id:     json['id'],
    name:   json['name'] ?? '',
    email:  json['email'] ?? '',
    role:   json['role'] ?? 'pelanggan',
    phone:  json['phone'],
    avatar: json['avatar'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email,
    'role': role, 'phone': phone, 'avatar': avatar,
  };
}

// ─── PACKAGE MODEL ───────────────────────────────────────────
class PackageModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int duration;
  final String? image;

  PackageModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.duration,
    this.image,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) => PackageModel(
    id:          json['id'],
    name:        json['name'] ?? '',
    description: json['description'],
    price:       double.tryParse(json['price'].toString()) ?? 0,
    duration:    json['duration'] ?? 0,
    image:       json['image'],
  );
}

// ─── ORDER MODEL ─────────────────────────────────────────────
class OrderModel {
  final int id;
  final int userId;
  final int packageId;
  final int? driverId;
  final String bookingDate;
  final double totalPrice;
  final String status;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String? packageName;
  final String? packageImage;
  final String? driverName;
  final String? driverPhone;
  final String? paymentStatus;
  final String createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.packageId,
    this.driverId,
    required this.bookingDate,
    required this.totalPrice,
    required this.status,
    this.latitude,
    this.longitude,
    this.notes,
    this.packageName,
    this.packageImage,
    this.driverName,
    this.driverPhone,
    this.paymentStatus,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id:            json['id'],
    userId:        json['user_id'],
    packageId:     json['package_id'],
    driverId:      json['driver_id'],
    bookingDate:   json['booking_date'] ?? '',
    totalPrice:    double.tryParse(json['total_price'].toString()) ?? 0,
    status:        json['status'] ?? 'pending',
    latitude:      json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
    longitude:     json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
    notes:         json['notes'],
    packageName:   json['package_name'],
    packageImage:  json['package_image'],
    driverName:    json['driver_name'],
    driverPhone:   json['driver_phone'],
    paymentStatus: json['payment_status'],
    createdAt:     json['created_at'] ?? '',
  );
}

// ─── NOTIFICATION MODEL ──────────────────────────────────────
class NotificationModel {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id:        json['id'],
    title:     json['title'] ?? '',
    message:   json['message'] ?? '',
    isRead:    json['is_read'] == 1 || json['is_read'] == true,
    createdAt: json['created_at'] ?? '',
  );
}
