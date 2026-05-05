import 'package:flutter/foundation.dart';
import '../models/analytics_model.dart';
import '../../core/network/api_client.dart';

class AnalyticsService extends ChangeNotifier {
  List<MonthlyRevenueModel> _monthlyRevenue = [];
  List<SeasonAnalysisModel> _seasonAnalysis = [];
  AnalyticsSummaryModel? _summary;
  ForecastModel? _forecast;
  bool _isLoading = false;
  String? _error;

  List<MonthlyRevenueModel> get monthlyRevenue => _monthlyRevenue;
  List<SeasonAnalysisModel> get seasonAnalysis => _seasonAnalysis;
  AnalyticsSummaryModel? get summary => _summary;
  ForecastModel? get forecast => _forecast;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMonthlyRevenue() async {
    try {
      print('📍 [fetchMonthlyRevenue] START');
      final res = await ApiClient().dio.get('/analytics/revenue-monthly');
      print('✅ Response status: ${res.statusCode}');
      print('📝 Response data: ${res.data}');

      if (res.data['success'] == true) {
        _monthlyRevenue = (res.data['data'] as List)
            .map((e) => MonthlyRevenueModel.fromJson(e))
            .toList();
          notifyListeners();
        print('✅ Monthly revenue loaded: ${_monthlyRevenue.length} items');
      }
    } catch (e) {
      print('❌ Error fetchMonthlyRevenue: $e');
      _error = e.toString();
    }
  }

  Future<void> fetchSeasonAnalysis() async {
    try {
      print('📍 [fetchSeasonAnalysis] START');
      final res = await ApiClient().dio.get('/analytics/season-analysis');
      print('✅ Response status: ${res.statusCode}');
      print('📝 Response data: ${res.data}');

      if (res.data['success'] == true) {
        _seasonAnalysis = (res.data['data'] as List)
            .map((e) => SeasonAnalysisModel.fromJson(e))
            .toList();
          notifyListeners();
        print('✅ Season analysis loaded: ${_seasonAnalysis.length} items');
      }
    } catch (e) {
      print('❌ Error fetchSeasonAnalysis: $e');
      _error = e.toString();
    }
  }

  Future<void> fetchSummary() async {
    try {
      print('📍 [fetchSummary] START');
      final res = await ApiClient().dio.get('/analytics/summary');
      print('✅ Response status: ${res.statusCode}');
      print('📝 Response data: ${res.data}');

      if (res.data['success'] == true) {
        _summary = AnalyticsSummaryModel.fromJson(res.data['data']);
        notifyListeners();
        print('✅ Summary loaded: ${_summary?.thisMonthRevenue}');
      }
    } catch (e) {
      print('❌ Error fetchSummary: $e');
      _error = e.toString();
    }
  }

  Future<void> fetchForecast() async {
    try {
      print('📍 [fetchForecast] START');
      final res = await ApiClient().dio.get('/analytics/forecast');
      print('✅ Response status: ${res.statusCode}');
      print('📝 Response data: ${res.data}');

      if (res.data['success'] == true) {
        _forecast = ForecastModel.fromJson(res.data['data']);
        notifyListeners();
        print('✅ Forecast loaded: ${_forecast?.nextMonthForecast}');      }
    } catch (e) {
      print('❌ Error fetchForecast: $e');
      _error = e.toString();
    }
  }

  Future<void> fetchAllAnalytics() async {
    print('🟢 [fetchAllAnalytics] START');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('⏳ Fetching all analytics...');
      await Future.wait([
        fetchSummary(),
        fetchMonthlyRevenue(),
        fetchSeasonAnalysis(),
        fetchForecast(),
      ]);

      print('✅ All analytics fetched successfully!');
      print('📊 Summary: ${_summary}');
      print('📊 Monthly Revenue: ${_monthlyRevenue.length} items');
      print('📊 Season Analysis: ${_seasonAnalysis.length} items');
      print('📊 Forecast: ${_forecast}');
    } catch (e) {
      print('❌ Error fetchAllAnalytics: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
      print('🟢 [fetchAllAnalytics] DONE - isLoading: $_isLoading');
    }
  }
}