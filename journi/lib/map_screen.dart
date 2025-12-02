import 'package:flutter/material.dart';
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_trip_repository.dart';
import 'package:journi/domain/ports/entry_repository.dart';
import 'package:journi/domain/trip.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'PhotoViewerScreen.dart';
import 'application/entry_service.dart';
import 'application/trip_service.dart';
import 'application/user_service.dart';
import 'crear_viaje.dart';
import 'data/local/drift/drift_user_repository.dart';
import 'domain/entry.dart';
import 'domain/ports/trip_repository.dart';
import 'domain/ports/user_repository.dart';
import 'domain/user.dart';
import 'estadisticasScreen.dart';
import 'login_screen.dart';
import 'main.dart';
import 'mi_perfil.dart';

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
  final User? currentUser;

  MapaPaisScreen(
      {super.key,
      required this.viajes,
      required this.sesionIniciada,
      required this.selectedIndex,
      required this.tripRepo,
      required this.entryRepo,
      required this.tripService,
      required this.entryService,
      required this.userRepo,
      required this.userService,
      required this.currentUser});

  @override
  State<MapaPaisScreen> createState() => _MapaPaisScreenState();
}

class _MapaPaisScreenState extends State<MapaPaisScreen> {
  late final userService;
  late int _selectedIndex = widget.selectedIndex;

  @override
  void initState() {
    super.initState();
    _cargarViajes();
    userService = makeUserService(widget.userRepo);
  }

  Future<void> _cargarViajes() async {
    /*final res = await tripRepo.list();
    if (res is Ok<List<Trip>>) {
      setState(() {
        _viajes = res.value;
      });
    } else {
      setState(() {
        _viajes = [];
      });
    }*/
  }

