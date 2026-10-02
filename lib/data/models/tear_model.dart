import 'package:flutter/material.dart';

import '../../ui/core/theme/app_colors.dart';

/// Represents a single recorded emotional tear entry.
class Tear {
  const Tear({
    required this.id,
    required this.timestamp,
    required this.memoryTitle,
    required this.cryingReason,
    required this.reliefLevel,
    required this.reflectionNote,
    this.color = AppColors.secondary,
  });

  final String id;
  final DateTime timestamp;
  final String memoryTitle;
  final String cryingReason;
  final int reliefLevel; // e.g. 8 for Lv. 8/10
  final String reflectionNote;
  final Color color;

  /// Convenience getters for UI compatibility
  String get reasonHonored => cryingReason;
  String get rootEmotion => memoryTitle;
  String get compassionReflection => reflectionNote;

  Tear copyWith({
    String? id,
    DateTime? timestamp,
    String? memoryTitle,
    String? cryingReason,
    int? reliefLevel,
    String? reflectionNote,
    Color? color,
  }) {
    return Tear(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      memoryTitle: memoryTitle ?? this.memoryTitle,
      cryingReason: cryingReason ?? this.cryingReason,
      reliefLevel: reliefLevel ?? this.reliefLevel,
      reflectionNote: reflectionNote ?? this.reflectionNote,
      color: color ?? this.color,
    );
  }

  /// Serializes to a Map suitable for Firebase Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'memoryTitle': memoryTitle,
      'cryingReason': cryingReason,
      'reliefLevel': reliefLevel,
      'reflectionNote': reflectionNote,
      'colorValue': color.toARGB32(),
    };
  }

  /// Deserializes from a Map (e.g. from Firebase Firestore).
  factory Tear.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      // Support for Firestore Timestamp if added in the future
      try {
        final dynamic dyn = value;
        if (dyn?.toDate != null) return dyn.toDate() as DateTime;
      } catch (_) {}
      return DateTime.now();
    }

    Color parseColor(dynamic value) {
      if (value is int) return Color(value);
      return AppColors.secondary;
    }

    return Tear(
      id: id ?? map['id']?.toString() ?? '',
      timestamp: parseDate(map['timestamp']),
      memoryTitle: map['memoryTitle']?.toString() ?? '',
      cryingReason: map['cryingReason']?.toString() ?? '',
      reliefLevel: (map['reliefLevel'] as num?)?.toInt() ?? 0,
      reflectionNote: map['reflectionNote']?.toString() ?? '',
      color: parseColor(map['colorValue']),
    );
  }

  /// Sample tears matching the design mockups.
  static final List<Tear> samples = [
    Tear(
      id: '1',
      timestamp: DateTime(2026, 9, 18, 22, 42),
      memoryTitle: 'Overwhelm & Anxiety',
      cryingReason: 'Overwhelm & deadline stress',
      reliefLevel: 8,
      reflectionNote:
          'You allowed your nervous system to reset. Drink a glass of water and rest your eyes for a few minutes.',
      color: AppColors.secondary,
    ),
    Tear(
      id: '2',
      timestamp: DateTime(2026, 9, 16, 19, 15),
      memoryTitle: 'Grief & Longing',
      cryingReason: 'Missing someone deeply',
      reliefLevel: 6,
      reflectionNote:
          'Grief is proof of love that was deeply felt. Be gentle with your tender heart today.',
      color: AppColors.primary,
    ),
    Tear(
      id: '3',
      timestamp: DateTime(2026, 9, 12, 23, 3),
      memoryTitle: 'Vulnerability & Courage',
      cryingReason: 'Relief after a hard conversation',
      reliefLevel: 9,
      reflectionNote:
          'You showed honesty and strength. Notice the lightness in your chest as you let go.',
      color: AppColors.secondary,
    ),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tear &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          timestamp == other.timestamp &&
          memoryTitle == other.memoryTitle &&
          cryingReason == other.cryingReason &&
          reliefLevel == other.reliefLevel &&
          reflectionNote == other.reflectionNote;

  @override
  int get hashCode => Object.hash(
        id,
        timestamp,
        memoryTitle,
        cryingReason,
        reliefLevel,
        reflectionNote,
      );
}

/// Represents the aggregate collection of preserved tears.
class TearCollection {
  const TearCollection({
    this.totalTearsLogged = 0,
    this.averageReliefLevel = 0.0,
    this.tears = const [],
  });

  final int totalTearsLogged;
  final double averageReliefLevel;
  final List<Tear> tears;

  /// Creates a [TearCollection] calculating totals and average relief from a list of tears.
  factory TearCollection.fromTears(List<Tear> tears) {
    final total = tears.length;
    final avg = total == 0
        ? 0.0
        : tears.fold<int>(0, (sum, t) => sum + t.reliefLevel) / total;
    return TearCollection(
      totalTearsLogged: total,
      averageReliefLevel: double.parse(avg.toStringAsFixed(1)),
      tears: List.unmodifiable(tears),
    );
  }

  TearCollection copyWith({
    int? totalTearsLogged,
    double? averageReliefLevel,
    List<Tear>? tears,
  }) {
    return TearCollection(
      totalTearsLogged: totalTearsLogged ?? this.totalTearsLogged,
      averageReliefLevel: averageReliefLevel ?? this.averageReliefLevel,
      tears: tears ?? this.tears,
    );
  }

  /// Serializes to a Map suitable for Firebase Firestore.
  Map<String, dynamic> toMap() {
    return {
      'totalTearsLogged': totalTearsLogged,
      'averageReliefLevel': averageReliefLevel,
      'tears': tears.map((t) => t.toMap()).toList(),
    };
  }

  /// Deserializes from a Map (e.g. from Firebase Firestore).
  factory TearCollection.fromMap(
    Map<String, dynamic> map, {
    List<Tear>? tears,
  }) {
    final parsedTears = tears ??
        (map['tears'] as List<dynamic>?)
            ?.map((e) => Tear.fromMap(e as Map<String, dynamic>))
            .toList() ??
        const <Tear>[];

    final total =
        (map['totalTearsLogged'] as num?)?.toInt() ?? parsedTears.length;
    final avg = (map['averageReliefLevel'] as num?)?.toDouble() ??
        (parsedTears.isEmpty
            ? 0.0
            : parsedTears.fold<int>(0, (sum, t) => sum + t.reliefLevel) /
                parsedTears.length);

    return TearCollection(
      totalTearsLogged: total,
      averageReliefLevel: double.parse(avg.toStringAsFixed(1)),
      tears: List.unmodifiable(parsedTears),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TearCollection &&
          runtimeType == other.runtimeType &&
          totalTearsLogged == other.totalTearsLogged &&
          averageReliefLevel == other.averageReliefLevel &&
          tears.length == other.tears.length;

  @override
  int get hashCode => Object.hash(
        totalTearsLogged,
        averageReliefLevel,
        tears.length,
      );
}
