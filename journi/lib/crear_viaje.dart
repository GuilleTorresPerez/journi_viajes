import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'mi_perfil.dart';
import 'domain/user.dart';

import 'package:journi/application/entry_service.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/application/trip_service.dart';
import 'package:journi/application/use_cases/use_cases.dart';
import 'package:journi/domain/ports/entry_repository.dart';
import 'package:journi/domain/ports/trip_repository.dart';
import 'package:journi/domain/trip.dart';

import 'application/user_service.dart';
import 'domain/ports/user_repository.dart';
import 'login_screen.dart';
import 'main.dart';
import 'map_screen.dart';
import 'mi_perfil.dart';

class Crear_Viaje extends StatefulWidget {
  // 🔒 Los campos del Widget deben ser inmutables (final)
  final int selectedIndex; // primer item de la bottom navigation bar seleccionado por defecto
  final int num_viaje;
  final List<Trip> viajes;
  final bool sesionIniciada;

  // Servicios/puertos (también inmutables)
  final TripRepository repo;
  final EntryRepository entryRepo;
  final TripService tripService;
  final EntryService entryService;
  final UserRepository userRepo;
  final UserService userService;
  final User? currentUser;  // 👈 AÑADIR ESTO



  const Crear_Viaje({
    super.key,
    required this.selectedIndex,
    required this.sesionIniciada,
    required this.viajes,
    required this.num_viaje,
    required this.repo,
    required this.entryRepo,
    required this.tripService,
    required this.entryService,
    required this.userRepo,
    required this.userService,
    this.currentUser,      // 👈 AÑADIR ESTO
  });

  @override
  _CrearViajeState createState() => _CrearViajeState();
}

class _CrearViajeState extends State<Crear_Viaje> {
  // 🔁 Estado mutable aquí (no en el Widget)
  late int _selectedIndex;

  // Controladores deben vivir en el State y hacerse dispose()
  late final TextEditingController _titulo;
  late final TextEditingController _fecha_ini;
  late final TextEditingController _fecha_fin;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;

    _titulo = TextEditingController();
    _fecha_ini = TextEditingController();
    _fecha_fin = TextEditingController();

    // Rellena campos si venimos en modo edición
    if (widget.num_viaje >= 0) {
      final trip = widget.viajes[widget.num_viaje];
      final fechaInicial =
          DateFormat('dd-MM-yyyy').format(trip.startDate ?? DateTime.now());
      final fechaFinal =
          DateFormat('dd-MM-yyyy').format(trip.endDate ?? DateTime.now());
      _titulo.text = trip.title;
      _fecha_ini.text = fechaInicial;
      _fecha_fin.text = fechaFinal;
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _fecha_ini.dispose();
    _fecha_fin.dispose();
    super.dispose();
  }

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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
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
      body: Center(
        child: Column(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              InputField(
                key: const Key('tituloField'),
                controller: _titulo,
                hintText: 'Titulo del viaje',
              ),
              const SizedBox(height: 10),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 10),
              InputField(
                key: const Key('fechaIniField'),
                controller: _fecha_ini,
                hintText: 'Fecha de inicio de viaje (DD-MM-YYYY)',
              ),
              const SizedBox(height: 10),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 10),
              InputField(
                key: const Key('fechaFinField'),
                controller: _fecha_fin,
                hintText: 'Fecha de fin de viaje (DD-MM-YYYY)',
              ),
              const SizedBox(height: 10),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              RoundedButton
              (
                key: const Key('guardarButton'),
                text: 'Guardar',
                backgroundColor: Colors.white,
                textColor: Colors.black,
                onPressed: () async {
                  final titulo = _titulo.text.trim();
                  final ini = _parseDdMmYyyy(_fecha_ini.text.trim());
                  final fin = _parseDdMmYyyy(_fecha_fin.text.trim());

                  if (titulo.isEmpty || ini == null || fin == null) {
                    _showError('Rellena todos los campos con formato válido (DD-MM-YYYY).');
                    return;
                  }
                  if (ini.isAfter(fin)) {
                    _showError('La fecha de inicio no puede ser posterior a la final');
                    return;
                  }
                  if (titulo.length > Trip.titleMax) {
                    _showError('El título debe contener entre 1 y ${Trip.titleMax} caracteres');
                    return;
                  }

                  final nuevoId = DateTime.now().millisecondsSinceEpoch.toString();
                  final cmd = CreateTripCommand(
                    id: nuevoId,
                    title: titulo,
                    description: 'Description',
                    startDate: ini,
                    endDate: fin,
                  );

                  // Servicio de aplicación
                  final result = await widget.tripService.create(cmd);

                  if (!mounted) return; // evita usar context tras async gap

                  if (result is Ok<Trip>) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Viaje creado correctamente')),
                    );
                    Navigator.pop(context); // vuelve a la lista
                  } else if (result is Err<Trip>) {
                    final errors = result.errors.map((e) => e.message).join('\n');
                    _showError('Error al crear viaje:\n$errors');
                  }
                },
              ),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFFEDE5D0),
        unselectedItemColor: Colors.black,
        selectedItemColor: Colors.teal[500],
        iconSize: 35,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Mis viajes'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Nuevo viaje'),
          BottomNavigationBarItem(icon: Icon(Icons.equalizer), label: 'Datos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mi perfil'),
        ],
        onTap: (int inIndex) {
          setState(() {
            _selectedIndex = inIndex; // muta el estado, no el widget
          });
          if (_selectedIndex == 0) {
            Navigator.pop(context);  // vuelve a Mis viajes sin perder el estado
          } else if (_selectedIndex == 1) {
            // Ir al mapa
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MapaPaisScreen(
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
          } else if (_selectedIndex == 4) {
            if (widget.sesionIniciada && widget.currentUser != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MiPerfil(
                    selectedIndex: 4,
                    sesionIniciada: widget.sesionIniciada,
                    viajes: widget.viajes,
                    tripRepo: widget.repo,
                    entryRepo: widget.entryRepo,
                    tripService: widget.tripService,
                    entryService: widget.entryService,
                    userRepo: widget.userRepo,
                    userService: widget.userService,
                    currentUser: widget.currentUser!,   // 👈 IMPORTANTE
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(
                    selectedIndex: 2,
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
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        ),
        child: Text(text, style: TextStyle(color: textColor)),
      ),
    );
  }
}
