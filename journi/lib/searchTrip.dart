import 'package:flutter/material.dart';
import 'package:journi/domain/trip.dart';

class SearchTripsDelegate extends SearchDelegate<Trip?> {
  final List<Trip> allTrips;

  SearchTripsDelegate(this.allTrips);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  // -------------------------------
  //       FILTRADO DE VIAJES
  // -------------------------------
  DateTime? _parseDate(String input) {
    input = input.trim();

    // Caso ISO: 2024-05-01
    final iso = DateTime.tryParse(input);
    if (iso != null) return iso;

    // dd/MM/yyyy
    final r1 = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
    final m1 = r1.firstMatch(input);
    if (m1 != null) {
      final d = int.parse(m1.group(1)!);
      final m = int.parse(m1.group(2)!);
      final y = int.parse(m1.group(3)!);
      return DateTime(y, m, d);
    }

    // dd-MM-yyyy
    final r2 = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$');
    final m2 = r2.firstMatch(input);
    if (m2 != null) {
      final d = int.parse(m2.group(1)!);
      final m = int.parse(m2.group(2)!);
      final y = int.parse(m2.group(3)!);
      return DateTime(y, m, d);
    }

    return null;
  }

  List<Trip> _filterTrips() {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return allTrips;

    // Intentamos rango: "01/05/2024 a 10/05/2024"
    DateTime? rStart, rEnd;
    if (q.contains(" a ")) {
      final parts = q.split(" a ");
      if (parts.length == 2) {
        rStart = _parseDate(parts[0]);
        rEnd = _parseDate(parts[1]);
      }
    }

    // Intentamos fecha individual
    final parsedSingleDate = _parseDate(q);
    final parsedYear = _parseYear(q);

    return allTrips.where((trip) {
      final titleOK = trip.title.toLowerCase().contains(q);

      final start = trip.startDate;
      final end = trip.endDate;

      bool dateOK = false;

      // Comparación con fecha exacta
      if (parsedSingleDate != null && start != null) {
        final s = DateTime(start.year, start.month, start.day);
        final e = end != null ? DateTime(end.year, end.month, end.day) : s;
        final p = DateTime(parsedSingleDate.year, parsedSingleDate.month,
            parsedSingleDate.day);

        if (p.isAtSameMomentAs(s) ||
            p.isAtSameMomentAs(e) ||
            (p.isAfter(s) && p.isBefore(e))) {
          dateOK = true;
        }
      }

      // Comparación con rango
      if (rStart != null && rEnd != null && start != null && end != null) {
        final s = DateTime(start.year, start.month, start.day);
        final e = DateTime(end.year, end.month, end.day);

        if (!(e.isBefore(rStart!) || s.isAfter(rEnd!))) {
          dateOK = true;
        }
      }

      // Comparación con año (yyyy)
      if (parsedYear != null && start != null) {
        final sYear = start.year;
        final eYear = end?.year ?? start.year;

        if (parsedYear >= sYear && parsedYear <= eYear) {
          dateOK = true;
        }
      }

      return titleOK || dateOK;
    }).toList();
  }

  int? _parseYear(String input) {
    final r = RegExp(r'^\d{4}$');
    if (r.hasMatch(input)) {
      final y = int.tryParse(input);
      if (y != null && y > 1900 && y < 2100) {
        return y;
      }
    }
    return null;
  }

  // -------------------------------
  //     RESULTADOS ESTILO MAIN
  // -------------------------------
  @override
  Widget buildResults(BuildContext context) {
    final results = _filterTrips();

    return Container(
      color: Colors.teal[200], // FONDO IGUAL QUE EL MAIN
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: results.length,
        itemBuilder: (context, i) {
          final trip = results[i];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.flight_takeoff, color: Colors.teal),
              title: Text(
                trip.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (trip.startDate != null)
                    Text(
                      'Inicio: ${trip.startDate!.toLocal().toString().split(' ')[0]}',
                    ),
                  if (trip.endDate != null)
                    Text(
                      'Fin: ${trip.endDate!.toLocal().toString().split(' ')[0]}',
                    ),
                  const SizedBox(height: 4),
                ],
              ),
              isThreeLine: true,
              onTap: () => close(context, trip),
            ),
          );
        },
      ),
    );
  }

  // SUGERENCIAS = mismos resultados
  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
