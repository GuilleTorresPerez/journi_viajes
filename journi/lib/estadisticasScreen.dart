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
import 'map_screen.dart';
import 'package:fl_chart/fl_chart.dart';

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

  final User currentUser;

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
            // Mensaje dinámico de países visitados
            Builder(
              builder: (_) {
                final paisesVisitados = widget.viajes
                    .map((trip) => trip.title) // o trip.pais según tu modelo
                    .toSet()
                    .length;

                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
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
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: "🌍 ¡Enhorabuena!\n",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          TextSpan(
                            text: "Has visitado $paisesVisitados países",
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
                  ),
                );
              },
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

            // ---------- GRAFICA 1: DIAS POR VIAJE -------------
            _buildChartCard(
              title: "Duración de cada viaje (días)",
              chart: _buildBarChart(viajes: widget.viajes),
            ),

            const SizedBox(height: 20),

            // ---------- GRAFICA 2: DESTINOS VISITADOS ----------
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
            Navigator.pop(context);
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
        "Aún no tienes viajes",
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
      maxY: maxDays + 2, // espacio extra arriba
      borderData: FlBorderData(show: false),

      barGroups: barGroups,

      titlesData: FlTitlesData(
        // EJE X
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

        // APAGAR EJE DERECHO
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),

        // EJE IZQUIERDO CORREGIDO
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,

            // INTERVALOS PARA EVITAR SOLAPES
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
        "Aún no tienes viajes",
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
