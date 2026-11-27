/// Texts of the Cookie Jar notices
abstract final class CookieMessages {
  /// a cookie was created.
  static const added = 'Cookie added to your jar 🍪';

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
  static const allowCamera = 'Allow the camera to take a photo.';
  static const cameraFailed = "Couldn't take the photo. Try again.";

  /// In the detail, instead of a photo that is not on this phone.
  static const pictureNotHere = 'The picture is not on this phone';

  /// the title existed and was saved with a suffix.
  static String renamed(String typedTitle, String finalTitle) =>
      '"$typedTitle" already exists. Saved as "$finalTitle"';

  ///  an eaten cookie went back to the jar.
  static String backInJar(String title) => '"$title" is back in the jar';

  /// Under the title field, before saving, when a suffix will be added.
  static String willBeSavedAs(String finalTitle) =>
      'Will be saved as "$finalTitle"';
}
