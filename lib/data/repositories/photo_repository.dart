import 'package:camera/camera.dart' show XFile;

import '../models/photo_model.dart';
import '../services/local/photo_storage_service.dart';

/// Single source of the photos of the day. The view model asks this class, not
/// the storage service, so the photos could later come from a server instead.
class PhotoRepository {
  PhotoRepository({PhotoStorageService? storage})
    : _storage = storage ?? PhotoStorageService();

  final PhotoStorageService _storage;

  /// The photo of [day], or null if that day has none.
  Future<DailyPhoto?> photoOf(DateTime day) async {
    final file = await _storage.photoFor(day);
    return file == null ? null : DailyPhoto(day: day, file: file);
  }

  /// Which of [days] already have a photo.
  Future<Set<DateTime>> daysWithPhoto(List<DateTime> days) =>
      _storage.daysWithPhoto(days);

  /// Stores [photo] (from the camera or the gallery) as the photo of [day].
  Future<DailyPhoto> savePhoto(DateTime day, XFile photo) async =>
      DailyPhoto(day: day, file: await _storage.save(day, photo));
}
