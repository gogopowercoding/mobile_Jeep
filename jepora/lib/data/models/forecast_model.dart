class ForecastModel {
  final num? forecastedRevenue;
  final num? confidence;
  final num? baselineAverage;
  final String? trend;
  final List<HistoryItem>? history;

  ForecastModel({
    this.forecastedRevenue,
    this.confidence,
    this.baselineAverage,
    this.trend,
    this.history,
  });

  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    return ForecastModel(
      forecastedRevenue: json['forecast'] != null 
        ? num.tryParse(json['forecast'].toString()) 
        : null,
      confidence: json['confidence'],
      baselineAverage: json['baselineAverage'] != null
        ? num.tryParse(json['baselineAverage'].toString())
        : null,
      trend: json['trend'],
      history: json['history'] != null
        ? (json['history'] as List)
            .map((e) => HistoryItem.fromJson(e))
            .toList()
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'forecastedRevenue': forecastedRevenue,
      'confidence': confidence,
      'baselineAverage': baselineAverage,
      'trend': trend,
      'history': history?.map((e) => e.toJson()).toList(),
    };
  }
}

class HistoryItem {
  final String? month;
  final num? revenue;

  HistoryItem({
    this.month,
    this.revenue,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      month: json['month'],
      revenue: json['revenue'] != null
        ? num.tryParse(json['revenue'].toString())
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'revenue': revenue,
    };
  }
}