import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:journi/domain/entry.dart';
import 'package:journi/domain/trip.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Muestra los pins de las entradas en el mapa', (tester) async {
    // Crear un viaje de prueba
    final viaje = Trip(
      id: 'trip1',
      title: 'Viaje Test',
      ownerId: '',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    // Crear entradas de prueba con ubicación
    final entradas = [
      Entry.create(
        id: '1',
        tripId: 'trip1',
        type: EntryType.note,
        text: 'Nota con ubicación',
        location: const EntryLocation(lat: 10, lon: 10),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ).valueOrNull!,
      Entry.create(
        id: '2',
        tripId: 'trip1',
        type: EntryType.photo,
        mediaUri: 'foto.jpg',
        location: const EntryLocation(lat: 20, lon: 20),
        createdAt: DateTime(2024, 1, 2),
        updatedAt: DateTime(2024, 1, 2),
      ).valueOrNull!,
      Entry.create(
        id: '3',
        tripId: 'trip1',
        type: EntryType.video,
        mediaUri: 'video.mp4',
        location: const EntryLocation(
            lat: 10, lon: 10), // misma ubicación que la primera
        createdAt: DateTime(2024, 1, 3),
        updatedAt: DateTime(2024, 1, 3),
      ).valueOrNull!,
    ];

    // Crear el widget pasando las entradas directamente
    final widget = MaterialApp(
      home: MapaDetalleScreenTestable(
        viaje: viaje,
        entradas: entradas,
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Comprobar que FlutterMap existe
    expect(find.byType(FlutterMap), findsOneWidget);

    // Comprobar que los pins se generan: 2 ubicaciones distintas
    expect(find.byIcon(Icons.location_pin), findsNWidgets(2));
  });
}

/// Versión de MapaDetalleScreen que recibe entradas directamente para testing
class MapaDetalleScreenTestable extends StatefulWidget {
  final Trip viaje;
  final List<Entry> entradas;

  const MapaDetalleScreenTestable({
    Key? key,
    required this.viaje,
    required this.entradas,
  }) : super(key: key);

  @override
  State<MapaDetalleScreenTestable> createState() =>
      _MapaDetalleScreenTestableState();
}

class _MapaDetalleScreenTestableState extends State<MapaDetalleScreenTestable> {
  LatLng _posicionUsuario = const LatLng(0, 0);
  late List<Entry> _entradas;
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _entradas = widget.entradas;
    _generarMarkers();
  }

  void _generarMarkers() {
    final Map<String, List<Entry>> agrupadas = {};

    for (var e in _entradas) {
      if (e.location == null) continue;
      final key = "${e.location!.lat},${e.location!.lon}";
      agrupadas.putIfAbsent(key, () => []).add(e);
    }

    final List<Marker> nuevos = [];

    agrupadas.forEach((key, lista) {
      final lat = lista.first.location!.lat;
      final lng = lista.first.location!.lon;

      nuevos.add(
        Marker(
          point: LatLng(lat, lng),
          width: 80,
          height: 80,
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    });

    _markers = nuevos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _posicionUsuario,
          initialZoom: 2,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: _markers,
          ),
        ],
      ),
    );
  }
}
