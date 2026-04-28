import 'dart:convert';
import 'package:dio/dio.dart';

class AIService {
  // ⚠️ Isi API KEY OpenRouter kamu di sini
  static const String _apiKey = "ISI API";

  static const String _url = "https://openrouter.ai/api/v1/chat/completions";

  // ✅ Dio TERPISAH — tidak pakai ApiClient agar interceptor backend
  //    tidak ikut menyuntikkan token user ke request OpenRouter
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        'HTTP-Referer': 'https://yourapp.com',
        'X-Title': 'JeepOra App',
      },
    ),
  );

  static Future<String> getAIResponseWithHistory(
    List<Map<String, String>> history,
  ) async {
    try {
      final response = await _dio.post(
        _url,
        data: jsonEncode({
          "model": "openai/gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content":
                  "Kamu adalah asisten virtual JeepOra yang ramah dan membantu. "
                  "JeepOra adalah aplikasi pemesanan jeep wisata di kawasan Dieng, Wonosobo, Jawa Tengah. "
                  "Bantu user dengan informasi paket wisata, harga, pemesanan, cuaca, destinasi, "
                  "dan pertanyaan seputar wisata Dieng. "
                  "Jawab dalam Bahasa Indonesia yang ramah dan ringkas.",
            },
            ...history,
          ],
        }),
      );

      final data = response.data is String
          ? jsonDecode(response.data)
          : response.data;

      if (data["choices"] != null &&
          (data["choices"] as List).isNotEmpty &&
          data["choices"][0]["message"] != null) {
        return data["choices"][0]["message"]["content"] ?? "Tidak ada respon.";
      }

      return "AI tidak memberikan respon.";
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return "Koneksi timeout. Periksa jaringan kamu.";
      }
      if (e.response != null) {
        final status = e.response!.statusCode;
        if (status == 401) {
          return "API Key tidak valid atau sudah expired. Hubungi admin.";
        }
        if (status == 429) {
          return "Terlalu banyak permintaan. Coba lagi beberapa saat.";
        }
        return "Error API ($status): ${e.response!.data}";
      }
      return "Tidak dapat terhubung ke AI. Periksa koneksi internet.";
    } catch (e) {
      return "Terjadi kesalahan: $e";
    }
  }
}
