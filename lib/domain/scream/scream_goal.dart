
class ScreamGoal {
  const ScreamGoal({this.targetDb = 85, this.secondsToFill = 5})
    : assert(secondsToFill > 0);

  final double targetDb;

  final double secondsToFill;

  bool isLoudEnough(double db) => db >= targetDb;

  double progressOf(double loudSeconds) =>
      (loudSeconds / secondsToFill).clamp(0.0, 1.0);

  bool isReached(double loudSeconds) => loudSeconds >= secondsToFill;
}
