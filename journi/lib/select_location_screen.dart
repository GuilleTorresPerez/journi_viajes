import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import 'application/entry_service.dart';
import 'application/shared/result.dart';
import 'application/use_cases/entry_use_cases.dart';
import 'domain/entry.dart';
import 'domain/ports/entry_repository.dart';

/// Lo que devolvemos al guardar
class SelectedLocation {
  final String name;
  final LatLng position;

  SelectedLocation({required this.name, required this.position});
}

class SelectLocationScreen extends StatefulWidget {
  final String? initialName;
  final LatLng? initialPosition;
  final Entry entry;
  final EntryService entryService;
  final EntryRepository entryRepo;
  const SelectLocationScreen(
      {super.key,
      this.initialPosition,
      this.initialName,
      required this.entry,
      required this.entryRepo,
      required this.entryService});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final MapController _mapController = MapController();

  late LatLng _center;
  LatLng? _selected;

  @override
  void initState() {
    super.initState();

    // Si se pasa una posición inicial, úsala; si no, usa Madrid
    _center = widget.initialPosition ?? LatLng(40.4168, -3.7038);
    _selected = widget.initialPosition;
    _nameController.text = widget.initialName ?? '';

    if (widget.entry.location != null) {
      final loc = widget.entry.location!;
      _center = LatLng(loc.lat, loc.lon);
      _selected = _center;

      // Cargar el nombre guardado (o el initialName si tú lo usas)
      _nameController.text = widget.initialName ?? widget.entry.text ?? '';

      // Mover el mapa tras construir widgets
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_center, 14.0);
      });
    }
    // Caso 2: NO hay ubicación guardada → usar initialPosition o Madrid
    else {
      _center = widget.initialPosition ?? LatLng(40.4168, -3.7038);
      _selected = widget.initialPosition;
      _nameController.text = widget.initialName ?? '';

      if (widget.initialPosition != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(widget.initialPosition!, 14.0);
        });
      }
    }
  }

  /// 🔍 Buscar dirección en Nominatim (OpenStreetMap)
  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent':
              'journi/1.0 (developer@jorni.local)', // requerido por Nominatim
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data.first['lat']);
          final lon = double.parse(data.first['lon']);
          setState(() {
            _center = LatLng(lat, lon);
            _selected = _center;
            _mapController.move(_center, 14.0);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                key: Key('ubicacionNoExiste'),
                content: Text('No se encontró esa ubicación')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error HTTP ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error buscando ubicación: $e')));
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLocation() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una ubicación primero')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final tag = name.isEmpty ? 'Ubicación sin nombre' : name;

    // 1. Crear nuevo objeto location del dominio
    final newLocation = EntryLocation(
      lat: _selected!.latitude,
      lon: _selected!.longitude,
    );

    // 2. Crear nueva versión validada del Entry
    final updatedResult = widget.entry.copyValidated(
      location: newLocation,
      tags: [tag], // Reemplaza tags con solo esta ubicación
    );

    // 3. Manejar errores de validación
    if (updatedResult is Err<Entry>) {
      final errors = updatedResult.errors.map((e) => e.message).join("\n");

      _showError("Error al actualizar:\n$errors");
      return;
    }

    final updatedEntry = (updatedResult as Ok<Entry>).value;

    // 4. Persistir con update() — NO usar create()
    final saveResult = await widget.entryService.update(
      UpdateEntryCommand(
        id: updatedEntry.id,
        text: updatedEntry.text,
        location: updatedEntry.location,
        tags: updatedEntry.tags,
        updatedAt: DateTime.now(),
      ),
    );

    // 5. Comprobar si falló
    if (saveResult is Err<Entry>) {
      final errors = saveResult.errors.map((e) => e.message).join("\n");
      _showError("Error al guardar:\n$errors");
      return;
    }

    // 6. Todo OK → volver
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
        backgroundColor: Colors.teal[700],
      ),
      body: Column(
        children: [
          // 🔍 Buscador
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('nombreUbicacion'),
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar dirección...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const Key('buscaUbicacion'),
                  icon: const Icon(Icons.search, color: Colors.teal),
                  onPressed: _searchLocation,
                ),
              ],
            ),
          ),

          // ✏️ Nombre opcional
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              key: const Key('tituloUbicacion'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la ubicación (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 🗺️ Mapa
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 6,
                onTap: (tapPosition, latLng) {
                  setState(() {
                    _selected = latLng;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.journi',
                ),
                if (_selected != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selected!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ➕ Botones
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                FloatingActionButton.extended(
                  heroTag: 'save',
                  backgroundColor: Colors.teal,
                  onPressed: _saveLocation,
                  key: const Key('guardarUbicacion'),
                  icon: const Icon(Icons.check),
                  label: const Text('Guardar ubicación'),
                ),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
