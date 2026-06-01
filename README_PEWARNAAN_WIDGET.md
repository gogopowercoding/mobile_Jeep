# README Pewarnaan Widget / Box Jepora

File ini dibuat sebagai panduan cepat jika dosen meminta perubahan warna pada bagian tertentu di project Flutter **Jepora**.

Project ini sudah memakai warna terpusat melalui file:

```text
lib/core/theme/app_theme.dart
```

Di dalam file tersebut terdapat class utama:

```dart
class AppColors {
  static const Color primary        = Color(0xFF39E07A);
  static const Color primaryDark    = Color(0xFF1DB954);
  static const Color primaryLight   = Color(0xFFD6EED8);

  static const Color background     = Color(0xFFF5F5F0);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color cardGreen      = Color(0xFFD6EED8);

  static const Color textPrimary    = Color(0xFF1A1A1A);
  static const Color textSecondary  = Color(0xFF666666);
  static const Color textHint       = Color(0xFFAAAAAA);
  static const Color textOnPrimary  = Color(0xFF0A3020);

  static const Color success        = Color(0xFF39E07A);
  static const Color warning        = Color(0xFFFFB800);
  static const Color error          = Color(0xFFE53935);
  static const Color info           = Color(0xFF2196F3);

  static const Color statusPending    = Color(0xFFFFB800);
  static const Color statusConfirmed  = Color(0xFF2196F3);
  static const Color statusOngoing    = Color(0xFF9C27B0);
  static const Color statusCompleted  = Color(0xFF39E07A);
  static const Color statusCancelled  = Color(0xFFE53935);

  static const Color divider        = Color(0xFFE8E8E8);
  static const Color shimmerBase    = Color(0xFFE8E8E8);
  static const Color shimmerHigh    = Color(0xFFF5F5F5);
}
```

## 1. Cara Membaca Kode Warna Flutter

Format warna di Flutter biasanya memakai:

```dart
Color(0xFF39E07A)
```

Penjelasan:

```text
0xFF  = opacity penuh / tidak transparan
39E07A = kode warna HEX
```

Jika dari website warna kamu mendapat kode `#2196F3`, maka di Flutter ditulis:

```dart
Color(0xFF2196F3)
```

Jadi tanda `#` diganti dengan `0xFF`.

## 2. Mengganti Warna Utama Aplikasi

Jika dosen meminta warna utama aplikasi diganti, ubah bagian ini:

```dart
static const Color primary = Color(0xFF39E07A);
```

Contoh diganti menjadi biru:

```dart
static const Color primary = Color(0xFF2196F3);
```

Warna ini memengaruhi banyak bagian, seperti:

- Tombol utama
- Warna icon aktif
- Border input saat fokus
- Harga paket
- Beberapa icon dan badge

## 3. Mengganti Warna Background Halaman

Warna background utama aplikasi ada di:

```dart
static const Color background = Color(0xFFF5F5F0);
```

Contoh jika ingin dibuat putih:

```dart
static const Color background = Color(0xFFFFFFFF);
```

Warna ini digunakan di `ThemeData`:

```dart
scaffoldBackgroundColor: AppColors.background,
```

Artinya semua halaman yang memakai `Scaffold` akan mengikuti warna background ini.

## 4. Mengganti Warna Card / Box Umum

Card umum aplikasi memakai:

```dart
static const Color surface = Color(0xFFFFFFFF);
```

Biasanya dipakai untuk:

- Card pesanan
- Card profil
- Box form
- Container putih
- Bottom navigation

Jika ingin semua card menjadi agak krem:

```dart
static const Color surface = Color(0xFFFFF8E1);
```

## 5. Mengganti Warna Box Paket Wisata

Card paket wisata menggunakan warna khusus:

```dart
static const Color cardGreen = Color(0xFFD6EED8);
```

Dipakai di file:

```text
lib/presentation/widgets/common/common_widgets.dart
```

Bagian widget:

```dart
class PackageCard extends StatelessWidget
```

Kode warnanya:

```dart
decoration: BoxDecoration(
  color: AppColors.cardGreen,
  borderRadius: BorderRadius.circular(16),
),
```

Jika dosen meminta box paket wisata diganti warna, ubah:

```dart
static const Color cardGreen = Color(0xFFD6EED8);
```

Contoh menjadi biru muda:

```dart
static const Color cardGreen = Color(0xFFE3F2FD);
```

