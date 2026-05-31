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
        id: int.tryParse(json['id'].toString()) ?? 0,
        dayNumber: int.tryParse(json['day_number'].toString()) ?? 1,
        startTime: json['start_time']?.toString() ?? '',
        endTime: json['end_time']?.toString(),
        activity: json['activity']?.toString() ?? '',
        isOptional: json['is_optional'] == 1 ||
            json['is_optional'] == true ||
            json['is_optional'].toString() == '1',
        sortOrder: int.tryParse(json['sort_order'].toString()) ?? 0,
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
