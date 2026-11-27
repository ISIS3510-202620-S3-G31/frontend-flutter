import 'dart:async';
import 'dart:typed_data';

import 'package:frontend_flutter/data/models/cookie_model.dart';
import 'package:frontend_flutter/data/services/connectivity_service.dart';
import 'package:frontend_flutter/data/services/local/cookie_sync_preferences.dart';
import 'package:frontend_flutter/data/services/remote/cookie_remote_service.dart';

class FakeConnectivity implements ConnectivityChecker {
  FakeConnectivity({this.online = true});

  bool online;

  @override
  Future<bool> isOnline() async => online;
}

/// Firestore and Storage of one account, in memory.
class FakeCookieRemote implements CookieRemoteService {
  final docs = <String, CookieModel>{};
  final images = <String, Uint8List>{};
  final calls = <String>[];

  /// The ids whose photo download fails, as if the network dropped.
  final failingDownloads = <String>{};

  /// When set, the next call fails like a lost connection.
  bool failNext = false;

  void _maybeFail() {
    if (failNext) {
      failNext = false;
      throw TimeoutException('network dropped');
    }
  }

  @override
  Future<String> uploadImage(
    String userId,
    String cookieId,
    Uint8List jpeg,
  ) async {
    _maybeFail();
    calls.add('image $cookieId');
    images[cookieId] = jpeg;
    return 'https://storage.example/$cookieId.jpg';
  }

  @override
  Future<CookieModel?> push(CookieModel cookie) async {
    _maybeFail();
    calls.add('doc ${cookie.id}');
    final cloud = docs[cookie.id];
    if (cloud != null && cloud.updatedAt > cookie.updatedAt) return cloud;
    docs[cookie.id] = CookieModel.fromFirestore(
      cookie.id,
      cookie.toFirestore(),
    );
    return null;
  }

  @override
  Future<List<CookieModel>> fetchAll(String userId) async {
    _maybeFail();
    return docs.values.toList();
  }

  @override
  Future<Uint8List?> downloadImage(String userId, String cookieId) async {
    if (failingDownloads.contains(cookieId)) {
      throw TimeoutException('network dropped');
    }
    return images[cookieId];
  }

  @override
  Future<void> delete(String userId, String cookieId) async {
    _maybeFail();
    calls.add('delete $cookieId');
    docs.remove(cookieId);
    images.remove(cookieId);
  }
}

class FakeSyncPreferences implements CookieSyncPreferences {
  final downloaded = <String>{};

  @override
  Future<bool> hasDownloaded(String userId) async =>
      downloaded.contains(userId);

  @override
  Future<void> markDownloaded(String userId) async => downloaded.add(userId);
}
