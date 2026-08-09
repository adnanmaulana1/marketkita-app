import 'package:intl/intl.dart';

String rupiah(int? value) {
  final v = value ?? 0;
  final f = NumberFormat('#,###', 'id_ID');
  return 'Rp${f.format(v)}';
}

String formatDate(String? iso, {bool withTime = true}) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final dt = DateTime.parse(iso).toLocal();
    final fmt = withTime ? DateFormat('dd MMM yyyy, HH:mm') : DateFormat('dd MMM yyyy');
    return fmt.format(dt);
  } catch (_) {
    return iso;
  }
}
