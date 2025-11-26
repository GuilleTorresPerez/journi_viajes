import 'package:flutter/material.dart';
import 'package:journi/login_screen.dart';

import 'application/entry_service.dart';
import 'application/trip_service.dart';
import 'application/user_service.dart';
import 'domain/ports/entry_repository.dart';
import 'domain/ports/trip_repository.dart';
import 'domain/ports/user_repository.dart';
import 'domain/trip.dart'; // para poder ir al login
import 'package:journi/application/use_cases/user_use_cases.dart';
import 'package:journi/application/shared/result.dart';
import 'package:journi/domain/user.dart';

// ignore: must_be_immutable
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

  RegisterScreen({
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
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  //final TextEditingController _idController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    //_idController.dispose();
    _nombreController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onGuardar() async {
    //final id = _idController.text.trim();
    final nombre = _nombreController.text.trim();
    final apellidos = _apellidosController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    print('DEBUG REGISTRO: "$nombre" "$apellidos" "$email" "$password"');

    if (nombre.isEmpty ||
        apellidos.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Falta algún campo')));
      return;
    }

    // 🔑 Generar un id aleatorio/simple para el usuario
    final generatedId = 'user_${DateTime.now().millisecondsSinceEpoch}';

    final cmd = RegisterUserCommand(
      id: generatedId,
      name: nombre,
      lastName: apellidos,
      email: email,
      password: password,
    );

    final result = await widget.userService.register(cmd);

    if (!mounted) return;

    if (result is Ok<User>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado correctamente')),
      );

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
    } else {
      final msg = result.errorsOrEmpty.isNotEmpty
          ? result.errorsOrEmpty.first.message
          : 'Error al registrar usuario';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
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
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                _buildInput(
                  _emailController,
                  'Correo electronico',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Contraseña
                _buildInput(_passwordController, 'Contraseña',
                    obscureText: true),

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

                SizedBox(height: 40),

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
