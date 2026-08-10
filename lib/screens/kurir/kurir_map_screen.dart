import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../models/order.dart';
import '../../services/ws_service.dart';

class KurirMapScreen extends StatefulWidget {
  final List<Order> activeOrders;
  const KurirMapScreen({super.key, required this.activeOrders});

  @override
  State<KurirMapScreen> createState() => _KurirMapScreenState();
}

class _KurirMapScreenState extends State<KurirMapScreen> {
  final _mapCtrl = MapController();
  final _ws = WsService.instance;
  LatLng? _position;
  Position? _lastPos;
  bool _tracking = false;
  String? _err;
  StreamSubscription<Position>? _sub;

  @override
  void initState() {
    super.initState();
    _ws.connect();
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      setState(() => _err = 'Layanan lokasi nonaktif. Nyalakan GPS untuk mengirim posisi.');
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      setState(() => _err = 'Izin lokasi ditolak. Beri izin untuk mengirim posisi live.');
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition();
      _update(pos);
      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen(_update);
      setState(() => _tracking = true);
    } catch (e) {
      setState(() => _err = '$e');
    }
  }

  void _update(Position p) {
    if (!mounted) return;
    setState(() {
      _position = LatLng(p.latitude, p.longitude);
      _lastPos = p;
    });
    final orderIds = widget.activeOrders.map((o) => o.id).toList();
    if (orderIds.isNotEmpty) {
      _ws.sendLocation(orderIds, p.latitude, p.longitude);
    }
    final center = _mapCtrl.camera.center;
    final dist = const Distance().distance(center, _position!);
    if (dist > 3000) {
      _mapCtrl.move(_position!, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = widget.activeOrders;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kirim Lokasi Live', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _err != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 56, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text('$_err', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _start, child: const Text('Coba lagi')),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: _position ?? const LatLng(-3.42, 119.31),
                    initialZoom: 15,
                    onTap: (_, point) => setState(() => _position = point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.marketkita_app',
                    ),
                    if (_position != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: _position!,
                          width: 42,
                          height: 42,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF171717),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
                            ),
                            child: const Icon(Icons.two_wheeler, color: Colors.white, size: 20),
                          ),
                        ),
                      ]),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(_tracking ? Icons.gps_fixed : Icons.gps_off, size: 18, color: _tracking ? Colors.green : Colors.grey),
                            const SizedBox(width: 6),
                            Text(_tracking ? 'Lokasi aktif dikirim' : 'Menunggu lokasi...',
                                style: TextStyle(fontWeight: FontWeight.w700, color: _tracking ? Colors.green : Colors.grey)),
                            const Spacer(),
                            Text('${orders.length} order', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        if (_lastPos != null) ...[
                          const SizedBox(height: 4),
                          Text('${_lastPos!.latitude.toStringAsFixed(5)}, ${_lastPos!.longitude.toStringAsFixed(5)}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_position != null)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: FloatingActionButton.small(
                      backgroundColor: const Color(0xFF171717),
                      foregroundColor: Colors.white,
                      heroTag: 'center',
                      onPressed: () => _mapCtrl.move(_position!, 15),
                      child: const Icon(Icons.my_location),
                    ),
                  ),
              ],
            ),
    );
  }
}
