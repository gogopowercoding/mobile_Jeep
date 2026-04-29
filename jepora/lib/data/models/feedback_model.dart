class FeedbackModel {
  final int id;
  final String message;
  final int rating;
  final String createdAt;
  final int? orderId;
  final String? bookingDate;
  final String? packageName;

  FeedbackModel({
    required this.id,
    required this.message,
    required this.rating,
    required this.createdAt,
    this.orderId,
    this.bookingDate,
    this.packageName,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> j) => FeedbackModel(
        id:          j['id'],
        message:     j['message'] ?? '',
        rating:      j['rating']  ?? 5,
        createdAt:   j['created_at'] ?? '',
        orderId:     j['order_id'],
        bookingDate: j['booking_date'],
        packageName: j['package_name'],
      );

  FeedbackModel copyWith({String? message, int? rating}) => FeedbackModel(
        id:          id,
        message:     message     ?? this.message,
        rating:      rating      ?? this.rating,
        createdAt:   createdAt,
        orderId:     orderId,
        bookingDate: bookingDate,
        packageName: packageName,
      );
}