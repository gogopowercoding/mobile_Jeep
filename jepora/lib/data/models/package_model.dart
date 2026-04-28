import 'schedule_model.dart';

class PackageModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int duration;
  final String? image;

  // 🔥 Tambahan
  final List<ScheduleModel>? schedules;

  PackageModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.duration,
    this.image,
    this.schedules,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) => PackageModel(
        id: json['id'],
        name: json['name'] ?? '',
        description: json['description'],
        price: double.tryParse(json['price'].toString()) ?? 0,
        duration: json['duration'] ?? 0,
        image: json['image'],

        // 🔥 Parsing schedules
        schedules: json['schedules'] != null
            ? (json['schedules'] as List)
                .map((e) => ScheduleModel.fromJson(e))
                .toList()
            : [],
      );
}