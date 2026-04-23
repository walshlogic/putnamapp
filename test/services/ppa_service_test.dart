import 'package:flutter_test/flutter_test.dart';
import 'package:putnamlife/exceptions/app_exceptions.dart';
import 'package:putnamlife/services/ppa_service.dart';

// These tests cover the guard clauses that short-circuit before the Supabase
// client is touched. End-to-end happy-path coverage (network + ppa schema
// round-trips) belongs against a live Supabase test project and is not wired
// up in this repo yet.
void main() {
  final service = PpaService.instance;

  group('PpaService input validation', () {
    test('searchByAddress returns empty list for blank query', () async {
      expect(await service.searchByAddress(''), isEmpty);
      expect(await service.searchByAddress('   '), isEmpty);
    });

    test('searchByOwner returns empty list for blank query', () async {
      expect(await service.searchByOwner(''), isEmpty);
      expect(await service.searchByOwner('\t '), isEmpty);
    });

    test('getParcelDetail throws ValidationException for blank parcel', () {
      expect(
        () => service.getParcelDetail(''),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => service.getParcelDetail('   '),
        throwsA(isA<ValidationException>()),
      );
    });

    test('getParcelDetail throws ValidationException when asterisk is the only char', () {
      // The ingest parser strips a trailing `*` continuation marker, so a
      // lone `*` is effectively an empty parcel number.
      expect(
        () => service.getParcelDetail('*'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('estimateTax throws ValidationException for negative taxable value', () {
      expect(
        () => service.estimateTax(taxableValue: -1, rollYear: 2025),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
