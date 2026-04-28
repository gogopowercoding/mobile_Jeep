import 'dart:math';

class ChatbotService {
  static String? _lastIntent;
  static final Random _rand = Random();

  static String getResponse(String message) {
    final msg = message.toLowerCase();

    if (_match(msg, ["halo", "hai"])) {
      return _random([
        "Halo! Ada yang bisa saya bantu?",
        "Hai! Mau tanya seputar jeep Dieng?",
      ]);
    }

    if (_match(msg, ["berapa lama", "waktu tempuh", "durasi"])) {
      if (_match(msg, ["jogja"]) && _match(msg, ["dieng"])) {
        return "Perjalanan dari Jogja ke Dieng sekitar 3–4 jam.";
      }
      return "Durasi wisata jeep sekitar 2–4 jam tergantung paket.";
    }

    if (_match(msg, ["harga", "biaya", "tarif"])) {
      _lastIntent = "harga";
      return "Harga tergantung paket. Mau rute Dieng atau sunrise?";
    }

    if (_lastIntent == "harga") {
      if (_match(msg, ["dieng"])) {
        _lastIntent = null;
        return "Harga rute Dieng mulai dari Rp300.000.";
      }
      if (_match(msg, ["sunrise"])) {
        _lastIntent = null;
        return "Paket sunrise mulai dari Rp400.000.";
      }
      return "Sebutkan rute yang kamu inginkan.";
    }

    if (_match(msg, ["booking", "reservasi"])) {
      return "Silakan booking melalui menu Booking di aplikasi.";
    }

    if (_match(msg, ["kapasitas", "berapa orang"])) {
      return "Satu jeep dapat menampung hingga 6 orang.";
    }

    if (_match(msg, ["destinasi", "wisata dieng"])) {
      return "Destinasi populer: Kawah Sikidang, Telaga Warna.";
    }

    if (_match(msg, ["cuaca dieng"])) {
      return "Dieng cukup dingin, sebaiknya memakai jaket.";
    }

    if (_match(msg, ["lokasi dieng"])) {
      return "Dieng berada di Wonosobo, Jawa Tengah.";
    }

    if (_match(msg, ["terima kasih"])) {
      return "Sama-sama.";
    }

    if (_match(msg, ["siapa kamu"])) {
      return "Saya asisten JeepOra.";
    }

    return "Maaf, saya belum memiliki informasi untuk itu.";
  }

  static bool _match(String msg, List<String> keys) {
    return keys.any((k) => msg.contains(k));
  }

  static String _random(List<String> list) {
    return list[_rand.nextInt(list.length)];
  }
}