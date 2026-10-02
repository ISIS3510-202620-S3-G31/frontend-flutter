import '../../../../data/models/tear_model.dart';
import '../../../core/theme/app_colors.dart';

export '../../../../data/models/tear_model.dart';

/// Backward-compatible class matching the previous [TearEntry] signature,
/// subclassing [Tear] from the new data model.
class TearEntry extends Tear {
  const TearEntry({
    required super.id,
    required super.timestamp,
    required super.reliefLevel,
    required String reasonHonored,
    required String rootEmotion,
    required String compassionReflection,
    super.color = AppColors.secondary,
  }) : super(
          memoryTitle: rootEmotion,
          cryingReason: reasonHonored,
          reflectionNote: compassionReflection,
        );

  /// Sample tears forwarded to [Tear.samples].
  static List<Tear> get samples => Tear.samples;
}