  @override
  Widget build(BuildContext context) {
    if (widget.viajes == null) {
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
            setState(() async {
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
                        userRepo: widget.userRepo,
                        userService: userService,
                        skipLogin: false,
                        currentUser: widget.currentUser),
                  ),
                );
              } else if (_selectedIndex == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Crear_Viaje(
                      selectedIndex: _selectedIndex,
                      viajes: widget.viajes,
                      sesionIniciada: widget.sesionIniciada,
                      num_viaje: -1,
                      repo: widget.tripRepo,
                      entryRepo: widget.entryRepo,
                      tripService: widget.tripService,
                      entryService: widget.entryService,
                      userRepo: widget.userRepo,
                      userService: userService,
                      currentUser: widget.currentUser,
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
                    viajes: widget.viajes,
                    tripRepo: widget.tripRepo,
                    entryRepo: widget.entryRepo,
                    tripService: widget.tripService,
                    entryService: widget.entryService,
                  ),
                ),
              );
            }
            */
              else if (index == 3) {
                // Estadisticas
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EstadisticasScreen(
                      selectedIndex: index,
                      sesionIniciada: widget.sesionIniciada,
                      viajes: widget.viajes,
                      tripRepo: widget.tripRepo,
                      entryRepo: widget.entryRepo,
                      tripService: widget.tripService,
                      entryService: widget.entryService,
                      userRepo: widget.userRepo,
                      userService: widget.userService,
                      currentUser: widget.currentUser!,
                    ),
                  ),
                );
              } else if (index == 4) {
                // Perfil
                if (widget.sesionIniciada && widget.currentUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MiPerfil(
                        selectedIndex: index,
                        sesionIniciada: widget.sesionIniciada,
                        viajes: widget.viajes,
                        tripRepo: widget.tripRepo,
                        entryRepo: widget.entryRepo,
                        tripService: widget.tripService,
                        entryService: widget.entryService,
                        userRepo: widget.userRepo,
                        userService: widget.userService,
                        currentUser: widget.currentUser!,
                      ),
                    ),
                  );
                } else {
                  final loggedUser = await Navigator.push<User?>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(
                        selectedIndex: index,
                        sesionIniciada: widget.sesionIniciada,
                        viajes: widget.viajes,
                        tripRepo: widget.tripRepo,
                        entryRepo: widget.entryRepo,
                        tripService: widget.tripService,
                        entryService: widget.entryService,
                        userRepo: widget.userRepo,
                        userService: widget.userService,
                      ),
                    ),
                  );

                  bool _sesionIniciada = false;
                  if (loggedUser != null && mounted) {
                    setState(() {
                      _sesionIniciada = true;
                    });

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MiPerfil(
                          selectedIndex: index,
                          sesionIniciada: _sesionIniciada,
                          viajes: widget.viajes,
                          tripRepo: widget.tripRepo,
                          entryRepo: widget.entryRepo,
                          tripService: widget.tripService,
                          entryService: widget.entryService,
                          userRepo: widget.userRepo,
                          userService: widget.userService,
                          currentUser: loggedUser,
                        ),
                      ),
                    );
                  }
                }
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
      body: widget.viajes.isEmpty
          ? const Center(child: Text('No hay viajes para mostrar.'))
          : ListView.builder(
              itemCount: widget.viajes.length,
              itemBuilder: (context, index) {
                final viaje = widget.viajes[index];
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
          setState(() async {
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
                    skipLogin: false,
                    tripRepo: widget.tripRepo,
                    entryRepo: widget.entryRepo,
                    tripService: widget.tripService,
                    entryService: widget.entryService,
                    userRepo: widget.userRepo,
                    userService: userService,
                    currentUser: widget.currentUser,
                  ),
                ),
              );
            } else if (_selectedIndex == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Crear_Viaje(
                    selectedIndex: _selectedIndex,
                    viajes: widget.viajes,
                    sesionIniciada: widget.sesionIniciada,
                    num_viaje: -1,
                    repo: widget.tripRepo,
                    entryRepo: widget.entryRepo,
                    tripService: widget.tripService,
                    entryService: widget.entryService,
                    userRepo: widget.userRepo,
                    userService: userService,
                    currentUser: widget.currentUser,
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
                    viajes: widget.viajes,
                    tripRepo: widget.tripRepo,
                    entryRepo: widget.entryRepo,
                    tripService: widget.tripService,
                    entryService: widget.entryService,
                  ),
                ),
              );
            }
            */
            else if (index == 3) {
              // Estadisticas
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EstadisticasScreen(
                    selectedIndex: index,
                    sesionIniciada: widget.sesionIniciada,
                    viajes: widget.viajes,
                    tripRepo: widget.tripRepo,
                    entryRepo: widget.entryRepo,
                    tripService: widget.tripService,
                    entryService: widget.entryService,
                    userRepo: widget.userRepo,
                    userService: widget.userService,
                    currentUser: widget.currentUser!,
                  ),
                ),
              );
            } else if (index == 4) {
              // Perfil
              if (widget.sesionIniciada && widget.currentUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MiPerfil(
                      selectedIndex: index,
                      sesionIniciada: widget.sesionIniciada,
                      viajes: widget.viajes,
                      tripRepo: widget.tripRepo,
                      entryRepo: widget.entryRepo,
                      tripService: widget.tripService,
                      entryService: widget.entryService,
                      userRepo: widget.userRepo,
                      userService: widget.userService,
                      currentUser: widget.currentUser!,
                    ),
                  ),
                );
              } else {
                final loggedUser = await Navigator.push<User?>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      selectedIndex: index,
                      sesionIniciada: widget.sesionIniciada,
                      viajes: widget.viajes,
                      tripRepo: widget.tripRepo,
                      entryRepo: widget.entryRepo,
                      tripService: widget.tripService,
                      entryService: widget.entryService,
                      userRepo: widget.userRepo,
                      userService: widget.userService,
                    ),
                  ),
                );

                bool _sesionIniciada = false;
                if (loggedUser != null && mounted) {
                  setState(() {
                    _sesionIniciada = true;
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MiPerfil(
                        selectedIndex: index,
                        sesionIniciada: _sesionIniciada,
                        viajes: widget.viajes,
                        tripRepo: widget.tripRepo,
                        entryRepo: widget.entryRepo,
                        tripService: widget.tripService,
                        entryService: widget.entryService,
                        userRepo: widget.userRepo,
                        userService: widget.userService,
                        currentUser: loggedUser,
                      ),
                    ),
                  );
                }
              }
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

