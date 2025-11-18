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
import 'application/trip_service.dart';
import 'map_screen.dart';
import 'mockImagePicker.dart';

// Puertos (interfaces)
import 'package:journi/domain/ports/entry_repository.dart';
import 'package:journi/domain/ports/trip_repository.dart';
import 'package:journi/domain/ports/user_repository.dart';

// Dominio / aplicación
import 'package:journi/application/shared/result.dart';

import 'package:journi/login_screen.dart';

void main() {
  final db = AppDatabase();
  final TripRepository tripRepo = DriftTripRepository(db);
  final EntryRepository entryRepo = DriftEntryRepository(db);
  final UserRepository userRepo = DriftUserRepository(db);

  final tripService = makeTripService(tripRepo);
  final entryService = makeEntryService(entryRepo);
  final userService = makeUserService(userRepo);

  runApp(MyApp(
    tripRepo: tripRepo,
    tripService: tripService,
    entryRepo: entryRepo,
    entryService: entryService,
    userRepo: userRepo,
    userService: userService,
  ));
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
        inicionSesiada: false,
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

class MyHomePage extends StatefulWidget {
  MyHomePage({
    super.key,
    required this.title,
    required this.inicionSesiada,
    required this.viajes,
    required this.tripRepo,
    required this.tripService,
    required this.entryRepo,
    required this.entryService,
    required this.userRepo,
    required this.userService,
  });

  final String title;
  final bool inicionSesiada;
  final TripRepository tripRepo;
  final TripService tripService;

  final EntryRepository entryRepo;
  final MockImagePicker picker = MockImagePicker();

  final EntryService entryService;

  List<Trip> viajes = [];

  UserRepository userRepo;
  UserService userService;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // 🔽 snapshot inicial para cuando el stream aún no ha emitido
  List<Trip>? _initialTrips;

  @override
  void initState() {
    super.initState();
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
          inicionSesiada: widget.inicionSesiada,
          viajes: const [],
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
                            'Inicio: ${viaje.startDate!.toLocal().toString().split(' ')[0]}'),
                      if (viaje.endDate != null)
                        Text(
                            'Fin: ${viaje.endDate!.toLocal().toString().split(' ')[0]}'),
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
                          inicionSesiada: widget.inicionSesiada,
                          viajes: items,
                          num_viaje: index,
                          repo: widget.tripRepo,
                          entryRepo: widget.entryRepo,
                          tripService: widget.tripService,
                          entryService: widget.entryService,
                          picker: widget.picker,
                          userRepo: widget.userRepo,
                          userService: widget.userService,
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
              icon: Icon(Icons.folder), label: 'Mis viajes'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Nuevo viaje'),
          BottomNavigationBarItem(icon: Icon(Icons.equalizer), label: 'Datos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mi perfil'),
        ],
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
            if (_selectedIndex == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Crear_Viaje(
                    selectedIndex: _selectedIndex,
                    inicionSesiada: widget.inicionSesiada,
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
              // Ir al mapa
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapaPaisScreen(
                    selectedIndex: index,
                    inicionSesiada: widget.inicionSesiada,
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
            } else if (index == 4) {
              //mi perfil
              if (widget.inicionSesiada) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MiPerfil(
                      selectedIndex: index,
                      inicionSesiada: widget.inicionSesiada,
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
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      selectedIndex: index,
                      inicionSesiada: widget.inicionSesiada,
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
              }
            }
          });
        },
      ),
    );
  }
}
