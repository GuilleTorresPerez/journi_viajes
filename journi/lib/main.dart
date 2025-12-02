import 'package:flutter/material.dart';

import 'package:journi/crear_viaje.dart';
import 'package:journi/mi_perfil.dart';
import 'package:journi/pantalla_viaje.dart';

// Infra BD (Drift)
import 'package:journi/data/local/drift/app_database.dart';
import 'package:journi/data/local/drift/drift_entry_repository.dart';
import 'package:journi/data/local/drift/drift_trip_repository.dart';
import 'package:journi/data/local/drift/drift_user_repository.dart';
import 'package:journi/searchTrip.dart';
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

  // 1. Instanciamos los repositorios
  final TripRepository tripRepo = DriftTripRepository(db);
  final EntryRepository entryRepo = DriftEntryRepository(db);
  final UserRepository userRepo = DriftUserRepository(db);
  final GeocodingRepository geoRepo = PlatformGeocodingRepository();

  // 2. Inyectamos las dependencias.
  // CORRECCIÓN: Añadimos userRepo como segundo argumento en makeTripService
  final tripService = makeTripService(tripRepo, userRepo, entryRepo, geoRepo);

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
        skipLogin: false, // por defecto false

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
    required this.userService,
    required this.skipLogin,
    this.currentUser
  });

  final bool skipLogin; // nuevo flag para tests
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
  User? currentUser;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // snapshot inicial para cuando el stream aún no ha emitido
  List<Trip>? _initialTrips;

  bool _sesionIniciada = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
    _sesionIniciada = widget.sesionIniciada;
    _checkSession().then((_) => _loadInitial());
  }

  Future<void> _checkSession() async {
    if (widget.skipLogin) {
      _currentUser = User(
        id: "test-user",
        name: "Test",
        lastName: "User",
        email: "test@test.com",
        passwordHash: "Use",
        passwordSalt: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _sesionIniciada = true;
    }
    final user = await _currentUser;

    if (!mounted) return;

    if (user != null) {
      setState(() {
        _currentUser = user;
        _sesionIniciada = true;
      });
    } else {
      // Si no hay usuario, mostramos login
      final loggedUser = await Navigator.push<User?>(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            selectedIndex: _selectedIndex,
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
          _currentUser = loggedUser;
          _sesionIniciada = true;
        });
      }
    }
  }

  Future<void> _loadInitial() async {
    // Espera hasta que _currentUser esté disponible
    if (_currentUser == null) return;

    final res = await widget.tripRepo.list(_currentUser!.id);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () async {
              final items = widget.viajes;

              final selectedTrip = await showSearch<Trip?>(
                context: context,
                delegate: SearchTripsDelegate(items),
              );

              // Opcional: si el usuario selecciona un viaje, lo abrimos
              if (selectedTrip != null && mounted) {
                final index = items.indexOf(selectedTrip);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Pantalla_Viaje(
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
                      currentUser: _currentUser,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Trip>>(
              stream: widget.tripRepo.watchAll(_currentUser!.id),
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
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        key: ValueKey('id$index'),
                        leading: const Icon(Icons.flight_takeoff,
                            color: Colors.teal),
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
                                currentUser: _currentUser,
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
                  currentUser: _currentUser!,
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
                  currentUser: _currentUser,
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
                    currentUser: _currentUser!,
                  ),
                ),
              );
            } else {
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