## 6. Mengganti Warna Tombol Utama

Tombol utama mengikuti konfigurasi global di:

```text
lib/core/theme/app_theme.dart
```

Bagian:

```dart
elevatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
  ),
),
```

Jika ingin semua tombol utama menjadi biru, ubah `AppColors.primary`.

Jika ingin warna teks tombol menjadi putih, ubah:

```dart
static const Color textOnPrimary = Color(0xFFFFFFFF);
```

## 7. Mengganti Warna Tombol Booking di PackageCard

Tombol `Booking` di card paket wisata berada di:

```text
lib/presentation/widgets/common/common_widgets.dart
```

Bagian:

```dart
ElevatedButton.styleFrom(
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
)
```

Jika hanya tombol Booking yang ingin diganti tanpa memengaruhi tombol lain, ganti langsung menjadi:

```dart
backgroundColor: Color(0xFF2196F3),
foregroundColor: Colors.white,
```

Namun cara yang lebih rapi tetap memakai warna dari `AppColors`.

## 8. Mengganti Warna Bottom Navigation

Bottom navigation custom berada di:

```text
lib/presentation/widgets/common/app_bottom_navbar.dart
```

Bagian warna background bawah:

```dart
color: AppColors.surface,
```

Bagian warna item aktif:

```dart
color: active ? AppColors.primaryLight : Colors.transparent,
```

Bagian warna icon aktif:

```dart
color: active ? AppColors.primary : AppColors.textHint,
```

Jika dosen meminta warna menu aktif diganti, ubah:

```dart
static const Color primary = Color(0xFF...);
static const Color primaryLight = Color(0xFF...);
```

## 9. Mengganti Warna Status Pesanan

Status pesanan memakai `StatusBadge` di:

```text
lib/presentation/widgets/common/common_widgets.dart
```

Bagian pemetaan status:

```dart
Color get _color {
  switch (status) {
    case 'pending':   return AppColors.statusPending;
    case 'confirmed': return AppColors.statusConfirmed;
    case 'ongoing':   return AppColors.statusOngoing;
    case 'completed': return AppColors.statusCompleted;
    case 'cancelled': return AppColors.statusCancelled;
    default:          return AppColors.textHint;
  }
}
```

Warna status bisa diubah di:

```text
lib/core/theme/app_theme.dart
```

Contoh:

```dart
static const Color statusPending = Color(0xFFFFB800);
static const Color statusConfirmed = Color(0xFF2196F3);
static const Color statusOngoing = Color(0xFF9C27B0);
static const Color statusCompleted = Color(0xFF39E07A);
static const Color statusCancelled = Color(0xFFE53935);
```

Jika dosen meminta status `pending` menjadi merah muda:

```dart
static const Color statusPending = Color(0xFFE91E63);
```

## 10. Mengganti Warna TextField / Input Form

Warna input form berada di:

```text
lib/core/theme/app_theme.dart
```

Bagian:

```dart
inputDecorationTheme: InputDecorationTheme(
  filled: true,
  fillColor: AppColors.surface,
  focusedBorder: OutlineInputBorder(
    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderSide: const BorderSide(color: AppColors.error, width: 1),
  ),
),
```

Keterangan:

| Bagian | Warna yang dipakai |
|---|---|
| Isi input | `AppColors.surface` |
| Border normal | `AppColors.divider` |
| Border saat diklik | `AppColors.primary` |
| Border error | `AppColors.error` |
| Hint text | `AppColors.textHint` |

## 11. Mengganti Warna Teks

Warna teks utama berada di:

```dart
static const Color textPrimary = Color(0xFF1A1A1A);
static const Color textSecondary = Color(0xFF666666);
static const Color textHint = Color(0xFFAAAAAA);
```

Keterangan:

| Warna | Fungsi |
|---|---|
| `textPrimary` | Judul, teks utama |
| `textSecondary` | Deskripsi, subtitle |
| `textHint` | Placeholder, icon nonaktif |
| `textOnPrimary` | Teks di atas tombol utama |

## 12. Mengganti Warna Card Statistik Admin

Card statistik admin berada di:

```text
lib/presentation/screens/admin/widgets/admin_stat_card.dart
```

Biasanya warna card dikirim dari parameter widget, misalnya dari halaman admin tab.

Cari pemanggilan seperti:

```dart
AdminStatCard(
  title: 'Total Pesanan',
  value: '10',
  icon: Icons.receipt_long,
  color: AppColors.primary,
)
```

