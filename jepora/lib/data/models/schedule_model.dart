class ScheduleModel {
  final int id;
  final int dayNumber;
  final String startTime;
  final String? endTime;
  final String activity;
  final bool isOptional;
  final int sortOrder;

  ScheduleModel({
    required this.id,
    required this.dayNumber,
    required this.startTime,
    this.endTime,
    required this.activity,
    required this.isOptional,
    required this.sortOrder,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) => ScheduleModel(
        id: json['id'],
        dayNumber: json['day_number'] ?? 1,
        startTime: json['start_time'] ?? '',
        endTime: json['end_time'],
        activity: json['activity'] ?? '',
        isOptional: json['is_optional'] == 1 || json['is_optional'] == true,
        sortOrder: json['sort_order'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'day_number': dayNumber,
        'start_time': startTime,
        'end_time': endTime,
        'activity': activity,
        'is_optional': isOptional ? 1 : 0,
        'sort_order': sortOrder,
      };
}