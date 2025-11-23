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
  late int _selectedIndex;

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
                          builder: (context) =>
                              OpcionesViajeScreen(viaje: viaje),
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

  const OpcionesViajeScreen({Key? key, required this.viaje}) : super(key: key);

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
                    builder: (context) => MapaDetalleScreen(viaje: viaje),
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
                    builder: (context) => LineaTemporalScreen(viaje: viaje),
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

  const MapaDetalleScreen({Key? key, required this.viaje}) : super(key: key);

  @override
  State<MapaDetalleScreen> createState() => _MapaDetalleScreenState();
}

class _MapaDetalleScreenState extends State<MapaDetalleScreen> {
  LatLng? _posicionUsuario;

  @override
  void initState() {
    super.initState();
    // TODO: no coger la ubicacion del usuario, sino la ubicacion del viaje cuando la hayamos guardado
    _obtenerUbicacion();
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
      body: _posicionUsuario == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: _posicionUsuario!,
                initialZoom: 6,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80,
                      height: 80,
                      point: _posicionUsuario!,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

//
// 🔹 Pantalla para la línea temporal
//
class LineaTemporalScreen extends StatelessWidget {
  final Trip viaje;

  const LineaTemporalScreen({Key? key, required this.viaje}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      appBar: AppBar(
        title: Text('Línea temporal: ${viaje.title}'),
        backgroundColor: Colors.teal,
      ),
      body: const Center(
        child: Text(
          'Este viaje no tiene eventos.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