class LineaTemporalScreen extends StatefulWidget {
  final Trip viaje;
  final EntryService entryService;
  final EntryRepository entryRepo;

  const LineaTemporalScreen({
    Key? key,
    required this.viaje,
    required this.entryService,
    required this.entryRepo,
  }) : super(key: key);

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
      body: entradas == null
          ? const Center(child: CircularProgressIndicator())
          : entradas!.isEmpty
              ? const Center(
                  child: Text(
                    'Este viaje no tiene eventos.',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : TimelineList(
                  entries: entradas!,
                  onTapEntry: (e) {
                    if (e.type == EntryType.photo && e.mediaUri != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PhotoViewerScreen(uri: e.mediaUri!),
                        ),
                      );
                    }
                  },
                ),
    );
  }
}

class TimelineTile extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final Widget child;
  final Color lineColor;
  final Color dotColor;
  final double lineWidth;
  final double dotSize;
  final VoidCallback? onTap;
  final Animation<double> animation;

  const TimelineTile({
    Key? key,
    required this.child,
    required this.animation,
    this.isFirst = false,
    this.isLast = false,
    this.lineColor = Colors.grey,
    this.dotColor = Colors.teal,
    this.lineWidth = 3.0,
    this.dotSize = 16.0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double leftWidth = 50.0;

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.2, 0),
          end: Offset.zero,
        ).animate(animation),
        child: InkWell(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: leftWidth,
                child: Column(
                  children: [
                    // Línea superior
                    SizedBox(
                      height: 30,
                      child: Center(
                        child: Container(
                          width: lineWidth,
                          height: double.infinity,
                          color: isFirst ? Colors.transparent : lineColor,
                        ),
                      ),
                    ),

                    // Punto
                    Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),

                    // Línea inferior
                    SizedBox(
                      height: 30,
                      child: Center(
                        child: Container(
                          width: lineWidth,
                          height: double.infinity,
                          color: isLast ? Colors.transparent : lineColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class TimelineList extends StatefulWidget {
  final List<Entry> entries;
  final void Function(Entry entry)? onTapEntry;

  const TimelineList({
    Key? key,
    required this.entries,
    this.onTapEntry,
  }) : super(key: key);

  @override
  State<TimelineList> createState() => _TimelineListState();
}

class _TimelineListState extends State<TimelineList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      itemCount: widget.entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final e = widget.entries[index];

        final isFirst = index == 0;
        final isLast = index == widget.entries.length - 1;

        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(
            (index / widget.entries.length),
            1.0,
            curve: Curves.easeOut,
          ),
        );

        return TimelineTile(
          isFirst: isFirst,
          isLast: isLast,
          animation: animation,
          dotColor: _colorForType(e.type),
          child: _buildCard(e),
          onTap: () => widget.onTapEntry?.call(e),
        );
      },
    );
  }

  Widget _buildCard(Entry e) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              _iconForType(e.type),
              color: _colorForType(e.type),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.text ?? _titleForType(e.type),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    e.createdAt.toLocal().toString().split(' ')[0],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(EntryType type) {
    switch (type) {
      case EntryType.photo:
        return Icons.photo;
      case EntryType.video:
        return Icons.videocam;
      case EntryType.note:
      default:
        return Icons.edit_note;
    }
  }

  Color _colorForType(EntryType type) {
    switch (type) {
      case EntryType.photo:
        return Colors.orange;
      case EntryType.video:
        return Colors.redAccent;
      case EntryType.note:
      default:
        return Colors.blueAccent;
    }
  }

  String _titleForType(EntryType type) {
    switch (type) {
      case EntryType.photo:
        return 'Fotografía';
      case EntryType.video:
        return 'Vídeo';
      case EntryType.note:
      default:
        return 'Nota';
    }
  }
}
