import 'package:flutter/material.dart';
import 'package:journi/login_screen.dart';

import 'application/entry_service.dart';
import 'application/trip_service.dart';
import 'application/user_service.dart';
import 'data/local/drift/app_database.dart';
import 'data/local/drift/drift_user_repository.dart';
import 'domain/ports/entry_repository.dart';
import 'domain/ports/trip_repository.dart';
import 'domain/ports/user_repository.dart';
import 'domain/trip.dart'; // para poder ir al login

class RegisterScreen extends StatefulWidget {
  final bool sesionIniciada;
  int selectedIndex;
  List<Trip> viajes;
  final TripRepository tripRepo;
  final EntryRepository entryRepo;
  final TripService tripService;
  final EntryService entryService;
  final UserRepository userRepo;
  final UserService userService;

  RegisterScreen(
      {super.key,
      required this.sesionIniciada,
      required this.viajes,
      required this.selectedIndex,
      required this.tripRepo,
      required this.entryRepo,
      required this.tripService,
      required this.entryService,
      required this.userRepo,
      required this.userService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onGuardar() {
    final nombre = _nombreController.text.trim();
    final apellidos = _apellidosController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (nombre.isEmpty ||
        apellidos.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rellena todos los campos')),
      );
      return;
    }

    // 🔐 Aquí iría tu lógica real de registro (API, base de datos, etc.)
    // De momento solo avisamos y podrías navegar donde quieras (perfil, login, etc.)

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario registrado correctamente')),
    );

    // Por ejemplo, tras registrar podrías ir a la pantalla de login:
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          selectedIndex: widget.selectedIndex,
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

  void _onYaTengoCuenta() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          selectedIndex: widget.selectedIndex,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C7470), // verde como en la imagen
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra superior con JOURNI y X
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'JOURNI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              const Text(
                'Crear Usuario',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              // Nombre
              _buildInput(_nombreController, 'Nombre'),
              const SizedBox(height: 16),

              // Apellidos
              _buildInput(_apellidosController, 'Apellidos'),
              const SizedBox(height: 16),

              // Correo electrónico
              _buildInput(_emailController, 'Correo electronico',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),

              // Contraseña
              _buildInput(_passwordController, 'Contraseña', obscureText: true),

              const SizedBox(height: 8),

              // Texto "Ya tengo una cuenta creada" clicable
              Center(
                child: GestureDetector(
                  onTap: _onYaTengoCuenta,
                  child: const Text(
                    'Ya tengo una cuenta creada',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onGuardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4B54C), // naranja
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String hintText, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDE5D0),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
        ),
      ),
    );
  }
}
