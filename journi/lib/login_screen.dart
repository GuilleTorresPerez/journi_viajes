import 'package:flutter/material.dart';
import 'application/entry_service.dart';
import 'application/trip_service.dart';
import 'application/user_service.dart';
import 'domain/ports/entry_repository.dart';
import 'domain/ports/trip_repository.dart';
import 'domain/ports/user_repository.dart';
import 'domain/trip.dart';
import 'mi_perfil.dart'; // importa tu pantalla de perfil
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final int selectedIndex;
  final List<Trip> viajes;
  final bool inicionSesiada;
  final TripRepository tripRepo;
  final EntryRepository entryRepo;
  final TripService tripService;
  final EntryService entryService;
  final UserRepository userRepo;
  final UserService userService;

  const LoginScreen({
    super.key,
    required this.inicionSesiada,
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
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onEntrar() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rellena correo y contraseña')),
      );
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'El correo introducido no sigue el formato correcto. Inténtelo de nuevo')),
      );
      return;
    }

    // 🔐 Simulamos login correcto
    //sesionIniciada = true; // ✅ Ahora la reconoce correctamente

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión iniciada correctamente')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MiPerfil(
          selectedIndex: widget.selectedIndex,
          inicionSesiada: true,
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
                'Iniciar sesión',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              // Campo correo electrónico
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE5D0),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Correo electronico',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campo contraseña
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE5D0),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Contraseña',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText; // alterna visibilidad
                        });
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegisterScreen(
                          selectedIndex: widget.selectedIndex,
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
                  },
                  child: const Text(
                    'Aun no tengo cuenta creada',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Botón "Entrar"
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onEntrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4B54C), // naranja
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Entrar',
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
}
