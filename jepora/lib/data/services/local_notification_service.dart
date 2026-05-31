import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  factory LocalNotificationService() => _instance;

  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'jeep_ora_channel',
    'JeepOra Notifications',
    description: 'Notifikasi untuk JeepOra',
    importance: Importance.high,
  );

  /// Initialize Local Notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // flutter_local_notifications versi baru sudah tidak memakai
    // onDidReceiveLocalNotification di DarwinInitializationSettings.
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.createNotificationChannel(_channel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    _isInitialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Show Simple Notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _ensureInitialized();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'jeep_ora_channel',
      'JeepOra Notifications',
      channelDescription: 'Notifikasi untuk JeepOra',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Show Notification with Big Picture (Android only).
  /// Catatan: imagePath harus path file lokal, bukan URL internet langsung.
  Future<void> showBigPictureNotification({
    required int id,
    required String title,
    required String body,
    String? imagePath,
    String? payload,
  }) async {
    await _ensureInitialized();

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'jeep_ora_channel',
      'JeepOra Notifications',
      channelDescription: 'Notifikasi untuk JeepOra',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      styleInformation: imagePath != null
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(imagePath),
              contentTitle: title,
              summaryText: body,
            )
          : null,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Show Notification with Progress (Android only)
  Future<void> showProgressNotification({
    required int id,
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
    String? payload,
  }) async {
    await _ensureInitialized();

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'jeep_ora_channel',
      'JeepOra Notifications',
      channelDescription: 'Notifikasi untuk JeepOra',
      importance: Importance.high,
      priority: Priority.high,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      onlyAlertOnce: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }



  /// Menjadwalkan reminder untuk jadwal booking wisata.
  ///
  /// Karena data booking dari backend hanya berupa tanggal (tanpa jam), reminder
  /// dibuat pada H-1 pukul 08.00 WIB. Jika waktu tersebut sudah lewat, sistem
  /// mencoba menjadwalkan pada hari-H pukul 06.00 WIB. Jika masih sudah lewat
  /// juga, reminder dibuat 1 menit dari sekarang agar tetap bisa diuji saat demo.
  Future<void> scheduleBookingReminder({
    required int orderId,
    required String packageName,
    required DateTime bookingDate,
    String? pickupAddress,
  }) async {
    await _ensureInitialized();

    final reminderTime = _resolveBookingReminderTime(bookingDate);
    final notificationId = _bookingReminderNotificationId(orderId);

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final body = pickupAddress == null || pickupAddress.trim().isEmpty
        ? 'Jangan lupa persiapkan perjalananmu untuk paket $packageName.'
        : 'Jangan lupa persiapkan perjalananmu. Lokasi jemput: $pickupAddress';

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Reminder Wisata Jeep',
      body,
      tz.TZDateTime.from(reminderTime, tz.local),
      platformChannelSpecifics,
      payload: 'booking_reminder:$orderId',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    if (kDebugMode) {
      debugPrint(
        'Booking reminder scheduled for order #$orderId at $reminderTime',
      );
    }
  }

  /// Membatalkan reminder booking tertentu, dipakai saat pesanan dibatalkan.
  Future<void> cancelBookingReminder(int orderId) async {
    await cancel(_bookingReminderNotificationId(orderId));
  }

  int _bookingReminderNotificationId(int orderId) => 100000 + orderId;

  DateTime _resolveBookingReminderTime(DateTime bookingDate) {
    final now = DateTime.now();
    final bookingDay = DateTime(
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
    );

    final oneDayBeforeAtEight = DateTime(
      bookingDay.year,
      bookingDay.month,
      bookingDay.day,
      8,
    ).subtract(const Duration(days: 1));

    if (oneDayBeforeAtEight.isAfter(now)) {
      return oneDayBeforeAtEight;
    }

    final sameDayAtSix = DateTime(
      bookingDay.year,
      bookingDay.month,
      bookingDay.day,
      6,
    );

    if (sameDayAtSix.isAfter(now)) {
      return sameDayAtSix;
    }

    return now.add(const Duration(minutes: 1));
  }


  /// Cancel Single Notification
  Future<void> cancel(int id) async {
    await _ensureInitialized();
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel All Notifications
  Future<void> cancelAll() async {
    await _ensureInitialized();
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Handle notification tap
  void _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) {
    final String? payload = notificationResponse.payload;
    if (kDebugMode) {
      debugPrint('Notification tapped. Payload: $payload');
    }
    navigateToItemDetail(payload);
  }

  /// Navigate to notification detail
  void navigateToItemDetail(String? payload) {
    if (payload != null && kDebugMode) {
      debugPrint('Navigating to: $payload');
    }
    // TODO: Implementasi navigasi berdasarkan payload jika diperlukan.
    // Contoh: navigateToOrderDetail(payload)
  }
}
