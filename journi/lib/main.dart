import 'package:flutter/material.dart';

import 'package:journi/crear_viaje.dart';
import 'package:journi/mi_perfil.dart';
import 'package:journi/pantalla_viaje.dart';

// Infra BD (Drift)
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_entry_repository.dart';
import 'package:journi/data/local/drift/drift_trip_repository.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'application/entry_service.dart';
import 'package:journi/application/user_service.dart';
import 'domain/trip.dart';
import 'domain/user.dart';
import 'application/trip_service.dart';
import 'estadisticasScreen.dart';
import 'map_screen.dart';
import 'mockImagePicker.dart';

// Puertos (interfaces)
import 'package:journi/domain/ports/entry_repository.dart';
import 'package:journi/domain/ports/trip_repository.dart';
import 'package:journi/domain/ports/user_repository.dart';

// Dominio / aplicación

import 'package:journi/login_screen.dart';
import 'package:journi/data/external/platform_geocoding_repository.dart';
import 'package:journi/domain/ports/geocoding_repository.dart';

void main() {
  final db = AppDatabase();
  final TripRepository tripRepo = DriftTripRepository(db);
  final EntryRepository entryRepo = DriftEntryRepository(db);
  final UserRepository userRepo = DriftUserRepository(db);

  final GeocodingRepository geoRepo = PlatformGeocodingRepository();

  final tripService = makeTripService(tripRepo, entryRepo, geoRepo);
  final entryService = makeEntryService(entryRepo);
  final userService = makeUserService(userRepo);

  runApp(
    MyApp(
      tripRepo: tripRepo,
      tripService: tripService,
      entryRepo: entryRepo,
      entryService: entryService,
      userRepo: userRepo,
      userService: userService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final EntryService entryService;
  final TripService tripService;
  final UserService userService;

  final TripRepository tripRepo;
  final EntryRepository entryRepo;
  final UserRepository userRepo;

  const MyApp({
    super.key,
    required this.tripRepo,
    required this.tripService,
    required this.entryRepo,
    required this.entryService,
    required this.userRepo,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JOURNI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: 'JOURNI',
        sesionIniciada: false,
        viajes: const [],
        tripRepo: tripRepo,
        tripService: tripService,
        entryRepo: entryRepo,
        entryService: entryService,
        userRepo: userRepo,
        userService: userService,
      ),
    );
  }
}

// ignore: must_be_immutable
class MyHomePage extends StatefulWidget {
  MyHomePage({
    super.key,
    required this.title,
    required this.sesionIniciada,
    required this.viajes,
    required this.tripRepo,
    required this.tripService,
    required this.entryRepo,
    required this.entryService,
    required this.userRepo,
    required this.userService, //required bool inicionSesiada,
  });

  final String title;
  final bool sesionIniciada;

  final TripRepository tripRepo;
  final TripService tripService;

  final EntryRepository entryRepo;
  final MockImagePicker picker = MockImagePicker();

  final EntryService entryService;

  List<Trip> viajes = [];

  final UserRepository userRepo;
  final UserService userService;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // 🔽 snapshot inicial para cuando el stream aún no ha emitido
  List<Trip>? _initialTrips;

  bool _sesionIniciada = false; // 👈 NUEVO
  User? _currentUser; // 👈 NUEVO

  @override
  void initState() {
    super.initState();
    _sesionIniciada = widget.sesionIniciada; // 👈 IMPORTANTE
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final res = await widget.tripRepo.list();
    if (!mounted) return;
    if (res is Ok<List<Trip>>) {
      setState(() {
        _initialTrips = res.value;
      });
    } else {
      setState(() {
        _initialTrips = const <Trip>[];
      });
    }
  }

  void _createNewTravel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Crear_Viaje(
          selectedIndex: _selectedIndex,
          sesionIniciada: _sesionIniciada,
          viajes: const [],
          num_viaje: -1,
          repo: widget.tripRepo,
          entryRepo: widget.entryRepo,
          tripService: widget.tripService,
          entryService: widget.entryService,
          userRepo: widget.userRepo,
          userService: widget.userService,
          currentUser: _currentUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[200],
      appBar: AppBar(
        backgroundColor: Colors.teal[200],
        centerTitle: true,
        title: const Text(
          'JOURNI',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<Trip>>(
        stream: widget.tripRepo.watchAll(),
        builder: (context, snapshot) {
          // Usamos el stream si hay datos; si no, usamos la carga inicial
          final items = snapshot.data ?? _initialTrips;

          if (items == null) {
            // Primer frame (o mientras resuelve list())
            return const Center(child: CircularProgressIndicator());
          }

          widget.viajes = items;
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No tienes ningún viaje registrado.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final viaje = items[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  key: ValueKey('id$index'),
                  leading: const Icon(Icons.flight_takeoff, color: Colors.teal),
                  title: Text(
                    viaje.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
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
                      const SizedBox(height: 4),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Pantalla_Viaje(
                          selectedIndex: _selectedIndex,
                          sesionIniciada: _sesionIniciada,
                          viajes: items,
                          num_viaje: index,
                          repo: widget.tripRepo,
                          entryRepo: widget.entryRepo,
                          tripService: widget.tripService,
                          entryService: widget.entryService,
                          picker: widget.picker,
                          userRepo: widget.userRepo,
                          userService: widget.userService,
                          currentUser: _currentUser, // 👈 NUEVO
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewTravel,
        tooltip: 'Nuevo viaje',
        child: const Icon(key: Key('anadirButton'), Icons.add),
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
        onTap: (int index) async {
          // Actualizamos índice básico
          setState(() {
            _selectedIndex = index;
          });

          if (index == 2) {
            // Nuevo viaje
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Crear_Viaje(
                  selectedIndex: _selectedIndex,
                  sesionIniciada: _sesionIniciada,
                  viajes: widget.viajes,
                  num_viaje: -1,
                  repo: widget.tripRepo,
                  entryRepo: widget.entryRepo,
                  tripService: widget.tripService,
                  entryService: widget.entryService,
                  userRepo: widget.userRepo,
                  userService: widget.userService,
                ),
              ),
            );
          } else if (index == 1) {
            // Mapa
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MapaPaisScreen(
                  selectedIndex: index,
                  sesionIniciada: _sesionIniciada,
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
          } else if (index == 3) {
            // Estadisticas
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EstadisticasScreen(
                  selectedIndex: index,
                  sesionIniciada: _sesionIniciada,
                  viajes: widget.viajes,
                  tripRepo: widget.tripRepo,
                  entryRepo: widget.entryRepo,
                  tripService: widget.tripService,
                  entryService: widget.entryService,
                  userRepo: widget.userRepo,
                  userService: widget.userService,
                  currentUser: _currentUser!,
                ),
              ),
            );
          } else if (index == 4) {
            // Perfil
            if (_sesionIniciada && _currentUser != null) {
              // Ya tenía sesión -> ir directo a MiPerfil
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
                    currentUser: _currentUser!, //loggedUser
                  ),
                ),
              );
            } else {
              // No hay sesión -> ir a Login y esperar resultado
              final loggedUser = await Navigator.push<User?>(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(
                    selectedIndex: index,
                    sesionIniciada: _sesionIniciada,
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

              if (loggedUser != null && mounted) {
                setState(() {
                  _sesionIniciada = true;
                  _currentUser = loggedUser;
                });

                // Una vez logueado, lo llevamos al perfil
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
        },
      ),
    );
  }
}
