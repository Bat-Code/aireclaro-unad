import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../models/report_draft.dart';
import 'petitioner_screen.dart';

class LocationScreen extends StatefulWidget {
  final ReportDraft draft;
  const LocationScreen({super.key, required this.draft});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _map = MapController();
  bool _mapReady = false;
  bool _loading = false;
  String? _error;
  LatLng? _point;
  DateTime? _fecha;

  // Centro por defecto: Soacha
  static const _soacha = LatLng(4.5794, -74.2168);

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'El GPS está apagado. Actívalo e intenta de nuevo.';
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw 'Permiso de ubicación denegado. Actívalo en los ajustes del teléfono.';
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final p = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _point = p;
        _fecha = DateTime.now();
      });
      if (_mapReady) _map.move(p, 16);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

    void _next() {
    if (_point == null || _fecha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aún no hay ubicación')));
      return;
    }
    final d = widget.draft;
    d.latitud = _point!.latitude;
    d.longitud = _point!.longitude;
    d.fechaHora = _fecha;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => PetitionerScreen(draft: d)));
  }

  @override
  Widget build(BuildContext context) {
    final p = _point;
    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación y hora')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Paso 3/4'),
            const LinearProgressIndicator(value: 0.75),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: p ?? _soacha,
                    initialZoom: p == null ? 12 : 16,
                    onMapReady: () => _mapReady = true,
                    onTap: (_, point) => setState(() => _point = point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.aireclaro.aireclaro',
                    ),
                    if (p != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: p,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: const Icon(Icons.location_pin,
                              color: Colors.red, size: 40),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Toca el mapa si necesitas corregir el punto.',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ListTile(
              dense: true,
              leading: const Icon(Icons.place),
              title: Text(p == null
                  ? 'Buscando ubicación...'
                  : '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}'),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.access_time),
              title: Text(_fecha == null
                  ? '--'
                  : DateFormat('dd/MM/yyyy HH:mm').format(_fecha!)),
            ),
            OutlinedButton.icon(
              onPressed: _loading ? null : _locate,
              icon: const Icon(Icons.my_location),
              label: const Text('Actualizar ubicación'),
            ),
            FilledButton(onPressed: _next, child: const Text('Siguiente')),
          ],
        ),
      ),
    );
  }
}