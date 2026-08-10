import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Picker lokasi untuk checkout: pilih titik di peta atau pakai posisi GPS saat ini.
/// Mengembalikan (lat, lng, label alamat) saat tombol konfirmasi ditekan.
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initial;
  const LocationPickerScreen({super.key, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapCtrl = MapController();
  final _geocoding = Geocoding();
  late LatLng _picked;
  bool _locating = false;
  String? _address;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial ?? const LatLng(-3.422, 119.325);
  }

  Future<void> _useCurrent() async {
    setState(() => _locating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _snack('Layanan lokasi nonaktif.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _snack('Izin lokasi ditolak.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _picked = LatLng(pos.latitude, pos.longitude));
      _mapCtrl.move(_picked, 16);
      await _reverse();
    } catch (e) {
      _snack('Gagal ambil lokasi: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _reverse() async {
    try {
      final places = await _geocoding.placemarkFromCoordinates(_picked.latitude, _picked.longitude);
      if (places.isNotEmpty) {
        final p = places.first;
        final parts = [
          p.street ?? '',
          p.subLocality ?? '',
          p.locality ?? '',
          p.administrativeArea ?? '',
        ].where((s) => s.isNotEmpty).toList();
        setState(() => _address = parts.join(', '));
      }
    } catch (_) {}
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Lokasi Pengiriman', style: TextStyle(fontWeight: FontWeight.w800))),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _picked,
              initialZoom: 15,
              onTap: (_, point) {
                setState(() => _picked = point);
                _reverse();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.marketkita_app',
              ),
            ],
          ),
          // pin di tengah
          IgnorePointer(
            child: Center(
              child: Icon(Icons.location_on, size: 48, color: Colors.red.shade600, shadows: [Shadow(color: Colors.black26, blurRadius: 6)]),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)]),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _address ?? '${_picked.latitude.toStringAsFixed(5)}, ${_picked.longitude.toStringAsFixed(5)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 16,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF171717),
              foregroundColor: Colors.white,
              heroTag: 'gps',
              onPressed: _locating ? null : _useCurrent,
              child: _locating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, {'lat': _picked.latitude, 'lng': _picked.longitude, 'label': _address ?? ''}),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF171717), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Gunakan Lokasi Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
