import 'package:flutter/material.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_trip_repository.dart';
import 'package:journi/domain/ports/entry_repository.dart';
import 'package:journi/domain/trip.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'application/entry_service.dart';
import 'application/trip_service.dart';
import 'application/user_service.dart';
import 'crear_viaje.dart';
import 'data/local/drift/drift_user_repository.dart';
import 'domain/entry.dart';
import 'domain/ports/trip_repository.dart';
import 'domain/ports/user_repository.dart';
import 'login_screen.dart';
import 'main.dart';

//
// 🔹 Pantalla principal: lista de viajes
//
// ignore: must_be_immutable
class MapaPaisScreen extends StatefulWidget {
  final bool sesionIniciada;
  int selectedIndex;
  List<Trip> viajes;
  final TripRepository tripRepo;
  final EntryRepository entryRepo;
  final TripService tripService;
  final EntryService entryService;
  final UserRepository userRepo;
  final UserService userService;

  MapaPaisScreen({
    super.key,
    required this.viajes,
    required this.sesionIniciada,
    required this.selectedIndex,
    required this.tripRepo,
    required this.entryRepo,
    required this.tripService,
    required this.entryService,
    required this.userRepo,
    required this.userService,
  });

  @override
  State<MapaPaisScreen> createState() => _MapaPaisScreenState();
}

class _MapaPaisScreenState extends State<MapaPaisScreen> {
  final TripRepository tripRepo = DriftTripRepository(AppDatabase());
  final UserRepository userRepo = DriftUserRepository(AppDatabase());
  late final userService;
  List<Trip>? _viajes;
  late int _selectedIndex = widget.selectedIndex;

  @override
  void initState() {
    super.initState();
    _cargarViajes();
    userService = makeUserService(userRepo);
  }

