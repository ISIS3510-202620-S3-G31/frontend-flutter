import 'package:camera/camera.dart' show XFile;

import '../models/photo_model.dart';
import '../services/local/photo_storage_service.dart';

class PhotoRepository {
  PhotoRepository({PhotoStorageService? storage})
    : _storage = storage ?? PhotoStorageService();

  final PhotoStorageService _storage;

  Future<DailyPhoto?> photoOf(DateTime day) async {
    final file = await _storage.photoFor(day);
    return file == null ? null : DailyPhoto(day: day, file: file);
  }

  Future<Set<DateTime>> daysWithPhoto(List<DateTime> days) =>
      _storage.daysWithPhoto(days);

  Future<DailyPhoto> savePhoto(DateTime day, XFile photo) async =>
      DailyPhoto(day: day, file: await _storage.save(day, photo));
}
