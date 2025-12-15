import 'package:journi/domain/entry.dart';

List<Entry> filterEntriesByText({
  required List<Entry> entries,
  required String query,
}) {
  if (query.trim().isEmpty) {
    return entries;
  }

  final lowerQuery = query.toLowerCase();

  return entries.where((e) {
    return e.type == EntryType.note &&
        e.text != null &&
        e.text!.toLowerCase().contains(lowerQuery);
  }).toList();
}
