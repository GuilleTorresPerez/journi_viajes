import 'package:flutter/material.dart';

import 'application/entry_service.dart';
import 'application/trip_service.dart';
import 'application/user_service.dart';
import 'crear_viaje.dart';
import 'domain/ports/entry_repository.dart';
import 'domain/ports/trip_repository.dart';
import 'domain/ports/user_repository.dart';
import 'domain/trip.dart';
import 'domain/user.dart';
import 'estadisticasScreen.dart';
import 'login_screen.dart';
import 'main.dart';
import 'map_screen.dart';

// ignore: must_be_immutable
class MiPerfil extends StatefulWidget {
  int selectedIndex;
  late final bool sesionIniciada;
  List<Trip> viajes;
  final TripRepository tripRepo;
  final EntryRepository entryRepo;
  final TripService tripService;
  final EntryService entryService;
  final UserRepository userRepo;
  final UserService userService;

  final User? currentUser;

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
    required this.currentUser,
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // FOTO DE PERFIL
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.teal[300],
                child: const Icon(
                  Icons.person,
                  size: 70,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // NOMBRE COMPLETO
              Text(
                "${widget.currentUser?.name} ${widget.currentUser?.lastName}",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 30),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Datos personales",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.teal[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // FILA ID
              _buildDataRow(
                  Icons.perm_identity, "ID", widget.currentUser!.id.toString()),

              const SizedBox(height: 12),

              // FILA EMAIL
              _buildDataRow(
                  Icons.email_outlined, "Email", widget.currentUser!.email),

              const SizedBox(height: 12),

              // FILA FECHA CREACIÓN
              _buildDataRow(Icons.calendar_month, "Usuario desde",
                  widget.currentUser!.createdAt.toString().substring(0, 10)),

              const SizedBox(height: 40),

              // BOTÓN DE CERRAR SESIÓN (solo en front)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Cerrar sesión",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                onPressed: () {
                  // CIERRE DE SESIÓN EN FRONT

                  // Ir a login y borrar historial de navegación
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyHomePage(
                        title: 'JOURNI',
                        sesionIniciada: false,
                        viajes: [],
                        tripRepo: widget.tripRepo,
                        entryRepo: widget.entryRepo,
                        tripService: widget.tripService,
                        entryService: widget.entryService,
                        userRepo: widget.userRepo,
                        userService: widget.userService,
                        skipLogin: false,
                        currentUser: null,
                      ),
                    ),
                    (route) => false, // borra todo el stack
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
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
            icon: Icon(Icons.folder),
            label: 'Mis viajes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Nuevo viaje'),
          BottomNavigationBarItem(icon: Icon(Icons.equalizer), label: 'Datos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mi perfil'),
        ],
        onTap: (int index) {
          setState(() => widget.selectedIndex = index);

          if (index == 0) {
            Navigator.pop(context);
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
                  currentUser: widget.currentUser,
                ),
              ),
            );
          } else if (index == 1) {
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
                  currentUser: widget.currentUser,
                ),
              ),
            );
          } else if (index == 3) {
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
          }
        },
      ),
    );
  }

  /// widget para mostrar cada dato con icono + título + valor
  Widget _buildDataRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.teal[700], size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
