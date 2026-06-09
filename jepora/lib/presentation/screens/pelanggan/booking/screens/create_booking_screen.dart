part of '../booking_tab.dart';

class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {

  
  final _formKey    = GlobalKey<FormState>();
  final _notesCtrl  = TextEditingController();

  int? _selectedPkg;
  DateTime? _selectedDate;


  LatLng? _selectedLocation;
  String? _addressLabel;

  String? _selectedCurrency = 'IDR';
  double? _convertedPrice;

  bool _isConvertingCurrency = false;
  bool _currencyExpanded = false;

  final _voucherCtrl     = TextEditingController();
  Map<String, dynamic>? _appliedVoucher;
  double?               _discountAmount;
  bool                  _voucherLoading = false;
  String?               _voucherError;

  ///  Accept LocationModel dari location picker
  Future<void> _pickLocation() async {
    try {
      final result = await Navigator.pushNamed(context, '/location-picker');
      
      if (!mounted) return;
      
      debugPrint(' Location picker result: $result (Type: ${result.runtimeType})');
      
      //  Terima LocationModel, bukan LatLng
      if (result != null && result is LocationModel) {
        setState(() {
          _selectedLocation = LatLng(result.latitude, result.longitude);
          _addressLabel = result.label ?? 
              "${result.latitude.toStringAsFixed(5)}, ${result.longitude.toStringAsFixed(5)}";
        });
        debugPrint(' Location selected: $_addressLabel');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lokasi berhasil dipilih'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint(' Location picker returned null or invalid type: $result');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pilihan lokasi dibatalkan'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint(' Error in location picker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih lokasi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PackageService>().fetchPackages();
      // Setelah packages load, trigger konversi jika ada paket pre-selected
      if (_selectedPkg != null && _selectedCurrency != 'IDR' && mounted) {
        final packages = context.read<PackageService>().packages;
        final pkg = _findPackageById(packages, _selectedPkg!);
        if (pkg != null) _convertCurrency(pkg.price, _selectedCurrency!);
      }
    });
  }

  /// Override didChangeDependencies untuk accept packageId dari route arguments
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get packageId from route arguments jika passed dari home/detail page
    final args = ModalRoute.of(context)?.settings.arguments;
    
    if (args != null) {
      int? packageId;
      
      // Handle berbagai format argument yang mungkin dikirim
      if (args is Map<String, dynamic> && args.containsKey('packageId')) {
        packageId = args['packageId'] as int?;
      } else if (args is int) {
        // Jika langsung dikirim sebagai int
        packageId = args;
      }
      
      // Set _selectedPkg jika belum ada (hanya sekali)
      if (packageId != null && _selectedPkg == null) {
        _selectedPkg = packageId;
        debugPrint('📦 Package pre-selected: $_selectedPkg');
        
        // Trigger currency conversion untuk package yang dipilih
        if (_selectedCurrency != 'IDR') {
          final packages = context.read<PackageService>().packages;
          final pkg = _findPackageById(packages, packageId);
          if (pkg != null) {
            _convertCurrency(pkg.price, _selectedCurrency!);
          }
        }
      }
    }
  }

