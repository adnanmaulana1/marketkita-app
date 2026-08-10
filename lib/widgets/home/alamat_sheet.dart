import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/alamat_kirim.dart';
import '../../screens/location_picker_screen.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text.dart';

/// Bottom sheet pemilihan alamat kirim (dari header "Kirim ke ...").
Future<void> showAlamatSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => const AlamatSheet(),
  );
}

class AlamatSheet extends StatelessWidget {
  const AlamatSheet({super.key});

  IconData _labelIcon(String label) {
    switch (label.toLowerCase()) {
      case 'kantor':
        return Icons.business_outlined;
      case 'lainnya':
        return Icons.place_outlined;
      default:
        return Icons.home_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = app.alamatList;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Pilih Alamat Pengiriman',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.neutral900)),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  icon: const Icon(Icons.close, size: 20, color: AppColors.neutral600),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (list.isEmpty)
            _emptyState(context)
          else
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => _alamatTile(context, app, list[i]),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: FilledButton.icon(
              onPressed: () => _openTambah(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambahkan Alamat'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Column(
        children: [
          const Icon(Icons.location_off_outlined, size: 40, color: AppColors.neutral400),
          const SizedBox(height: AppSpacing.sm),
          const Text('Belum ada alamat tersimpan', style: AppText.title),
          const SizedBox(height: 4),
          Text(
            'Tambahkan alamat agar pengiriman lebih mudah.',
            textAlign: TextAlign.center,
            style: AppText.caption,
          ),
        ],
      ),
    );
  }

  Widget _alamatTile(BuildContext context, AppState app, AlamatKirim a) {
    final aktif = app.alamatAktif?.id == a.id;
    return Material(
      color: AppColors.neutral100,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          app.setAlamatAktif(a);
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(_labelIcon(a.label), size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.label,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.neutral900),
                    ),
                    if (a.namaPenerima.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(a.namaPenerima, style: AppText.caption.copyWith(color: AppColors.neutral700)),
                    ],
                    if (a.alamat.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        a.alamat,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption,
                      ),
                    ],
                    if (a.telepon.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(a.telepon, style: AppText.caption.copyWith(color: AppColors.neutral600)),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Hapus alamat',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.neutral400),
                onPressed: () {
                  app.hapusAlamat(a.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alamat dihapus')),
                  );
                },
              ),
              const SizedBox(width: 2),
              Icon(
                aktif ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: aktif ? AppColors.primary : AppColors.neutral300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTambah(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const _TambahAlamatSheet(),
    );
  }
}

class _TambahAlamatSheet extends StatefulWidget {
  const _TambahAlamatSheet();

  @override
  State<_TambahAlamatSheet> createState() => _TambahAlamatSheetState();
}

class _TambahAlamatSheetState extends State<_TambahAlamatSheet> {
  static const _labels = ['Rumah', 'Kantor', 'Lainnya'];

  final _nama = TextEditingController();
  final _telepon = TextEditingController();
  final _alamat = TextEditingController();
  String _label = 'Rumah';
  double? _lat;
  double? _lng;
  bool _saving = false;

  @override
  void dispose() {
    _nama.dispose();
    _telepon.dispose();
    _alamat.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pilihDiPeta() async {
    final res = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (!mounted || res == null) return;
    setState(() {
      _lat = res['lat'] as double?;
      _lng = res['lng'] as double?;
      final label = res['label'] as String? ?? '';
      if (_alamat.text.trim().isEmpty && label.isNotEmpty) {
        _alamat.text = label;
      }
    });
  }

  Future<void> _simpan() async {
    if (_nama.text.trim().isEmpty) {
      _snack('Nama penerima wajib diisi.');
      return;
    }
    if (_alamat.text.trim().isEmpty) {
      _snack('Alamat lengkap wajib diisi.');
      return;
    }
    setState(() => _saving = true);
    final app = context.read<AppState>();
    await app.saveAlamat(
      AlamatKirim(
        id: DateTime.now().millisecondsSinceEpoch,
        label: _label,
        namaPenerima: _nama.text.trim(),
        telepon: _telepon.text.trim(),
        alamat: _alamat.text.trim(),
        lat: _lat,
        lng: _lng,
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alamat berhasil disimpan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Tambahkan Alamat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.neutral900),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final l in _labels)
                    ChoiceChip(
                      label: Text(l),
                      selected: _label == l,
                      onSelected: (_) => setState(() => _label = l),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.neutral100,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _label == l ? AppColors.white : AppColors.neutral700,
                      ),
                      checkmarkColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        side: BorderSide(
                          color: _label == l ? AppColors.primary : AppColors.neutral200,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _nama,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Penerima',
                  hintText: 'Nama penerima pesanan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _telepon,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'No. Telepon',
                  hintText: 'Nomor yang bisa dihubungi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _alamat,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alamat Lengkap',
                  hintText: 'Jalan, nomor rumah, patokan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _pilihDiPeta,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Pilih di Peta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.neutral300),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
              ),
              if (_lat != null && _lng != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text('Lokasi sudah dipilih di peta', style: AppText.caption.copyWith(color: AppColors.success)),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _saving ? null : _simpan,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : const Text('Simpan Alamat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