  Future<void> _cargarViajes() async {
    final res = await tripRepo.list();
    if (res is Ok<List<Trip>>) {
      setState(() {
        _viajes = res.value;
      });
    } else {
      setState(() {
        _viajes = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_viajes == null) {
      return Scaffold(
        backgroundColor: Colors.teal[200],
        appBar: AppBar(
          title: const Text('Recorrido de viajes'),
          backgroundColor: Colors.teal[200],
        ),
        body: Center(child: CircularProgressIndicator()),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: widget.selectedIndex,
          backgroundColor: const Color(0xFFEDE5D0),
          unselectedItemColor: Colors.black,
          selectedItemColor: Colors.teal[500],
          iconSize: 35,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.folder),
              label: 'Mis viajes',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Nuevo viaje',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.equalizer),
              label: 'Datos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Mi perfil',
            ),
          ],
          onTap: (int index) {
            setState(() {
              _selectedIndex = index;
              if (_selectedIndex == 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // cuando este con sesion iniciada habra que cambiarlo para que vaya directamente a la pantalla del perfil
                    builder: (context) => MyHomePage(
                      title: 'JOURNI',
                      sesionIniciada: widget.sesionIniciada,
                      viajes: widget.viajes,
                      tripRepo: widget.tripRepo,
                      entryRepo: widget.entryRepo,
                      tripService: widget.tripService,
                      entryService: widget.entryService,
                      userRepo: userRepo,
                      userService: userService,
                    ),
                  ),
                );
              } else if (_selectedIndex == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Crear_Viaje(
                      selectedIndex: _selectedIndex,
                      viajes: _viajes!,
                      sesionIniciada: widget.sesionIniciada,
                      num_viaje: -1,
                      repo: widget.tripRepo,
                      entryRepo: widget.entryRepo,
                      tripService: widget.tripService,
                      entryService: widget.entryService,
                      userRepo: userRepo,
                      userService: userService,
                    ),
                  ),
                );
              }
              /* DESCOMENTAR SI FUERA NECESARIO
            else if (index == 1) {
              // Ir al mapa
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapaPaisScreen(
                    selectedIndex: index,
                    viajes: _viajes!,
                    tripRepo: widget.tripRepo,
                    entryRepo: widget.entryRepo,
                    tripService: widget.tripService,
                    entryService: widget.entryService,
                  ),
                ),
              );
            }
            */
              else if (index == 4) {
                //mi perfil
                index = 1;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      selectedIndex: 1,
                      sesionIniciada: widget.sesionIniciada,
                      tripRepo: widget.tripRepo,
                      viajes: widget.viajes,
                      entryRepo: widget.entryRepo,
                      tripService: widget.tripService,
                      entryService: widget.entryService,
                      userRepo: widget.userRepo,
                      userService: widget.userService,
                    ),
                  ),
                );
              }
            });
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.teal[200],
      appBar: AppBar(
        title: const Text('Recorrido de viajes'),
        backgroundColor: Colors.teal[200],
      ),
      body: _viajes!.isEmpty
          ? const Center(child: Text('No hay viajes para mostrar.'))
          : ListView.builder(
              itemCount: _viajes!.length,
              itemBuilder: (context, index) {
                final viaje = _viajes![index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.map, color: Colors.teal),
                    title: Text(
                      viaje.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (viaje.startDate != null)
                          Text(
                            'Inicio: ${viaje.startDate!.toLocal().toString().split(' ')[0]}',
                          ),
                        if (viaje.endDate != null)
                          Text(
                            'Fin: ${viaje.endDate!.toLocal().toString().split(' ')[0]}',
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OpcionesViajeScreen(
                              viaje: viaje,
                              entryService: widget.entryService,
                              entryRepo: widget.entryRepo),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFFEDE5D0),
        unselectedItemColor: Colors.black,
        selectedItemColor: Colors.teal[500],
        iconSize: 35,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Mis viajes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Nuevo viaje'),
          BottomNavigationBarItem(icon: Icon(Icons.equalizer), label: 'Datos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mi perfil'),
        ],
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
            if (_selectedIndex == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // cuando este con sesion iniciada habra que cambiarlo para que vaya directamente a la pantalla del perfil
                  builder: (context) => MyApp(
                    tripRepo: widget.tripRepo,
                    entryRepo: widget.entryRepo,
                    tripService: widget.tripService,
                    entryService: widget.entryService,
                    userRepo: userRepo,
                    userService: userService,
                  ),
                ),
              );
            } else if (_selectedIndex == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Crear_Viaje(
                    selectedIndex: _selectedIndex,
                    viajes: _viajes!,
                    sesionIniciada: widget.sesionIniciada,
                    num_viaje: -1,
                    repo: widget.tripRepo,
                    entryRepo: widget.entryRepo,
                    tripService: widget.tripService,
                    entryService: widget.entryService,
                    userRepo: userRepo,
                    userService: userService,
                  ),
                ),
              );
            }
            /* DESCOMENTAR SI FUERA NECESARIO
            else if (index == 1) {
              // Ir al mapa
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapaPaisScreen(
                    selectedIndex: index,
                    viajes: _viajes!,
                    tripRepo: widget.tripRepo,
                    entryRepo: widget.entryRepo,
                    tripService: widget.tripService,
                    entryService: widget.entryService,
                  ),
                ),
              );
            }
            */
            else if (index == 4) {
              //mi perfil
              index = 1;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(
                    selectedIndex: 1,
                    sesionIniciada: widget.sesionIniciada,
                    tripRepo: widget.tripRepo,
                    viajes: widget.viajes,
                    entryRepo: widget.entryRepo,
                    tripService: widget.tripService,
                    entryService: widget.entryService,
                    userRepo: widget.userRepo,
                    userService: widget.userService,
                  ),
                ),
              );
            }
          });
        },
      ),
    );
  }
}

//
// 🔹 Pantalla intermedia: opciones del viaje
//
class OpcionesViajeScreen extends StatelessWidget {
  final Trip viaje;
  final EntryService entryService;
  final EntryRepository entryRepo;

