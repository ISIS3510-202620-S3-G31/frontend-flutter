
class ScreamGoal {
  const ScreamGoal({
    this.minDb = 70,
    this.targetDb = 80,
    this.secondsToFill = 5,
  }) : assert(targetDb > minDb),
       assert(secondsToFill > 0);

  final double minDb;

  final double targetDb;

  final double secondsToFill;

  double fillRateOf(double db) =>
      ((db - minDb) / (targetDb - minDb)).clamp(0.0, 1.0);

  double progressOf(double loudSeconds) =>
      (loudSeconds / secondsToFill).clamp(0.0, 1.0);

  bool isReached(double loudSeconds) => loudSeconds >= secondsToFill;
}
