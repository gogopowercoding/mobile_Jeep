# Setup Fitur Local Notifications

Fitur local notifications telah diintegrasikan ke project JeepOra menggunakan package `flutter_local_notifications`. Berikut adalah panduan setup lengkapnya.

## ✅ Fitur yang Sudah Diimplementasikan

1. **LocalNotificationService** - Service untuk mengelola local notifications
   - File: `lib/data/services/local_notification_service.dart`
   - Methods: 
     - `showNotification()` - Tampilkan notifikasi simple
     - `showBigPictureNotification()` - Notifikasi dengan gambar (Android)
     - `showProgressNotification()` - Notifikasi dengan progress bar (Android)
     - `cancel()` - Batalkan notifikasi
     - `cancelAll()` - Batalkan semua notifikasi

2. **AdminNotificationService** - Terintegrasi dengan local notifications
   - Automatically menampilkan local notification ketika ada notifikasi baru yang belum dibaca
   - Polling setiap 30 detik untuk fetch notifikasi dari API

3. **Main.dart** - Sudah initialize local notifications saat app startup

## 📱 Setup Platform-Specific

### Android Setup (Sudah Otomatis)
- ✅ Permission `POST_NOTIFICATIONS` sudah ditambahkan di AndroidManifest.xml
- ✅ Notification channel `jeep_ora_channel` sudah dikonfigurasi di LocalNotificationService
- ✅ Android API 33+ (Android 13+) support untuk POST_NOTIFICATIONS

**Untuk Android 12 dan lebih rendah:** Tidak memerlukan permission khusus, notification akan tampil otomatis.

### iOS Setup

iOS sudah support otomatis untuk flutter_local_notifications. Permission diminta saat app pertama kali menampilkan notifikasi.

## 🚀 Cara Menggunakan

### 1. Show Simple Notification
```dart
await LocalNotificationService().showNotification(
  id: 1,
  title: 'Pesanan Baru',
  body: 'Anda memiliki pesanan baru dari John Doe',
  payload: 'order_123',
);
```

### 2. Show Big Picture Notification (Android)
```dart
await LocalNotificationService().showBigPictureNotification(
  id: 2,
  title: 'Pembayaran Dikonfirmasi',
  body: 'Pembayaran Anda telah diterima',
  imageUrl: '/path/to/image.jpg',
  payload: 'payment_456',
);
```

### 3. Show Progress Notification (Android)
```dart
await LocalNotificationService().showProgressNotification(
  id: 3,
  title: 'Downloading',
  body: 'Sedang download dokumen...',
  progress: 75,
  maxProgress: 100,
  payload: 'download_789',
);
```

### 4. Cancel Notification
```dart
await LocalNotificationService().cancel(1);
await LocalNotificationService().cancelAll();
```

## 📲 Testing

### Test di Android
```bash
# Install APK
flutter install

# Atau run di emulator/device
flutter run
```

Notifikasi akan muncul ketika:
- App menerima polling dari API dan ada notifikasi baru yang belum dibaca

### Test di iOS
```bash
flutter run
```

## 🔧 Customization

### Mengubah Notification Channel
Edit di `lib/data/services/local_notification_service.dart`:
```dart
const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
  'jeep_ora_channel',        // Channel ID
  'JeepOra Notifications',   // Channel Name
  channelDescription: 'Notifikasi untuk JeepOra',
  importance: Importance.max,
  priority: Priority.high,
);
```

### Handle Notification Tap
Edit method `navigateToItemDetail()` di `local_notification_service.dart` untuk handle navigation saat user tap notifikasi:
```dart
void navigateToItemDetail(String? payload) {
  if (payload != null) {
    // TODO: Navigasi berdasarkan payload
    // Contoh: 
    // if (payload.startsWith('order_')) {
    //   navigateToOrderDetail(payload);
    // }
  }
}
```

## 📋 Daftar Notifikasi yang Bisa Ditampilkan

Berdasarkan polling dari API, notifikasi akan ditampilkan untuk:
- ✅ Pesanan baru
- ✅ Pembayaran dikonfirmasi/ditolak
- ✅ Pesanan dibatalkan
- ✅ Driver sedang menuju ke lokasi penjemputan
- ✅ Perubahan status pesanan

## 🐛 Troubleshooting

### Notifikasi tidak muncul di Android
1. Pastikan app berjalan di device/emulator dengan Android 12+
2. Check permission di Settings > Apps > JeepOra > Notifications
3. Pastikan notification sound tidak di-mute

### Notifikasi tidak muncul di iOS
1. Check notification setting di Settings > Notifications > JeepOra
2. Pastikan alerts, badges, dan sounds di-enable
3. Coba restart device

### Error saat run
1. Jalankan `flutter clean`
2. Jalankan `flutter pub get`
3. Jalankan `flutter run` kembali

## 📚 Resources

- [flutter_local_notifications Docs](https://pub.dev/packages/flutter_local_notifications)
- [Android Notification Documentation](https://developer.android.com/guide/topics/ui/notifiers/notifications)
- [iOS UserNotifications Framework](https://developer.apple.com/documentation/usernotifications)

## ✨ Next Steps

1. Implement notification tap handler untuk navigasi ke order detail
2. Tambahkan sound/vibration pattern custom
3. Setup notification grouping untuk multiple notifications
4. Implement scheduling untuk delayed notifications