  const OpcionesViajeScreen(
      {Key? key,
      required this.viaje,
      required this.entryRepo,
      required this.entryService})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[200],
      appBar: AppBar(
        title: Text(viaje.title, textAlign: TextAlign.center),
        backgroundColor: Colors.teal[200],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.map, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
              label: const Text(
                'Ver mapa',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapaDetalleScreen(
                      viaje: viaje,
                      entryService: entryService,
                      entryRepo: entryRepo,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.timeline, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
              label: const Text(
                'Ver línea temporal',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LineaTemporalScreen(
                      viaje: viaje,
                      entryRepo: entryRepo,
                      entryService: entryService,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

//
// 🔹 Pantalla del mapa de un viaje
//
class MapaDetalleScreen extends StatefulWidget {
  final Trip viaje;
  final EntryService entryService;
  final EntryRepository entryRepo;

  const MapaDetalleScreen({
    Key? key,
    required this.viaje,
    required this.entryService,
    required this.entryRepo,
  }) : super(key: key);

  @override
  State<MapaDetalleScreen> createState() => _MapaDetalleScreenState();
}

class _MapaDetalleScreenState extends State<MapaDetalleScreen> {
  LatLng? _posicionUsuario;
  List<Entry>? _entradas;
  List<Marker> _markers = [];

  @override
  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
    _cargarEntradas();
  }

  Future<void> _cargarEntradas() async {
    final res = await widget.entryService.listByTrip(widget.viaje.id);

    if (res is Ok<List<Entry>>) {
      setState(() {
        _entradas = res.value;
      });
      _generarMarkers();
    } else {
      setState(() {
        _entradas = [];
      });
    }
  }

  void _generarMarkers() {
    if (_entradas == null) return;

    final Map<String, List<Entry>> agrupadas = {};

    for (var e in _entradas!) {
      if (e.location?.lat == null || e.location?.lon == null) continue;
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
          child: GestureDetector(
            onTap: () {
              _mostrarPopup(lista);
            },
            child: const Icon(
              Icons.location_pin,
              color: Colors.red,
              size: 40,
            ),
          ),
        ),
      );
    });

    setState(() => _markers = nuevos);
  }

  void _mostrarPopup(List<Entry> entradas) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Entradas en esta ubicación"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: entradas.length,
              itemBuilder: (context, index) {
                final e = entradas[index];
                return ListTile(
                  title: Text(
                    e.text ?? "(${e.type.name})",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    e.createdAt.toLocal().toString().split(" ")[0],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            )
          ],
        );
      },
    );
  }

  Future<void> _obtenerUbicacion() async {
    bool permiso = await Geolocator.isLocationServiceEnabled();
    if (!permiso) return;

    LocationPermission permisoAcceso = await Geolocator.checkPermission();
    if (permisoAcceso == LocationPermission.denied) {
      permisoAcceso = await Geolocator.requestPermission();
      if (permisoAcceso == LocationPermission.denied) return;
    }

    Position posicion = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _posicionUsuario = LatLng(posicion.latitude, posicion.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      appBar: AppBar(
        title: Text('Mapa: ${widget.viaje.title}'),
        backgroundColor: Colors.teal,
      ),
      /*
         TODO: En lugar de posicionUsuario, se debe comprobar si la lista de entradas es vacía o no.
         TODO: En caso de serlo, sacamos el body que tenemos.
         TODO: Sino, recorremos la lista y ponemos un pin por ubicación en entrada
      */
      body: _posicionUsuario == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: _posicionUsuario!,
                initialZoom: 2,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
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

//
// 🔹 Pantalla para la línea temporal
//
class LineaTemporalScreen extends StatefulWidget {
  final Trip viaje;
  final EntryService entryService;
  final EntryRepository entryRepo;

  const LineaTemporalScreen(
      {Key? key,
      required this.viaje,
      required this.entryService,
      required this.entryRepo})
      : super(key: key);

  @override
  State<LineaTemporalScreen> createState() => _LineaTemporalScreenState();
}

class _LineaTemporalScreenState extends State<LineaTemporalScreen> {
  List<Entry>? entradas;

  @override
  void initState() {
    super.initState();
    cargarEntradas();
  }

  Future<void> cargarEntradas() async {
    final res = await widget.entryService.listByTrip(widget.viaje.id);

    if (res is Ok<List<Entry>>) {
      setState(() => entradas = res.value);
    } else {
      setState(() => entradas = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      appBar: AppBar(
        title: Text('Línea temporal: ${widget.viaje.title}'),
        backgroundColor: Colors.teal,
      ),

      // TODO: Mostrar todas las entradas en orden de creación, con la info necesaria
      // TODO: En caso de que no haya entradas, mostramos lo que hay ahora mismo
      body: entradas == null
          ? const Center(child: CircularProgressIndicator())
          : entradas!.isEmpty
              ? const Center(
                  child: Text(
                    'Este viaje no tiene eventos.',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: entradas!.length,
                  itemBuilder: (context, index) {
                    final e = entradas![index];
                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: ListTile(
                        leading: const Icon(Icons.event, color: Colors.teal),
                        title: Text(
                          e.text ?? "(${e.type.name})",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          e.createdAt.toLocal().toString().split(" ")[0] ?? '',
                        ),
                        onTap: () {
                          // Puedes abrir detalles si quieres
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

// WIDGET AUXILIAR PARA LA LÍNEA TEMPORAL

/// Widget reutilizable: un tile de la timeline
class TimelineTile extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final Widget child;
  final Color lineColor;
  final Color dotColor;
  final double lineWidth;
  final double dotSize;
  final VoidCallback? onTap;

  const TimelineTile({
    Key? key,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.lineColor = Colors.grey,
    this.dotColor = Colors.teal,
    this.lineWidth = 2.0,
    this.dotSize = 12.0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ancho fijo para la columna de timeline
    const double leftWidth = 40.0;

    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // columna izquierda: línea y punto
          SizedBox(
            width: leftWidth,
            child: Column(
              children: [
                // linea superior (oculta si es el primer elemento)
                Expanded(
                  flex: 1,
                  child: Container(
                    width: lineWidth,
                    color: isFirst ? Colors.transparent : lineColor,
                    margin: EdgeInsets.only(top: 4),
                  ),
                ),

                // el punto (círculo)
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),

                // linea inferior (oculta si es el último elemento)
                Expanded(
                  flex: 1,
                  child: Container(
                    width: lineWidth,
                    color: isLast ? Colors.transparent : lineColor,
                    margin: EdgeInsets.only(bottom: 4),
                  ),
                ),
              ],
            ),
          ),

          // espacio entre la línea y el contenido
          const SizedBox(width: 12),

          // contenido derecho
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Lista de timeline basada en una lista de entradas
class TimelineList extends StatelessWidget {
  final List<Entry> entries;
  final void Function(Entry entry)? onTapEntry;

  const TimelineList({
    Key? key,
    required this.entries,
    this.onTapEntry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('Este viaje no tiene eventos.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final e = entries[index];
        final isFirst = index == 0;
        final isLast = index == entries.length - 1;

        // título seguro (evita nulls)
        final title =
            e.type == EntryType.note ? (e.text ?? '') : _titleForType(e.type);

        // subtítulo opcional (fecha u otra cosa)
        final subtitle = e.createdAt != null
            ? e.createdAt!.toLocal().toString().split(' ')[0]
            : null;

        return TimelineTile(
          isFirst: isFirst,
          isLast: isLast,
          onTap: () => onTapEntry?.call(e),
          child: Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                  // puedes añadir aquí una línea o imagen preview si quieres
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _titleForType(EntryType type) {
    switch (type) {
      case EntryType.photo:
        return '📷 Fotografía';
      case EntryType.video:
        return '🎥 Vídeo';
      case EntryType.note:
      default:
        return 'Entrada';
    }
  }
}
