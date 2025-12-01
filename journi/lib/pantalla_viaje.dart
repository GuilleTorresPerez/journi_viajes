import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:journi/application/trip_service.dart';
import 'package:journi/application/entry_service.dart';
import 'package:journi/application/use_cases/entry_use_cases.dart';
import 'package:journi/domain/ports/entry_repository.dart';

import 'package:journi/domain/ports/trip_repository.dart';
import 'package:journi/domain/entry.dart';
import 'package:journi/domain/trip.dart' hide Ok;
import 'package:journi/domain/user.dart';
import 'package:video_player/video_player.dart';

import 'application/shared/result.dart';
import 'application/user_service.dart';
import 'crear_viaje.dart';
import 'domain/ports/user_repository.dart';
import 'editar_viaje.dart';
import 'map_screen.dart';
//import 'select_location_screen.dart';
import 'package:journi/login_screen.dart';

import 'mi_perfil.dart';

class Pantalla_Viaje extends StatefulWidget {
  final int
      selectedIndex; // primer item de la bottom navigation bar seleccionado por defecto
  final List<Trip> viajes;
  final int num_viaje;
  final ImagePicker? picker;
  final bool sesionIniciada;
  // 👉 Puerto (interfaz) en lugar del repo in-memory
  final TripRepository repo;
  final EntryRepository entryRepo;
  final TripService tripService;
  final EntryService entryService;
  final UserRepository userRepo;
  final UserService userService;
  final User? currentUser;

  Pantalla_Viaje(
      {super.key,
      required this.selectedIndex,
      required this.sesionIniciada,
      required this.viajes,
      required this.num_viaje,
      required this.repo,
      required this.entryRepo,
      required this.tripService,
      required this.entryService,
      this.picker,
      required this.userRepo,
      required this.userService,
      required this.currentUser});

  @override
  _PantallaViajeState createState() => _PantallaViajeState();
}

class _PantallaViajeState extends State<Pantalla_Viaje> {
  VideoPlayerController? _videoController;

