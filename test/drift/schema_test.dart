import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

/// Schema v1 is exported to drift_schemas/ so future versions get generated
/// migration tests (`dart run drift_dev make-migrations`, ADR 0002).
void main() {
  test('current schema matches the exported v1 schema', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    expect(db.schemaVersion, 1);

    final file = File('drift_schemas/app_database/drift_schema_v1.json');
    expect(file.existsSync(), isTrue, reason: 'run drift_dev make-migrations');
    final exported =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final entities = (exported['entities'] as List)
        .cast<Map<String, dynamic>>()
        .where((e) => e['type'] == 'table')
        .map((e) => (e['data'] as Map<String, dynamic>)['name'])
        .toSet();
    expect(entities, {for (final t in db.allTables) t.actualTableName});

    // Opening creates every table and the foreign-key pragma is on.
    await db.customSelect('SELECT 1').get();
    final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(fk.data.values.first, 1);
  });
}
