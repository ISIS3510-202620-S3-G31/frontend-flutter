
class ScreamGoal {
  const ScreamGoal({this.targetDb = 85, this.floorDb = 40})
    : assert(targetDb > floorDb);

  final double targetDb;

  final double floorDb;

  double progressOf(double db) =>
      ((db - floorDb) / (targetDb - floorDb)).clamp(0.0, 1.0);

  bool isReached(double db) => db >= targetDb;
}
