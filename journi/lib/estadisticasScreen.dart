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
import 'main.dart';
import 'map_screen.dart';
import 'package:fl_chart/fl_chart.dart';

import 'mi_perfil.dart';

// ignore: must_be_immutable
class EstadisticasScreen extends StatefulWidget {
  int selectedIndex;
  final bool sesionIniciada;
  List<Trip> viajes;
  final TripRepository tripRepo;
  final EntryRepository entryRepo;
  final TripService tripService;
  final EntryService entryService;
  final UserRepository userRepo;
  final UserService userService;

  final User? currentUser;

  EstadisticasScreen({
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
  State<EstadisticasScreen> createState() => _EstadisticasState();
}

class _EstadisticasState extends State<EstadisticasScreen> {
  @override
  Widget build(BuildContext context) {
    final paisesVisitados = widget.viajes
        .map((trip) => trip.title) // o trip.pais según tu modelo
        .toSet()
        .length;

    final bool noHayViajes = widget.viajes.isEmpty;

    return Scaffold(
      backgroundColor: Colors.teal[200],
      appBar: AppBar(
        backgroundColor: Colors.teal[200],
        title: const Text('Mis estadísticas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mensaje dinámico de países visitados o sin viajes
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.teal[100],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: widget.viajes.isEmpty
                            ? const [
                                TextSpan(
                                  text:
                                      "🌍 Todavía no tienes ningún viaje registrado.\n",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                TextSpan(
                                  text: "¿Quieres crear uno?",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ]
                            : [
                                TextSpan(
                                  text: "🌍 ¡Enhorabuena!\n",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      "Has realizado ${widget.viajes.map((t) => t.title).toSet().length} viajes",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const TextSpan(
                                  text: " ✈️✨",
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Mostrar botón solo si no hay viajes
                    if (widget.viajes.isEmpty)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final Trip? nuevoViaje = await Navigator.push<Trip>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Crear_Viaje(
                                selectedIndex: widget.selectedIndex,
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
                          //  Agregamos el viaje a la lista y reconstruimos
                          if (nuevoViaje != null) {
                            setState(() {
                              widget.viajes.add(nuevoViaje);
                            });
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Crear viaje'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ---------- TITULO -------------
            Text(
              "Resumen de tus viajes",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal[900],
              ),
            ),

            const SizedBox(height: 20),

            _buildChartCard(
              title: "Duración de cada viaje (días)",
              chart: _buildBarChart(viajes: widget.viajes),
            ),
            const SizedBox(height: 20),
            _buildChartCard(
              title: "Destinos visitados",
              chart: _buildPieChart(viajes: widget.viajes),
            ),
            const SizedBox(height: 30),
          ],
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
            Navigator.push(
              context,
              MaterialPageRoute(
                // cuando este con sesion iniciada habra que cambiarlo para que vaya directamente a la pantalla del perfil
                builder: (context) => MyHomePage(
                  title: 'JOURNI',
                  sesionIniciada: widget.sesionIniciada,
                  viajes: widget.viajes,
                  skipLogin: false,
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
          }
          if (index == 2) {
            // Nuevo viaje
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Crear_Viaje(
                  selectedIndex: widget.selectedIndex,
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
            // Mapa
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
            // Estadisticas
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
                  currentUser: widget.currentUser,
                ),
              ),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MiPerfil(
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
}

Widget _buildChartCard({required String title, required Widget chart}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(height: 200, child: chart),
      ],
    ),
  );
}

Widget _buildBarChart({required List<Trip> viajes}) {
  if (viajes.isEmpty) {
    return const Center(
      child: Text(
        "Aún no tienes viajes registrados.",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  final List<BarChartGroupData> barGroups = [];
  final List<String> labels = [];

  for (int i = 0; i < viajes.length; i++) {
    final trip = viajes[i];

    if (trip.startDate != null && trip.endDate != null) {
      final int days = trip.endDate!.difference(trip.startDate!).inDays + 1;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: days.toDouble(),
            ),
          ],
        ),
      );

      labels.add(trip.title);
    }
  }

  // Calcular el viaje más largo para ajustar el eje
  final int maxDays = barGroups
      .map((g) => g.barRods.first.toY.toInt())
      .fold(0, (a, b) => a > b ? a : b);

  return BarChart(
    BarChartData(
      maxY: maxDays + 2,
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true, // activamos las líneas de la cuadrícula
        drawHorizontalLine: true, // solo horizontales
        drawVerticalLine: false, // quitamos las verticales
        horizontalInterval:
            (maxDays / 5).ceilToDouble(), // espacio entre líneas
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.black12, // color de la línea
          strokeWidth: 1, // grosor
        ),
      ),
      barGroups: barGroups,
      titlesData: FlTitlesData(
        topTitles: AxisTitles(
          sideTitles: SideTitles(
              showTitles: false), // <--- ocultamos los números de arriba
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              int index = value.toInt();
              if (index < 0 || index >= labels.length) return const Text("");
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  labels[index],
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            interval: (maxDays / 5).ceilToDouble(),
            getTitlesWidget: (value, _) => Text("${value.toInt()}"),
          ),
        ),
      ),
    ),
  );
}

Widget _buildPieChart({required List<Trip> viajes}) {
  if (viajes.isEmpty) {
    return const Center(
      child: Text(
        "Aún no tienes viajes registrados.",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  final List<PieChartSectionData> secciones = [];

  for (final trip in viajes) {
    // Si falta alguna fecha, ignoramos ese viaje
    if (trip.startDate == null || trip.endDate == null) continue;

    final int days = trip.endDate!.difference(trip.startDate!).inDays + 1;

    secciones.add(
      PieChartSectionData(
        value: days.toDouble(), // tamaño según duración
        title: trip.title, // nombre del viaje
        radius: 45,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  return PieChart(
    PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 40,
      sections: secciones,
    ),
  );
}
