/// Texts of the Cookie Jar notices
abstract final class CookieMessages {
  /// a cookie was created.
  static const added = 'Fresh out of the oven! Your cookie is in the jar 🍪';

  /// the photo could not be written to the phone.
  static const notEnoughSpace =
      'Not enough space on this phone to save the picture';

  /// a cookie was eaten (with Undo).
  static const eaten = 'Cookie eaten 🍪';
  static const undo = 'Undo';

  static const deleted = 'Cookie deleted forever';

  ///  dictation failed without internet.
  static const offlineVoiceNotReady = 'Offline voice not ready. Please type.';
  static const dictationStopped = 'Dictation stopped. Try again or type.';
  static const allowMicrophone = 'Allow the microphone to dictate.';
  static const holdToDictate = 'Hold the mic to dictate, release to finish.';
  static const allowCamera = 'Allow the camera to take a photo.';
  static const cameraFailed = "Couldn't take the photo. Try again.";

  /// In the detail, instead of a photo that is not on this phone.
  static const pictureNotHere = 'The picture is not on this phone';

  /// a cookie created without network.
  static const savedOffline =
      "Cookie baked on this phone 🍪 It will upload when you're back online";

  /// the network dropped with the tool open.
  static const wentOffline =
      "You're offline. Your cookie jar still works; gifts and friends will wait";

  /// the network came back.
  static const backOnline = 'Back online. Syncing your cookies…';

  /// nothing is left to upload.
  static const allBackedUp = 'All your cookies are backed up ✓';

  /// deleted forever without network.
  static const deletedOffline =
      "Deleted from this phone. It will be deleted from the cloud when you're back online";

  /// the photo is not on this phone and there is no network.
  static const pictureNeedsInternet =
      'Connect to the internet to see this picture';

  /// the photo download failed.
  static const pictureFailed =
      "Couldn't load the picture. Check your connection";

  /// a new phone (it never downloaded) without network.
  static const cookiesInCloud =
      'Your cookies are in the cloud. Connect to the internet to bring them here';

  /// the download of changes failed with network (a slow one).
  static const syncFailed = "Couldn't sync right now. We'll keep trying";

  static const retry = 'Retry';

  /// In the detail, instead of a photo that is still in the cloud.
  static const pictureWhenOnline =
      "The picture will show when you're back online";

  /// Preparing the photo (the compression runs in the background).
  static const preparingPhoto = 'Preparing the photo…';

  /// cookies arrived from another phone of the same account.
  static String arrivedFromOtherDevices(int count) => count == 1
      ? '1 cookie arrived from your other devices'
      : '$count cookies arrived from your other devices';

  /// two phones created the same title offline.
  static String existedOnTwoPhones(String title, String finalTitle) =>
      '"$title" existed on two phones. One is now "$finalTitle"';

  /// Above the jar while something waits to upload.
  static String waitingToUpload(int count) => count == 1
      ? '⏳ 1 cookie waiting to upload'
      : '⏳ $count cookies waiting to upload';

  /// the title existed and was saved with a suffix.
  static String renamed(String typedTitle, String finalTitle) =>
      '"$typedTitle" already exists. Baked as "$finalTitle"';

  ///  an eaten cookie went back to the jar.
  static String backInJar(String title) => '"$title" is back in the jar';

  /// Under the title field, before saving, when a suffix will be added.
  static String willBeSavedAs(String finalTitle) =>
      'Will be baked as "$finalTitle"';
}
