
class PendingWrite {
  const PendingWrite({
    required this.path,
    required this.userId,
    required this.data,
    required this.createdAt,
  });

  final String path;


  final String userId;
  final Map<String, Object?> data;
  final DateTime createdAt;
}


enum SaveOutcome { saved, savedOffline }
