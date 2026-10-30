import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/recommendation_model.dart';
import '../../../data/models/tool_model.dart';
import '../../../data/repositories/analytics_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/recommendation_log_repository.dart';
import '../../../data/repositories/stats_repository.dart';
import '../../../data/repositories/tool_repository.dart';
import '../../../domain/recommendation/frequency_based_strategy.dart';
import '../../../domain/recommendation/mood_based_strategy.dart';
import '../../../domain/recommendation/recommendation_strategy.dart';
import '../../../domain/recommendation/tool_recommender.dart';

/// The tabs of the bottom bar, from left to right.
enum HomeTab {
  stats('Stats'),
  home('Home'),
  tools('ToolHub'),
  profile('Profile');

  const HomeTab(this.screenName);

  /// Screen name logged to analytics when the tab is shown.
  final String screenName;
}

class ToolHubViewModel extends ChangeNotifier {
  ToolHubViewModel({
    ToolRepository? repository,
    StatsRepository? statsRepository,
    ToolRecommender? recommender,
    AnalyticsRepository? analytics,
    RecommendationLogRepository? recommendationLog,
    AuthRepository? auth,
    this._openableToolIds,
    DateTime Function()? now,
  }) : _repository = repository ?? const ToolRepository(),
       _statsRepository = statsRepository ?? StatsRepository(),
       _recommender = recommender ?? ToolRecommender(),
       _analytics = analytics ?? AnalyticsRepository(),
       _recommendationLog = recommendationLog ?? RecommendationLogRepository(),
       _auth = auth ?? AuthRepository(),
       _now = now ?? DateTime.now;

  final ToolRepository _repository;
  final StatsRepository _statsRepository;
  final ToolRecommender _recommender;
  final AnalyticsRepository _analytics;
  final RecommendationLogRepository _recommendationLog;
  final AuthRepository _auth;
  final Set<String>? _openableToolIds;
  final DateTime Function() _now;

  ToolCategory _selectedCategory = ToolCategory.all;
  HomeTab _selectedTab = HomeTab.home;
  Recommendation? _recommendation;
  String? _strategy;
  String? _recommendationLogId;
  bool _recommendationOpened = false;
  int _loads = 0;
  String? _userName;
  bool _disposed = false;

  ToolCategory get selectedCategory => _selectedCategory;
  HomeTab get selectedTab => _selectedTab;

  /// Null until [loadRecommendation] finishes.
  Recommendation? get recommendation => _recommendation;

  /// Null until [loadUserName] finishes, and when the profile cannot be read.
  String? get userName => _userName;

  List<ToolItem> get tools => _repository.toolsIn(_selectedCategory);

  String get listTitle => _selectedCategory == ToolCategory.all
      ? 'All tools'
      : '${_selectedCategory.label} tools';

  void selectCategory(ToolCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Tabs are not routes, so the navigator observer never sees them; the screen
  /// view of the tab shown first is logged here, the rest in [selectTab].
  void logScreenView() {
    _analytics.logScreenView(screenName: _selectedTab.screenName);
  }

  /// Tabs are not routes, so the navigator observer never sees them; the
  /// screen view is logged here instead.
  void selectTab(HomeTab tab) {
    if (tab == _selectedTab) return;
    _selectedTab = tab;
    notifyListeners();
    _analytics.logScreenView(screenName: tab.screenName);
    if (tab == HomeTab.home) unawaited(loadRecommendation());
  }

  ToolItem randomTool() => _repository.randomTool();

  /// The greeting is the only thing the name is used for, so a failed read
  /// just leaves it out instead of blocking the screen.
  Future<void> loadUserName() async {
    try {
      _userName = (await _auth.getCurrentUserProfile())?.name;
    } on Exception {
      _userName = null;
    }
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> loadRecommendation() async {
    final load = ++_loads;
    final now = _now();
    final data = await _statsRepository.dataSince(
      DateTime(now.year, now.month, now.day - 29),
    );
    if (_disposed || load != _loads) return;

    final lastDay = now.subtract(const Duration(days: 1));
    final history = UserHistory(
      recentCheckIns: [
        for (final checkIn in data.checkIns)
          if (!checkIn.timestamp.isBefore(lastDay)) checkIn,
      ],
      sessions: data.sessions,
    );
    final recommendation = _recommender.recommend(history, _openableTools());
    final strategy = _strategyName();

    if (recommendation == null) {
      _recommendation = null;
      _strategy = null;
      _recommendationLogId = null;
    } else if (!_isOnScreen(recommendation, strategy)) {
      _recommendation = recommendation;
      _strategy = strategy;
      _recommendationLogId = _recommendationLog.logShown(
        recommendation,
        strategy: strategy,
      );
      _recommendationOpened = false;
    }
    notifyListeners();
  }

  void openRecommendation() {
    final id = _recommendationLogId;
    final recommendation = _recommendation;
    if (id == null || recommendation == null || _recommendationOpened) return;
    _recommendationOpened = true;
    _recommendationLog.logOpened(id, toolId: recommendation.tool.id);
  }

  List<ToolItem> _openableTools() {
    final openable = _openableToolIds;
    final tools = _repository.allTools();
    if (openable == null) return tools;
    return [
      for (final tool in tools)
        if (openable.contains(tool.id)) tool,
    ];
  }

  bool _isOnScreen(Recommendation recommendation, String strategy) {
    final current = _recommendation;
    return current != null &&
        current.tool.id == recommendation.tool.id &&
        current.reason == recommendation.reason &&
        _strategy == strategy;
  }

  String _strategyName() => switch (_recommender.strategy) {
    MoodBasedStrategy() => 'Mood based',
    FrequencyBasedStrategy() => 'Frequency based',
    _ => 'Default',
  };

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
