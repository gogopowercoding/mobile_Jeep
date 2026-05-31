import 'schedule_model.dart';

class PackageModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int duration;
  final String? image;
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

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: double.tryParse(json['price'].toString()) ?? 0,
      duration: int.tryParse(json['duration'].toString()) ?? 0,
      image: json['image']?.toString(),
      schedules: json['schedules'] != null && json['schedules'] is List
          ? (json['schedules'] as List)
              .whereType<Map>()
              .map((e) => ScheduleModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'duration': duration,
        'image': image,
        'schedules': schedules?.map((e) => e.toJson()).toList() ?? [],
      };
}
