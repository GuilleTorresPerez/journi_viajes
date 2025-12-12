import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:journi/application/entry_service.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/domain/ports/entry_repository.dart';
import 'package:journi/domain/ports/trip_repository.dart';

import 'application/use_cases/use_cases.dart';
import 'application/user_service.dart';
import 'crear_viaje.dart';
import 'domain/ports/user_repository.dart';
import 'domain/trip.dart';
import 'domain/user.dart';
import 'estadisticasScreen.dart';
import 'login_screen.dart';
import 'main.dart';
import 'map_screen.dart';
import 'mi_perfil.dart';

class Editar_viaje extends StatefulWidget {
  // ❗ Los campos del widget deben ser inmutables (final)
  final int
      selectedIndex; // primer item de la bottom navigation bar seleccionado por defecto
  final int num_viaje;
  final List<Trip> viajes;
  final bool sesionIniciada;
  // 👉 Puerto (interfaz) en lugar del repo in-memory
  final TripRepository repo;
  final EntryRepository entryRepo;
  final TripService tripService;
  final EntryService entryService;
  final UserRepository userRepo;
  final UserService userService;
  final User? currentUser;

  const Editar_viaje({
    super.key,
    required this.selectedIndex,
    required this.viajes,
    required this.sesionIniciada,
    required this.num_viaje,
    required this.repo,
    required this.entryRepo,
    required this.tripService,
    required this.entryService,
    required this.userService,
    required this.userRepo,
    required this.currentUser,
  });

  @override
  State<Editar_viaje> createState() => _EditarViajeState();
}

class _EditarViajeState extends State<Editar_viaje> {
  // ✅ Lo mutable vive en el State
  late int _selectedIndex;
  late final TextEditingController _titulo;
  late final TextEditingController _fechaIni;
  late final TextEditingController _fechaFin;

