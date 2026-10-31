import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart' show XFile;
import 'package:frontend_flutter/data/services/auth_service.dart';
import 'package:frontend_flutter/data/services/connectivity_service.dart';
import 'package:frontend_flutter/data/services/local/photo_dao.dart';
import 'package:frontend_flutter/data/services/local/photo_storage_service.dart';
import 'package:frontend_flutter/data/services/photo_compressor.dart';
import 'package:frontend_flutter/data/services/remote/photo_remote_service.dart';
import 'package:intl/intl.dart';

final dayFormat = DateFormat('yyyy-MM-dd');

/// Answers with whoever [userId] says, without touching Firebase.
class FakeAuth extends AuthService {
  FakeAuth(this.userId);

  String? userId;

  @override
  String? get currentUserId => userId;
}

/// Keeps the photos of every account in one temporary folder, laid out the
/// same way the real service does: one subfolder per user.
class FakeStorage extends PhotoStorageService {
  FakeStorage(this.root);

  final Directory root;

  File _fileFor(String userId, DateTime day) =>
      File('${root.path}/$userId/${dayFormat.format(day)}.jpg');

  @override
  Future<File?> photoFor(String userId, DateTime day) async {
    final file = _fileFor(userId, day);
    return await file.exists() ? file : null;
  }

  @override
  Future<File> save(String userId, DateTime day, XFile photo) async {
    final file = _fileFor(userId, day);
    await file.parent.create(recursive: true);
    await file.writeAsString(await photo.readAsString());
    return file;
  }

  /// Loose files sit straight in the root, the way they did before each
  /// account had a folder.
  @override
  Future<void> deleteSharedLeftovers() async {
    cleanups++;
    await for (final found in root.list()) {
      if (found is File) await found.delete();
    }
  }

  int cleanups = 0;
}

/// The rows the real DAO keeps in one database per account.
class FakeDao extends PhotoDao {
  final Map<String, Map<String, bool>> rows = {};

  Map<String, bool> _of(String userId) => rows.putIfAbsent(userId, () => {});

  @override
  Future<void> insert(String userId, DateTime day) async =>
      _of(userId)[dayFormat.format(day)] = false;

  @override
  Future<Set<DateTime>> daysBetween(
    String userId,
    DateTime first,
    DateTime last,
  ) async => {
    for (final day in _of(userId).keys)
      if (!DateTime.parse(day).isBefore(first) &&
          !DateTime.parse(day).isAfter(last))
        DateTime.parse(day),
  };

  @override
  Future<List<DateTime>> notSyncedDays(String userId) async => [
    for (final row in _of(userId).entries)
      if (!row.value) DateTime.parse(row.key),
  ];

  @override
  Future<void> markSynced(String userId, DateTime day) async =>
      _of(userId)[dayFormat.format(day)] = true;

  @override
  Future<void> deleteSharedDatabase() async => sharedDatabaseDeleted = true;

  bool sharedDatabaseDeleted = false;
}

/// Firebase as seen by the app: what each account has there, and who asked
/// for what.
class FakeRemote extends PhotoRemoteService {
  final uploads = <String>[];
  final downloads = <String>[];

  /// What is already in Firebase, by `userId/yyyy-MM-dd`.
  final stored = <String, String>{};

  /// Set to throw instead of answering, the way no connection does.
  Object? failure;

  @override
  Future<void> upload(String userId, DateTime day, Uint8List photo) async {
    uploads.add('$userId/${dayFormat.format(day)}');
    stored['$userId/${dayFormat.format(day)}'] = String.fromCharCodes(photo);
  }

  @override
  Future<Set<DateTime>> daysWithPhoto(
    String userId,
    DateTime first,
    DateTime last,
  ) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    return {
      for (final key in stored.keys)
        if (key.startsWith('$userId/'))
          if (DateTime.parse(key.split('/').last) case final day
              when !day.isBefore(first) && !day.isAfter(last))
            day,
    };
  }

  @override
  Future<List<int>?> download(String userId, DateTime day) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    final key = '$userId/${dayFormat.format(day)}';
    downloads.add(key);
    return stored[key]?.codeUnits;
  }
}

class FakeConnectivity extends ConnectivityService {
  FakeConnectivity({this.online = true});

  bool online;

  @override
  Future<bool> isOnline() async => online;
}

/// Stands in for the isolate: tags the copy so a test can tell it from the
/// original, or fails the way an unreadable file does.
class FakeCompressor extends PhotoCompressor {
  final compressed = <String>[];
  Object? failure;

  @override
  Future<Uint8List> compress(String path) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    compressed.add(path);
    final original = await File(path).readAsString();
    return Uint8List.fromList('small($original)'.codeUnits);
  }
}
