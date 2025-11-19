import 'package:flutter/material.dart';

import 'application/entry_service.dart';
import 'application/trip_service.dart';
import 'application/user_service.dart';
import 'crear_viaje.dart';
import 'data/local/drift/app_database.dart';
import 'data/local/drift/drift_user_repository.dart';
import 'domain/ports/entry_repository.dart';
import 'domain/ports/trip_repository.dart';
import 'domain/ports/user_repository.dart';
import 'domain/trip.dart';
import 'login_screen.dart';
import 'main.dart';
import 'map_screen.dart';

class MiPerfil extends StatefulWidget {
  int selectedIndex;
  final bool sesionIniciada;
  List<Trip> viajes;
  final TripRepository tripRepo;
  final EntryRepository entryRepo;
  final TripService tripService;
  final EntryService entryService;
  final UserRepository userRepo;
  final UserService userService;

  MiPerfil({
    super.key,
    required this.sesionIniciada,
    required this.viajes,
    required this.selectedIndex,
    required this.tripRepo,
    required this.entryRepo,
    required this.tripService,
    required this.entryService,
    required this.userRepo,
    required this.userService,
  });

  @override
  State<MiPerfil> createState() => _MiPerfilState();
}

class _MiPerfilState extends State<MiPerfil> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[200],
      appBar: AppBar(
        backgroundColor: Colors.teal[200],
        title: const Text('Mi perfil'),
      ),
      body: const Center(
        child: Text('Aquí irá la información de tu perfil'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.selectedIndex,
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
            if (widget.selectedIndex == 0) {
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
                    userService: widget.userService,
                  ),
                ),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Crear_Viaje(
                    selectedIndex: index,
                    sesionIniciada: widget.sesionIniciada,
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
            }
          });
        },
      ),
    );
  }
}
