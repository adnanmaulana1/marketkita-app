import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/order.dart';
import '../services/ws_service.dart';
import '../utils/format.dart';

class KurirTrackingScreen extends StatefulWidget {
  final Order order;
  const KurirTrackingScreen({super.key, required this.order});

  @override
  State<KurirTrackingScreen> createState() => _KurirTrackingScreenState();
}

class _KurirTrackingScreenState extends State<KurirTrackingScreen> {
  final _mapCtrl = MapController();
  final _ws = WsService.instance;
  LatLng? _kurirPos;

  @override
  void initState() {
    super.initState();
    _ws.connect();
    _ws.listen(_onEvent);
    _ws.sendPing();
  }

  @override
  void dispose() {
    _ws.removeAll(_onEvent);
    super.dispose();
  }

  void _onEvent(Map<String, dynamic> data) {
    if (!mounted) return;
    if (data['type'] == 'kurir_location' &&
        (data['order_id'] as num?)?.toInt() == widget.order.id) {
      final lat = data['lat'];
      final lng = data['lng'];
      if (lat is num && lng is num) {
        setState(() => _kurirPos = LatLng(lat.toDouble(), lng.toDouble()));
        _mapCtrl.move(_kurirPos!, 15);
      }
    }
  }

  LatLng? get _storePos {
    if (widget.order.storeLatitude != null && widget.order.storeLongitude != null) {
      return LatLng(widget.order.storeLatitude!, widget.order.storeLongitude!);
    }
    return null;
  }

  LatLng? get _destPos {
    if (widget.order.latitude != null && widget.order.longitude != null) {
      return LatLng(widget.order.latitude!, widget.order.longitude!);
    }
    return null;
  }

  LatLng get _initialCenter {
    if (widget.order.storeLatitude != null && widget.order.storeLongitude != null) {
      return LatLng(widget.order.storeLatitude!, widget.order.storeLongitude!);
    }
    if (widget.order.latitude != null && widget.order.longitude != null) {
      return LatLng(widget.order.latitude!, widget.order.longitude!);
    }
    return const LatLng(-3.42, 119.31);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Scaffold(
      appBar: AppBar(title: Text('Lacak ${o.nomor}', style: const TextStyle(fontWeight: FontWeight.w800))),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Row(
              children: [
                Icon(_kurirPos != null ? Icons.two_wheeler : Icons.location_searching, color: _kurirPos != null ? Colors.green : Colors.grey[400]),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _kurirPos != null ? 'Kurir sedang dalam perjalanan' : 'Menunggu posisi kurir...',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (_kurirPos != null)
                        Text(
                          '${_kurirPos!.latitude.toStringAsFixed(5)}, ${_kurirPos!.longitude.toStringAsFixed(5)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                if (_kurirPos != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                    child: Text(o.statusKurir.toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.marketkita_app',
                ),
                MarkerLayer(markers: [
                  if (_storePos != null)
                    Marker(
                      point: _storePos!,
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.storefront, color: Colors.orange, size: 32),
                    ),
                  if (_destPos != null)
                    Marker(
                      point: _destPos!,
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                    ),
                  if (_kurirPos != null)
                    Marker(
                      point: _kurirPos!,
                      width: 42,
                      height: 42,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
                        ),
                        child: const Icon(Icons.two_wheeler, color: Colors.white, size: 22),
                      ),
                    ),
                ]),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storefront, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(o.storeNama ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text('${o.namaPenerima} — ${o.alamat}', style: TextStyle(color: Colors.grey[700], fontSize: 13))),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Total ${rupiah(o.total)} · ${o.metodeBayar}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