  DateTime? _parseDdMmYyyy(String input) {
    try {
      return DateFormat('dd-MM-yyyy').parseStrict(input);
    } catch (_) {
      return null;
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

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _titulo = TextEditingController();
    _fechaIni = TextEditingController();
    _fechaFin = TextEditingController();

    // Rellena campos si venimos en modo edición
    if (widget.num_viaje >= 0) {
      final trip = widget.viajes[widget.num_viaje];
      _titulo.text = trip.title;
      _fechaIni.text = DateFormat(
        'dd-MM-yyyy',
      ).format(trip.startDate ?? DateTime.now());
      _fechaFin.text = DateFormat(
        'dd-MM-yyyy',
      ).format(trip.endDate ?? DateTime.now());
    }
  }

  @override
  void dispose() {
    // 📌 Importante para evitar fugas de memoria
    _titulo.dispose();
    _fechaIni.dispose();
    _fechaFin.dispose();
    super.dispose();
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
      body: Center(
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InputField(
                    key: const Key('tituloField'),
                    controller: _titulo,
                    hintText: 'Titulo del viaje'),
                const SizedBox(height: 10),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                InputField(
                  key: const Key('fechaIniField'),
                  controller: _fechaIni,
                  hintText: 'Fecha de inicio de viaje (DD-MM-YYYY)',
                ),
                const SizedBox(height: 10),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                InputField(
                  key: const Key('fechaFinField'),
                  controller: _fechaFin,
                  hintText: 'Fecha de fin de viaje (DD-MM-YYYY)',
                ),
                const SizedBox(height: 10),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RoundedButton(
                  key: const Key('guardarButton'),
                  text: 'Guardar',
                  backgroundColor: Colors.white,
                  textColor: Colors.black,
                  onPressed: () async {
                    final titulo = _titulo.text.trim();
                    final ini = _parseDdMmYyyy(_fechaIni.text.trim());
                    final fin = _parseDdMmYyyy(_fechaFin.text.trim());

                    if (titulo.isEmpty || ini == null || fin == null) {
                      _showError(
                        'Rellena todos los campos con formato válido (DD-MM-YYYY).',
                      );
                      return;
                    }
                    if (ini.isAfter(fin)) {
                      _showError(
                        'La fecha de inicio no puede ser posterior a la final',
                      );
                      return;
                    }
                    if (titulo.length > Trip.titleMax) {
                      _showError(
                        'El título debe contener entre 1 y ${Trip.titleMax} caracteres',
                      );
                      return;
                    }

                    final cmd = UpdateTripCommand(
                      id: widget.viajes[widget.num_viaje].id, // no cambiamos id
                      title: Patch.value(titulo),
                      description: const Patch.value('Description'),
                      startDate: Patch.value(ini),
                      endDate: Patch.value(fin),
                    );

                    final result = await widget.tripService.patch(cmd);

                    if (!mounted)
                      return; // evita usar context tras async si desmonta

                    if (result is Ok<Trip>) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          key: Key('snackbar_ok'),
                          content: Text('Viaje actualizado correctamente'),
                        ),
                      );
                      await Future.delayed(const Duration(milliseconds: 300));
                      if (!mounted) return;
                      Navigator.pop(context, result.value); // volver a la lista
                    } else if (result is Err<Trip>) {
                      final errors =
                          result.errors.map((e) => e.message).join('\n');
                      _showError('Error al editar el viaje:\n$errors');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // ✅ usa estado, no muta el widget
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
        onTap: (int inIndex) async {
          setState(() => _selectedIndex = inIndex);
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
                  tripRepo: widget.repo,
                  entryRepo: widget.entryRepo,
                  tripService: widget.tripService,
                  entryService: widget.entryService,
                  userRepo: widget.userRepo,
                  userService: widget.userService,
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
                  repo: widget.repo,
                  entryRepo: widget.entryRepo,
                  tripService: widget.tripService,
                  entryService: widget.entryService,
                  userRepo: widget.userRepo,
                  userService: widget.userService,
                  currentUser: widget.currentUser,
                ),
              ),
            );
          } else if (_selectedIndex == 1) {
            // Ir al mapa
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MapaPaisScreen(
                  selectedIndex: _selectedIndex,
                  viajes: widget.viajes,
                  sesionIniciada: widget.sesionIniciada,
                  tripRepo: widget.repo,
                  entryRepo: widget.entryRepo,
                  tripService: widget.tripService,
                  entryService: widget.entryService,
                  userRepo: widget.userRepo,
                  userService: widget.userService,
                  currentUser: widget.currentUser,
                ),
              ),
            );
          } else if (_selectedIndex == 3) {
            // Estadisticas
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EstadisticasScreen(
                  selectedIndex: _selectedIndex,
                  sesionIniciada: widget.sesionIniciada,
                  viajes: widget.viajes,
                  tripRepo: widget.repo,
                  entryRepo: widget.entryRepo,
                  tripService: widget.tripService,
                  entryService: widget.entryService,
                  userRepo: widget.userRepo,
                  userService: widget.userService,
                  currentUser: widget.currentUser!,
                ),
              ),
            );
          } else if (_selectedIndex == 4) {
            // Perfil
            if (widget.sesionIniciada && widget.currentUser != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MiPerfil(
                    selectedIndex: _selectedIndex,
                    sesionIniciada: widget.sesionIniciada,
                    viajes: widget.viajes,
                    tripRepo: widget.repo,
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
                    selectedIndex: _selectedIndex,
                    sesionIniciada: widget.sesionIniciada,
                    viajes: widget.viajes,
                    tripRepo: widget.repo,
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
                      selectedIndex: _selectedIndex,
                      sesionIniciada: _sesionIniciada,
                      viajes: widget.viajes,
                      tripRepo: widget.repo,
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

class InputField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;

  const InputField({
    super.key,
    required this.hintText,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hintText, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.white),
            ),
            child: TextFormField(
              style: const TextStyle(color: Colors.white),
              controller: controller,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                hintText: '',
                filled: true,
                fillColor: Colors.transparent,
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  borderSide: BorderSide(color: Colors.white, width: 2.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoundedButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;

  const RoundedButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        child: Text(text, style: TextStyle(color: textColor)),
      ),
    );
  }
}
