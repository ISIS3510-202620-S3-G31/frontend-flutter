import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/repositories/auth_repository.dart';
import 'package:frontend_flutter/data/repositories/photo_repository.dart';
import 'package:frontend_flutter/ui/auth/view_model/auth_view_model.dart';

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository(this.signedIn);

  String? signedIn;
  Object? failure;

  @override
  String? get currentUserId => signedIn;

  @override
  Future<void> signOut() async {
    final failure = this.failure;
    if (failure != null) throw failure;
    signedIn = null;
  }
}

class FakePhotoRepository extends PhotoRepository {
  final forgotten = <String>[];
  Object? failure;

  @override
  Future<void> forgetCached(String userId) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    forgotten.add(userId);
  }
}

void main() {
  late FakeAuthRepository auth;
  late FakePhotoRepository photos;
  late AuthViewModel viewModel;

  setUp(() {
    auth = FakeAuthRepository('ana');
    photos = FakePhotoRepository();
    viewModel = AuthViewModel(repository: auth, photos: photos);
  });

  tearDown(() => viewModel.dispose());

  test('signing out drops what this phone cached for that account', () async {
    await viewModel.signOut();

    expect(photos.forgotten, ['ana']);
    expect(viewModel.isAuthenticated, isFalse);
  });

  test('a failed sign-out leaves the cache alone', () async {
    auth.failure = Exception('no connection');

    await viewModel.signOut();

    expect(photos.forgotten, isEmpty);
    expect(viewModel.errorMessage, isNotNull);
  });

  test('a cache that will not clear does not look like a failed sign-out', () async {
    photos.failure = Exception('the file is locked');

    await viewModel.signOut();

    expect(viewModel.errorMessage, isNull);
    expect(viewModel.isAuthenticated, isFalse);
  });
}
