import 'package:flutter/material.dart';

import '../../../data/models/recommendation_model.dart';
import '../../../data/models/tool_model.dart';
import '../../../data/repositories/stats_repository.dart';
import '../../../data/repositories/tool_repository.dart';
import '../../../data/services/analytics_service.dart';
import '../../../domain/recommendation/recommendation_strategy.dart';
import '../../../domain/recommendation/tool_recommender.dart';

/// The tabs of the bottom bar, from left to right.
enum HomeTab {
  stats('Stats'),
  home('ToolHub'),
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
    AnalyticsService? analytics,
    DateTime Function()? now,
  }) : _repository = repository ?? const ToolRepository(),
       _statsRepository = statsRepository ?? StatsRepository(),
       _recommender = recommender ?? ToolRecommender(),
       _analytics = analytics ?? AnalyticsService(),
       _now = now ?? DateTime.now;

  final ToolRepository _repository;
  final StatsRepository _statsRepository;
  final ToolRecommender _recommender;
  final AnalyticsService _analytics;
  final DateTime Function() _now;

  ToolCategory _selectedCategory = ToolCategory.all;
  HomeTab _selectedTab = HomeTab.home;
  Recommendation? _recommendation;
  bool _disposed = false;

  ToolCategory get selectedCategory => _selectedCategory;
  HomeTab get selectedTab => _selectedTab;

  /// Null until [loadRecommendation] finishes.
  Recommendation? get recommendation => _recommendation;

  List<ToolItem> get tools => _repository.toolsIn(_selectedCategory);

  String get listTitle => _selectedCategory == ToolCategory.all
      ? 'All tools'
      : '${_selectedCategory.label} tools';

  void selectCategory(ToolCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Tabs are not routes, so the navigator observer never sees them; the
  /// screen view is logged here instead.
  void selectTab(HomeTab tab) {
    if (tab == _selectedTab) return;
    _selectedTab = tab;
    notifyListeners();
    _analytics.logScreenView(screenName: tab.screenName);
  }

  ToolItem randomTool() => _repository.randomTool();

  Future<void> loadRecommendation() async {
    final now = _now();
    final data = await _statsRepository.dataSince(
      DateTime(now.year, now.month, now.day - 29),
    );
    final lastDay = now.subtract(const Duration(days: 1));
    final history = UserHistory(
      recentCheckIns: [
        for (final checkIn in data.checkIns)
          if (!checkIn.timestamp.isBefore(lastDay)) checkIn,
      ],
      sessions: data.sessions,
    );
    _recommendation = _recommender.recommend(history, _repository.allTools());
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
