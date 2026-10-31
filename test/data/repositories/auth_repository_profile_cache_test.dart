import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/user_model.dart';
import 'package:frontend_flutter/data/repositories/auth_repository.dart';
import 'package:frontend_flutter/data/services/auth_service.dart';
import 'package:frontend_flutter/data/services/connectivity_service.dart';
import 'package:frontend_flutter/data/services/local/user_profile_cache.dart';

/// Counts the reads of users/{uid} instead of making them.
class FakeAuthService implements AuthService {
  FakeAuthService(this.uid);

  String? uid;
  int reads = 0;
  bool offline = false;

  @override
  String? get currentUserId => uid;

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    reads++;
    if (offline) throw const AuthException('No connection');
    return UserModel(uid: uid, email: '$uid@mail.com', name: 'Reader $uid');
  }

  @override
  UserModel? currentSessionProfile() {
    final uid = this.uid;
    return uid == null
        ? null
        : UserModel(uid: uid, email: '$uid@mail.com', name: '');
  }

  @override
  Future<void> signOut() async => uid = null;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final uid = email.split('@').first;
    this.uid = uid;
    return UserModel(uid: uid, email: email, name: '');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Always online, so signing in goes ahead without the plugin.
class OnlineConnectivity implements ConnectivityService {
  @override
  Future<bool> isOnline() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late DateTime clock;
  late FakeAuthService service;
  late AuthRepository repository;

  setUp(() {
    clock = DateTime(2026, 10, 31, 12);
    service = FakeAuthService('ana');
    repository = AuthRepository(
      service: service,
      connectivity: OnlineConnectivity(),
      profileCache: UserProfileCache(now: () => clock),
    );
  });

  test('reads Firestore once and then answers from memory', () async {
    final first = await repository.getCurrentUserProfile();
    final second = await repository.getCurrentUserProfile();

    expect(service.reads, 1);
    expect(second, same(first));
    expect(repository.cachedCurrentUserProfile, same(first));
  });

  test('reads again once the copy is 10 minutes old', () async {
    await repository.getCurrentUserProfile();

    clock = clock.add(const Duration(minutes: 9));
    await repository.getCurrentUserProfile();
    expect(service.reads, 1);

    clock = clock.add(const Duration(minutes: 1));
    await repository.getCurrentUserProfile();
    expect(service.reads, 2);
  });

  test('a refresh skips the cache', () async {
    await repository.getCurrentUserProfile();
    await repository.getCurrentUserProfile(refresh: true);

    expect(service.reads, 2);
  });

  test('a refresh that fails keeps the copy it had', () async {
    final first = await repository.getCurrentUserProfile();
    service.offline = true;

    expect(await repository.getCurrentUserProfile(refresh: true), same(first));
  });

  test('signing out forgets the profile, even for the same account', () async {
    await repository.getCurrentUserProfile();
    await repository.signOut();
    service.uid = 'ana';

    expect(repository.cachedCurrentUserProfile, isNull);
  });

  test("a second account never sees the first one's profile", () async {
    await repository.getCurrentUserProfile();
    await repository.signIn(email: 'ben@mail.com', password: 'Secret123');

    final profile = await repository.getCurrentUserProfile();

    expect(profile?.uid, 'ben');
    expect(service.reads, 2);
  });

  test('offline it answers with the session and caches nothing', () async {
    service.offline = true;

    final profile = await repository.getCurrentUserProfile();

    expect(profile?.uid, 'ana');
    expect(repository.cachedCurrentUserProfile, isNull);
  });
}