Jika ingin mengubah warna card tertentu, ubah parameter `color` pada pemanggilan widget tersebut.

Contoh:

```dart
color: AppColors.info,
```

atau langsung:

```dart
color: Color(0xFF673AB7),
```

## 13. Mengganti Warna Icon atau Lingkaran Icon

Beberapa icon memakai warna seperti:

```dart
color: AppColors.primaryLight,
```

untuk background lingkaran, dan:

```dart
color: AppColors.primary,
```

untuk warna icon.

Contoh umum:

```dart
CircleAvatar(
  backgroundColor: AppColors.primaryLight,
  child: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
)
```

Jika ingin background icon menjadi kuning muda:

```dart
backgroundColor: Color(0xFFFFF3CD),
```

Jika ingin icon menjadi oranye:

```dart
color: Color(0xFFFF9800),
```

## 14. Mengganti Warna Box Manual di File Tertentu

Jika ada widget `Container` dengan warna langsung seperti ini:

```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
  ),
)
```

Bisa diganti menjadi:

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
  ),
)
```

Atau jika dosen meminta warna tertentu:

```dart
Container(
  decoration: BoxDecoration(
    color: Color(0xFFE3F2FD),
    borderRadius: BorderRadius.circular(16),
  ),
)
```

## 15. Rekomendasi Warna yang Aman untuk Demo

| Nama Warna | HEX | Flutter |
|---|---|---|
| Hijau utama | `#39E07A` | `Color(0xFF39E07A)` |
| Biru | `#2196F3` | `Color(0xFF2196F3)` |
| Biru muda | `#E3F2FD` | `Color(0xFFE3F2FD)` |
| Ungu | `#9C27B0` | `Color(0xFF9C27B0)` |
| Kuning | `#FFB800` | `Color(0xFFFFB800)` |
| Oranye | `#FF9800` | `Color(0xFFFF9800)` |
| Merah | `#E53935` | `Color(0xFFE53935)` |
| Abu background | `#F5F5F0` | `Color(0xFFF5F5F0)` |
| Putih | `#FFFFFF` | `Color(0xFFFFFFFF)` |
| Hitam teks | `#1A1A1A` | `Color(0xFF1A1A1A)` |

## 16. Contoh Permintaan Dosen dan Bagian yang Diubah

### A. "Ubah warna background aplikasi"

Ubah:

```dart
static const Color background = Color(0xFFF5F5F0);
```

### B. "Ubah warna box paket wisata"

Ubah:

```dart
static const Color cardGreen = Color(0xFFD6EED8);
```

### C. "Ubah warna tombol"

Ubah:

```dart
static const Color primary = Color(0xFF39E07A);
static const Color textOnPrimary = Color(0xFF0A3020);
```

### D. "Ubah warna menu bawah yang aktif"

Ubah:

```dart
static const Color primary = Color(0xFF39E07A);
static const Color primaryLight = Color(0xFFD6EED8);
```

### E. "Ubah warna status pending / selesai / batal"

Ubah:

```dart
static const Color statusPending = Color(0xFFFFB800);
static const Color statusCompleted = Color(0xFF39E07A);
static const Color statusCancelled = Color(0xFFE53935);
```

## 17. Tips Agar Tidak Error Saat Mengubah Warna

1. Jangan hapus `0xFF` di depan kode warna.
2. Jangan lupa pakai titik koma `;` di akhir baris.
3. Jika memakai `AppColors`, pastikan file sudah import:

```dart
import 'package:jepora/core/theme/app_theme.dart';
```

4. Setelah mengubah warna, jalankan:

```bash
flutter clean
flutter pub get
flutter run
```

5. Jika hanya perubahan warna tidak terlihat, coba lakukan **Hot Restart**, bukan hanya Hot Reload.

## 18. Kesimpulan

Untuk mengganti warna bagian tertentu, prioritas pertama adalah cek file:

```text
lib/core/theme/app_theme.dart
```

Karena sebagian besar warna aplikasi sudah dipusatkan di `AppColors`.

Jika warna yang diminta dosen hanya berlaku pada satu widget tertentu, cari widget tersebut lalu ubah properti:

```dart
color:
backgroundColor:
foregroundColor:
border: Border.all(color: ...)
```

Dengan cara ini, perubahan warna bisa dilakukan cepat tanpa mengubah struktur kode utama.
