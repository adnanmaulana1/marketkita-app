import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:marketkita_app/utils/format.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('rupiah', () {
    test('null menjadi Rp0', () {
      expect(rupiah(null), 'Rp0');
    });

    test('nol menjadi Rp0', () {
      expect(rupiah(0), 'Rp0');
    });

    test('format ribuan', () {
      expect(rupiah(1000000), 'Rp1.000.000');
    });

    test('format ratusan ribu', () {
      expect(rupiah(125000), 'Rp125.000');
    });
  });

  group('formatDate', () {
    test('null atau kosong mengembalikan string kosong', () {
      expect(formatDate(null), '');
      expect(formatDate(''), '');
    });

    test('dengan waktu memakai locale Indonesia', () {
      expect(formatDate('2026-08-09T10:00:00'), '09 Agu 2026, 10:00');
    });

    test('tanpa waktu', () {
      expect(formatDate('2026-08-09T10:00:00', withTime: false), '09 Agu 2026');
    });

    test('string tidak valid dikembalikan apa adanya', () {
      expect(formatDate('bukan-tanggal'), 'bukan-tanggal');
    });
  });
}
