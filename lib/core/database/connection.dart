import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

/// Opens the file-backed [AppDatabase] in the app's documents sandbox.
///
/// The DB file lives in the app sandbox (NOT an OS auto-backup location) so the
/// v1 "local content not recoverable after reinstall" behavior is deterministic
/// (see plan §6 Scenario 3). Integration/DI should register the result of this
/// as a lazy singleton.
Future<AppDatabase> openAppDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'auralearn.sqlite'));
  return AppDatabase(NativeDatabase.createInBackground(file));
}
