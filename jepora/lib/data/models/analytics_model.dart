class MonthlyRevenueModel {
  final String month;
  final int totalOrders;
  final double totalRevenue;
  final double avgOrderValue;

  MonthlyRevenueModel({
    required this.month,
    required this.totalOrders,
    required this.totalRevenue,
    required this.avgOrderValue,
  });

  factory MonthlyRevenueModel.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenueModel(
      month: json['month'] ?? '',
      totalOrders: json['total_orders'] ?? 0,
      totalRevenue: double.tryParse(json['total_revenue']?.toString() ?? '0') ?? 0.0,
      avgOrderValue: double.tryParse(json['avg_order_value']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class SeasonAnalysisModel {
  final String monthNumber;
  final String monthName;
  final int totalOrders;
  final double totalRevenue;
  final String season;

  SeasonAnalysisModel({
    required this.monthNumber,
    required this.monthName,
    required this.totalOrders,
    required this.totalRevenue,
    required this.season,
  });

  factory SeasonAnalysisModel.fromJson(Map<String, dynamic> json) {
    return SeasonAnalysisModel(
      monthNumber: json['month_number']?.toString() ?? '',
      monthName: json['month_name'] ?? '',
      totalOrders: json['total_orders'] ?? 0,
      totalRevenue: double.tryParse(json['total_revenue']?.toString() ?? '0') ?? 0.0,
      season: json['season'] ?? 'normal',
    );
  }
}

class AnalyticsSummaryModel {
  final int thisMonthOrders;
  final double thisMonthRevenue;
  final int lastMonthOrders;
  final double lastMonthRevenue;
  final double growthRate;

  AnalyticsSummaryModel({
    required this.thisMonthOrders,
    required this.thisMonthRevenue,
    required this.lastMonthOrders,
    required this.lastMonthRevenue,
    required this.growthRate,
  });

  factory AnalyticsSummaryModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummaryModel(
      thisMonthOrders: json['thisMonth']['total_orders'] ?? 0,
      thisMonthRevenue: double.tryParse(json['thisMonth']['total_revenue']?.toString() ?? '0') ?? 0.0,
      lastMonthOrders: json['lastMonth']['total_orders'] ?? 0,
      lastMonthRevenue: double.tryParse(json['lastMonth']['total_revenue']?.toString() ?? '0') ?? 0.0,
      growthRate: (json['growthRate'] ?? 0).toDouble(),
    );
  }
}

class ForecastModel {
  final double nextMonthForecast;
  final double baselineAverage;
  final String trend;
  final double confidence;

  ForecastModel({
    required this.nextMonthForecast,
    required this.baselineAverage,
    required this.trend,
    required this.confidence,
  });

  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    return ForecastModel(
      nextMonthForecast: double.tryParse(json['forecast']?.toString() ?? '0') ?? 0.0,
      baselineAverage: double.tryParse(json['baselineAverage']?.toString() ?? '0') ?? 0.0,
      trend: json['trend'] ?? 'stabil',
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}