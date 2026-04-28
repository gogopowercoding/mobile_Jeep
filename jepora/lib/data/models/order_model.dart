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
  final String? customerName;
  final String? customerPhone;
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
    this.customerName,
    this.customerPhone,
    this.paymentStatus,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'],
        userId: json['user_id'],
        packageId: json['package_id'],
        driverId: json['driver_id'],
        bookingDate: json['booking_date'] ?? '',
        totalPrice: double.tryParse(json['total_price'].toString()) ?? 0,
        status: json['status'] ?? 'pending',
        latitude: json['latitude'] != null
            ? double.tryParse(json['latitude'].toString())
            : null,
        longitude: json['longitude'] != null
            ? double.tryParse(json['longitude'].toString())
            : null,
        notes: json['notes'],
        packageName: json['package_name'],
        packageImage: json['package_image'],
        driverName: json['driver_name'],
        driverPhone: json['driver_phone'],
        customerName: json['customer_name'],
        customerPhone: json['customer_phone'],
        paymentStatus: json['payment_status'],
        createdAt: json['created_at'] ?? '',
      );
}