  ///  Find package by ID (kompatibel dengan semua versi Dart)
  PackageModel? _findPackageById(List<PackageModel> packages, int id) {
    try {
      return packages.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _convertCurrency(double price, String currency) async {
    if (currency == 'IDR') {
      setState(() => _convertedPrice = null);
      return;
    }
    setState(() => _isConvertingCurrency = true);
    final result = await CurrencyService.convert(
      amount: price, from: 'IDR', to: currency,
    );
    if (mounted) {
      setState(() {
        _convertedPrice = result != null ? (result['converted'] as num?)?.toDouble() : null;
        _isConvertingCurrency = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal booking'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ///  Better validation untuk location
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Pilih lokasi penjemputan terlebih dahulu'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      debugPrint(' Submit failed: No location selected');
      return;
    }

    debugPrint(' Form validation passed. Location: $_addressLabel');

    final orderService = context.read<OrderService>();

    final order = await orderService.createOrder(
      packageId:   _selectedPkg!,
      bookingDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),

      //  LOKASI DIPERBAIKI
      latitude:    _selectedLocation!.latitude,
      longitude:   _selectedLocation!.longitude,

      notes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),

      voucherId: _appliedVoucher != null
          ? (_appliedVoucher!['id'] as int?)
          : null,

    );

    if (!mounted) return;

    if (order != null) {
      try {
        final packages = context.read<PackageService>().packages;
        final pkg = _findPackageById(packages, _selectedPkg!);
        await LocalNotificationService().scheduleBookingReminder(
          orderId: order.id,
          packageName: pkg?.name ?? order.packageName ?? 'Paket Wisata',
          bookingDate: _selectedDate!,
          pickupAddress: _addressLabel,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking berhasil. Reminder jadwal wisata sudah diaktifkan.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        debugPrint('Gagal menjadwalkan reminder booking: $e');
      }

      Navigator.pushReplacementNamed(
        context,
        '/upload-payment',
        arguments: order,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderService.error ?? 'Gagal membuat pesanan'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _applyVoucher(double price) async {
    final code = _voucherCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _voucherLoading = true; _voucherError = null; _appliedVoucher = null; _discountAmount = null; });
    try {
      final res = await ApiClient().dio.get('/vouchers/validate', queryParameters: {'code': code});
      if (res.data['success'] == true) {
        final v = res.data['voucher'] as Map<String, dynamic>;
        // MySQL decimal dikembalikan sebagai String di Node.js — parse manual
        double? parseNum(dynamic val) => val == null ? null : double.tryParse(val.toString());

        final minOrder = parseNum(v['min_order']);
        if (minOrder != null && price < minOrder) {
          final fmt = minOrder.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => m[1]! + '.');
          setState(() => _voucherError = 'Minimal order Rp $fmt');
          return;
        }
        double disc;
        if (v['type'] == 'percent') {
          disc = price * (parseNum(v['value']) ?? 0) / 100;
          final mx = parseNum(v['max_discount']);
          if (mx != null && disc > mx) disc = mx;
        } else {
          disc = parseNum(v['value']) ?? 0;
        }
        if (disc > price) disc = price;
        setState(() { _appliedVoucher = v; _discountAmount = disc; });
      } else {
        setState(() => _voucherError = res.data['message'] ?? 'Voucher tidak valid');
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg    = e.response?.data?['message'];
      if (status == 401) {
        setState(() => _voucherError = 'Sesi habis, silakan login ulang');
      } else if (status == 404) {
        setState(() => _voucherError = msg ?? 'Voucher tidak valid atau sudah kadaluarsa');
      } else {
        setState(() => _voucherError = msg ?? 'Gagal menghubungi server (${status ?? 'no connection'})');
      }
    } catch (e) {
      setState(() => _voucherError = 'Error: $e');
    } finally {
      if (mounted) setState(() => _voucherLoading = false);
    }
  }

  void _removeVoucher() => setState(() {
    _appliedVoucher = null; _discountAmount = null;
    _voucherError = null; _voucherCtrl.clear();
  });

  @override
  void dispose() {
    _notesCtrl.dispose();
    _voucherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final packages     = context.watch<PackageService>();
    final orderService = context.watch<OrderService>();
    final selectedPkg  = _selectedPkg != null
        ? _findPackageById(packages.packages, _selectedPkg!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Buat Booking')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paket Wisata', style: AppTextStyles.label),
              const SizedBox(height: 8),
              //  Jika paket sudah dipilih dari route arguments, tampilkan fixed — tidak bisa diganti
              if (_selectedPkg != null && selectedPkg != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedPkg.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Paket sudah dipilih',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Jika belum ada paket dipilih (masuk manual), tampilkan dropdown
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: DropdownButtonFormField<int>(
                    value: _selectedPkg,
                    hint: const Text('Pilih paket', style: TextStyle(fontFamily: 'Poppins')),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    items: packages.packages.map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name, style: AppTextStyles.body),
                    )).toList(),
                    onChanged: (v) {
                      setState(() { _selectedPkg = v; _convertedPrice = null; });
                      if (v != null && _selectedCurrency != null) {
                        final pkg = _findPackageById(packages.packages, v);
                        if (pkg != null) {
                          _convertCurrency(pkg.price, _selectedCurrency!);
                        }
                      }
                    },
                    validator: (v) => v == null ? 'Pilih paket wisata' : null,
                  ),
                ),

              if (selectedPkg != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rp ${selectedPkg.price.toStringAsFixed(0).replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                  style: AppTextStyles.price,
                                ),
                                const SizedBox(height: 2),
                                if (_isConvertingCurrency)
                                  const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppColors.primary,
                                    ),
                                  )
                                else if (_convertedPrice != null && _selectedCurrency != 'IDR')
                                  Text(
                                    '≈ $_selectedCurrency ${_convertedPrice!.toStringAsFixed(2)}',
                                    style: AppTextStyles.caption,
                                  ),
                              ],
                            ),
                          ),
                          // Tombol pilih mata uang
                          GestureDetector(
                            onTap: () => setState(() => _currencyExpanded = !_currencyExpanded),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.currency_exchange_rounded,
                                      size: 13, color: AppColors.primary),
                                  const SizedBox(width: 5),
                                  Text(
                                    _selectedCurrency ?? 'IDR',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    _currencyExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Panel pilih mata uang
                      if (_currencyExpanded) ...[
                        const SizedBox(height: 10),
                        const Divider(color: AppColors.divider, height: 1),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: ['IDR', 'USD', 'EUR', 'SGD'].map((c) {
                            final isActive = c == (_selectedCurrency ?? 'IDR');
                            return GestureDetector(
                              onTap: () {
                                final currency = c;
                                setState(() {
                                  _selectedCurrency = currency;
                                  _currencyExpanded = false;
                                  _convertedPrice = null;
                                });
                                _convertCurrency(selectedPkg.price, currency);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.primary : AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActive ? AppColors.primary : AppColors.divider,
                                  ),
                                ),
                                child: Text(
                                  c,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                    color: isActive ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const Text('Tanggal Booking', style: AppTextStyles.label),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(primary: AppColors.primary),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.textHint, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate != null
                            ? DateFormat('EEEE, dd MMMM yyyy', 'id').format(_selectedDate!)
                            : 'Pilih tanggal',
                        style: _selectedDate != null ? AppTextStyles.body : AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text('Lokasi Penjemputan', style: AppTextStyles.label),
              const SizedBox(height: 8),

              ///  Location picker dengan visual feedback
              GestureDetector(
                onTap: _pickLocation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedLocation != null
                        ? AppColors.primaryLight
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedLocation != null
                          ? AppColors.primary
                          : AppColors.divider,
                      width: _selectedLocation != null ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: _selectedLocation != null
                            ? AppColors.primary
                            : AppColors.textHint,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedLocation != null
                                  ? "Lokasi Dipilih ✓"
                                  : 'Tap untuk pilih lokasi di map',
                              style: _selectedLocation != null
                                  ? const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                    color: AppColors.primary,
                                  )
                                  : AppTextStyles.bodyMuted,
                            ),
                            if (_selectedLocation != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _addressLabel ?? '',
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text('Catatan (opsional)', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Contoh: Jemput di hotel jam 05.00',
                controller: _notesCtrl,
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // ── Voucher ─────────────────────────────────
              const Text('Kode Voucher (opsional)', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _voucherCtrl,
                      enabled: _appliedVoucher == null,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontSize: 14, fontFamily: 'Poppins',
                          color: AppColors.textPrimary, letterSpacing: 1.2),
                      decoration: InputDecoration(
                        hintText: 'Masukkan kode voucher',
                        hintStyle: const TextStyle(fontSize: 13, fontFamily: 'Poppins',
                            color: AppColors.textHint, letterSpacing: 0),
                        filled: true,
                        fillColor: _appliedVoucher == null ? AppColors.surface : AppColors.primaryLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.divider)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.4))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    height: 52,
                    child: _appliedVoucher == null
                        ? ElevatedButton(
                            onPressed: _voucherLoading ? null : () {
                              final packages = context.read<PackageService>().packages;
                              final pkg = _findPackageById(packages, _selectedPkg!);
                              if (pkg != null) _applyVoucher(pkg.price);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.zero,
                            ),
                            child: _voucherLoading
                                ? const SizedBox(width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Pakai',
                                    style: TextStyle(fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13, color: Colors.white)),
                          )
                        : ElevatedButton(
                            onPressed: _removeVoucher,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error.withOpacity(0.1),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: AppColors.error.withOpacity(0.4))),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Hapus',
                                style: TextStyle(fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13, color: AppColors.error)),
                          ),
                  ),
                ],
              ),

              if (_voucherError != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_voucherError!, style: const TextStyle(
                      fontSize: 12, fontFamily: 'Poppins', color: AppColors.error))),
                ]),
              ],

              if (_appliedVoucher != null && _discountAmount != null) ...[
                const SizedBox(height: 10),
                Builder(builder: (ctx) {
                  final packages = context.read<PackageService>().packages;
                  final pkg = _findPackageById(packages, _selectedPkg!);
                  if (pkg == null) return const SizedBox.shrink();
                  final fmt = (double v) => 'Rp ' + v.toStringAsFixed(0)
                      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => m[1]! + '.');
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: Column(children: [
                      Row(children: [
                        const Icon(Icons.local_offer_rounded, size: 15, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_appliedVoucher!['description'] ?? _appliedVoucher!['code'],
                          style: const TextStyle(fontSize: 12, fontFamily: 'Poppins',
                              color: AppColors.primary, fontWeight: FontWeight.w600))),
                      ]),
                      const Divider(height: 14, color: AppColors.divider),
                      _VoucherRow(label: 'Harga Paket', value: fmt(pkg.price)),
                      _VoucherRow(label: 'Diskon', value: '- ' + fmt(_discountAmount!), valueColor: AppColors.error),
                      const Divider(height: 10, color: AppColors.divider),
                      _VoucherRow(label: 'Total', value: fmt(pkg.price - _discountAmount!), bold: true),
                    ]),
                  );
                }),
              ],

              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Konfirmasi Booking',
                isLoading: orderService.isLoading,
                onPressed: _submit,
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