  Future<void> _initVideo(File file) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(file);
    await _videoController!.initialize();
  }

  final ImagePicker _picker = ImagePicker();
  //final List<Map<String, dynamic>> _textos = []; // {texto, fecha}
  final TextEditingController _textoController = TextEditingController();

  late int _selectedIndex;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex; // snapshot inicial
  }

  @override
  Widget build(BuildContext context) {
    final currentTrip = widget.viajes[widget.num_viaje];

    return Scaffold(
      backgroundColor: Colors.teal[200],
      appBar: AppBar(
        backgroundColor: Colors.teal[200],
        title: Text(
          currentTrip.title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // BUSCAR / FILTRAR
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            tooltip: 'Buscar',
            onPressed: () {
              TextEditingController searchCtrl =
                  TextEditingController(text: _searchQuery);

              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Buscar por texto"),
                    content: TextField(
                      controller: searchCtrl,
                      decoration: const InputDecoration(
                        labelText: "Introduce texto a buscar",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancelar"),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _searchQuery = searchCtrl.text.trim());
                          Navigator.pop(context);
                        },
                        child: const Text("Aplicar"),
                      )
                    ],
                  );
                },
              );
            },
          ),

          // COMPARTIR VIAJE
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            tooltip: 'Compartir viaje',
            onPressed: () {
              TextEditingController emailCtrl = TextEditingController();

              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text(
                      "Compartir viaje",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo de la persona',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final email = emailCtrl.text.trim();
                          if (email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Introduce un correo válido')),
                            );
                            return;
                          }

                          Navigator.pop(context); // cerrar diálogo

                          final currentTrip = widget.viajes[widget.num_viaje];
                          final result = await widget.tripService
                              .shareTrip(currentTrip.id, email);

                          if (result is Ok<Unit>) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Invitación enviada a $email"),
                              ),
                            );
                          } else if (result is Err<Unit>) {
                            final errorMsg =
                                result.errors.map((e) => e.message).join(', ');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "Error al enviar invitación: $errorMsg"),
                              ),
                            );
                          }
                        },
                        child: const Text("Enviar"),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          // EDITAR
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            tooltip: 'Editar viaje',
            onPressed: () async {
              final updatedTrip = await Navigator.push<Trip?>(
                context,
                MaterialPageRoute(
                  builder: (context) => Editar_viaje(
                    selectedIndex: 2,
                    viajes: widget.viajes,
                    sesionIniciada: widget.sesionIniciada,
                    num_viaje: widget.num_viaje,
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

                if (updatedTrip != null) {
                  setState(() {
                    widget.viajes[widget.num_viaje] = updatedTrip; // actualiza la lista local
                  });
                }
            },
          ),

          // ELIMINAR
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.black),
            tooltip: 'Eliminar viaje',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Confirmar eliminación'),
                    content: const Text(
                      '¿Seguro que quieres eliminar este viaje?',
                    ),
                    actions: [
                      TextButton(
                        key: const Key('cancelarButton'),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        key: const Key('aceptarButton'),
                        onPressed: () async {
                          final tripToDelete = currentTrip;
                          final result = await widget.tripService.deleteById(
                            tripToDelete.id,
                          );
                          if (result is Ok<Unit>) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Viaje eliminado correctamente.'),
                              ),
                            );
                            widget.viajes.removeAt(widget.num_viaje);

                            Navigator.pop(context); // cierra diálogo
                            Navigator.pop(context); // vuelve a lista
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error al eliminar el viaje'),
                              ),
                            );
                          }
                        },
                        child: const Text('Eliminar'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // --- CONTENIDO PRINCIPAL ---
          StreamBuilder<List<Entry>>(
            stream: widget.entryService.watchByTrip(currentTrip.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'Aún no has añadido contenido.',
                    style: TextStyle(fontSize: 18),
                  ),
                );
              }

              List<Entry> entries = snapshot.data!;

              if (_searchQuery.isNotEmpty) {
                entries = entries.where((e) {
                  if (e.type == EntryType.note && e.text != null) {
                    return e.text!
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                  }
                  return false; // fotos y vídeos no se filtran
                }).toList();
              }

              return Column(children: [
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = "";
                        });
                      },
                      child: const Text("Deshacer búsqueda"),
                    ),
                  ),
                Expanded(
                    child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final e = entries[index];

                    // ---- TEXTO ----
                    if (e.type == EntryType.note && e.text != null) {
                      final fecha = e.createdAt.toLocal();
                      final fechaFormateada =
                          "${fecha.day.toString().padLeft(2, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.year} "
                          "${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}";

                      return Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.notes, color: Colors.teal),
                          title: Text(e.text!),
                          subtitle: Text('Añadido el $fechaFormateada'),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              await widget.entryService.deleteById(e.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Texto eliminado')),
                              );
                            },
                          ),
                        ),
                      );
                    }

                    // ---- FOTO ----
                    if (e.type == EntryType.photo && e.mediaUri != null) {
                      final file = File(e.mediaUri!);
                      final fecha = e.createdAt.toLocal();
                      final fechaFormateada =
                          "${fecha.day.toString().padLeft(2, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.year} "
                          "${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}";

                      return Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return Dialog(
                                          child: InteractiveViewer(
                                            panEnabled: true,
                                            child: Image.file(
                                              file,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(15),
                                    ),
                                    child: Image.file(
                                      file,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    await widget.entryService.deleteById(e.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Foto eliminada'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                'Añadida el $fechaFormateada',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // ---- VIDEO ----
                    if (e.type == EntryType.video && e.mediaUri != null) {
                      final file = File(e.mediaUri!);

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            FutureBuilder(
                              future: _initVideo(file),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState !=
                                    ConnectionState.done) {
                                  return const SizedBox(
                                    height: 200,
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }

                                return AspectRatio(
                                  aspectRatio:
                                      _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: () {
                                setState(() {
                                  _videoController!.value.isPlaying
                                      ? _videoController!.pause()
                                      : _videoController!.play();
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await widget.entryService.deleteById(e.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Video eliminado')),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ))
              ]);
            },
          ),

          // ---- COLUMNA FLOTANTE DE BOTONES ----
          Positioned(
            right: 15,
            top: 100,
            child: Column(
              children: [
                // Añadir texto
                FloatingActionButton(
                  mini: true,
                  heroTag: "btnTexto",
                  onPressed: () {
                    _textoController.clear();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Introduce un texto'),
                        content: TextField(
                          controller: _textoController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: 'Escribe aquí...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final texto = _textoController.text.trim();
                              if (texto.isEmpty) return;

                              final cmd = CreateEntryCommand(
                                id: UniqueKey().toString(),
                                tripId: currentTrip.id,
                                type: EntryType.note,
                                text: texto,
                              );
                              await widget.entryService.create(cmd);

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Texto añadido')),
                              );
                            },
                            child: const Text('Aceptar'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Icon(Icons.text_fields),
                ),
                const SizedBox(height: 12),

                // Añadir foto
                FloatingActionButton(
                  mini: true,
                  heroTag: "btnFoto",
                  onPressed: () {
                    // reutilizamos tu diálogo existente:
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text(
                          '¿Qué tipo de archivo multimedia quieres añadir?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final XFile? pickedFile = await _picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (pickedFile != null) {
                                final cmd = CreateEntryCommand(
                                  id: UniqueKey().toString(),
                                  tripId: currentTrip.id,
                                  type: EntryType.photo,
                                  mediaUri: pickedFile.path,
                                );
                                await widget.entryService.create(cmd);
                              }
                            },
                            child: const Text('Adjuntar foto'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final XFile? imagen = await _picker.pickImage(
                                source: ImageSource.camera,
                              );
                              if (imagen != null) {
                                final file = File(imagen.path);
                                final cmd = CreateEntryCommand(
                                  id: UniqueKey().toString(),
                                  tripId: currentTrip.id,
                                  type: EntryType.photo,
                                  mediaUri: file.path,
                                );
                                await widget.entryService.create(cmd);
                              }
                            },
                            child: const Text('Hacer foto'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final XFile? video = await _picker.pickVideo(
                                source: ImageSource.gallery,
                              );
                              if (video != null) {
                                final cmd = CreateEntryCommand(
                                  id: UniqueKey().toString(),
                                  tripId: currentTrip.id,
                                  type: EntryType.video,
                                  mediaUri: video.path,
                                );
                                await widget.entryService.create(cmd);
                              }
                            },
                            child: const Text('Adjuntar video'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Icon(Icons.camera_alt),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
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
        onTap: (int inIndex) {
          setState(() async {
            _selectedIndex = inIndex;
            if (_selectedIndex == 0) {
              // ✅ Volver a la home existente
              Navigator.pop(context);
            } else if (_selectedIndex == 1) {
              // Ir al mapa
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapaPaisScreen(
                    selectedIndex: widget.selectedIndex,
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
            } else if (widget.selectedIndex == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Crear_Viaje(
                    selectedIndex: widget.selectedIndex,
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
            } else if (_selectedIndex == 4) {
              // Perfil
              if (widget.sesionIniciada && widget.currentUser != null) {
                // Ya tenía sesión -> ir directo a MiPerfil
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
                      currentUser: widget.currentUser, //loggedUser
                    ),
                  ),
                );
              } else {
                // No hay sesión -> ir a Login y esperar resultado
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

                if (loggedUser != null && mounted) {
                  /*setState(() {
                    widget.currentUser = loggedUser;
                  });*/

                  // Una vez logueado, lo llevamos al perfil
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MiPerfil(
                        selectedIndex: _selectedIndex,
                        sesionIniciada: true,
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
          });
        },
      ),
    );
  }
}
