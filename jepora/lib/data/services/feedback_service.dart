import 'package:flutter/foundation.dart';
import 'package:jepora/core/network/api_client.dart';
import 'package:jepora/data/models/feedback_model.dart';

class FeedbackService extends ChangeNotifier {
  List<FeedbackModel> _myFeedbacks = [];
  bool _isLoading = false;
  String? _error;

  List<FeedbackModel> get myFeedbacks => _myFeedbacks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── GET MY FEEDBACK ─────────────────────────────────────────
  Future<void> fetchMyFeedback() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient().dio.get('/notifications/feedback/my');
      if (res.data['success'] == true) {
        _myFeedbacks = (res.data['data'] as List)
            .map((e) => FeedbackModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── SUBMIT (kirim baru) ──────────────────────────────────────
  Future<bool> submit({
    required String message,
    required int rating,
    int? orderId,
  }) async {
    try {
      final res = await ApiClient().dio.post('/notifications/feedback', data: {
        'message':  message,
        'rating':   rating,
        if (orderId != null) 'order_id': orderId,
      });
      return res.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ─── UPDATE ──────────────────────────────────────────────────
  Future<bool> update({
    required int id,
    required String message,
    required int rating,
  }) async {
    try {
      final res = await ApiClient().dio.put(
        '/notifications/feedback/$id',
        data: {'message': message, 'rating': rating},
      );
      if (res.data['success'] == true) {
        // Update local list tanpa fetch ulang
        _myFeedbacks = _myFeedbacks.map((f) {
          return f.id == id ? f.copyWith(message: message, rating: rating) : f;
        }).toList();
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ─── DELETE ──────────────────────────────────────────────────
  Future<bool> delete(int id) async {
    try {
      final res =
          await ApiClient().dio.delete('/notifications/feedback/$id');
      if (res.data['success'] == true) {
        _myFeedbacks.removeWhere((f) => f.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}