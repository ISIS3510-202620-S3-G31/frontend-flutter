import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/recommendation_model.dart';
import '../../../data/models/tool_model.dart';
import '../../../data/models/weather_model.dart';
import '../../../data/repositories/analytics_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/last_recommendation_repository.dart';
import '../../../data/repositories/recommendation_log_repository.dart';
import '../../../data/repositories/stats_repository.dart';
import '../../../data/repositories/tool_repository.dart';
import '../../../data/repositories/weather_repository.dart';
import '../../../data/services/location_service.dart';
import '../../../domain/recommendation/frequency_based_strategy.dart';
import '../../../domain/recommendation/mood_based_strategy.dart';
import '../../../domain/recommendation/recommendation_strategy.dart';
import '../../../domain/recommendation/tool_recommender.dart';
import '../../../domain/recommendation/weather_based_strategy.dart';

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
    WeatherRepository? weather,
    LastRecommendationRepository? lastRecommendations,
    this._openableToolIds,
    DateTime Function()? now,
  }) : _repository = repository ?? const ToolRepository(),
       _statsRepository = statsRepository ?? StatsRepository(),
       _recommender = recommender ?? ToolRecommender(),
       _analytics = analytics ?? AnalyticsRepository(),
       _recommendationLog = recommendationLog ?? RecommendationLogRepository(),
       _auth = auth ?? AuthRepository(),
       // One repository for the whole view model: each instance opens its own
       // HTTP client, so making one per load would pile them up.
       _weather = weather ?? WeatherRepository(),
       _lastRecommendations =
           lastRecommendations ?? LastRecommendationRepository(),
       _now = now ?? DateTime.now;

  final ToolRepository _repository;
  final StatsRepository _statsRepository;
  final ToolRecommender _recommender;
  final AnalyticsRepository _analytics;
  final RecommendationLogRepository _recommendationLog;
  final AuthRepository _auth;
  final WeatherRepository _weather;
  final LastRecommendationRepository _lastRecommendations;
  final Set<String>? _openableToolIds;
  final DateTime Function() _now;

  ToolCategory _selectedCategory = ToolCategory.all;
  HomeTab _selectedTab = HomeTab.home;
  Recommendation? _recommendation;
  Recommendation? _lastRecommendation;
  String? _strategy;
  String? _recommendationLogId;
  bool _recommendationOpened = false;
  Recommendation? _weatherRecommendation;
  String? _weatherStrategy;
  String? _weatherRecommendationLogId;
  bool _weatherRecommendationOpened = false;
  int _loads = 0;
  String? _userName;
  WeatherReading? _weatherReading;
  bool _recommendationLoading = false;
  bool _disposed = false;

  ToolCategory get selectedCategory => _selectedCategory;
  HomeTab get selectedTab => _selectedTab;

  /// The personal recommendation (check-in, habits, default). Null until
  /// [loadRecommendation] finishes.
  Recommendation? get recommendation => _recommendation;

  /// The recommendation saved in the previous session, shown as "Your last
  /// recommendation". Null on the first launch.
  Recommendation? get lastRecommendation => _lastRecommendation;

  /// The weather-based recommendation, shown next to [recommendation]. Null
  /// until [loadRecommendation] finishes, and when the weather has no opinion
  /// or could not be read.
  Recommendation? get weatherRecommendation => _weatherRecommendation;

  WeatherReading? get weatherReading => _weatherReading;

  /// True while [loadRecommendation] is in flight, so the screen can show
  /// that the recommendations — the weather read included — are still loading.
  bool get isRecommendationLoading => _recommendationLoading;

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

  Future<void> loadUserName() async {
    try {
      final name = (await _auth.getCurrentUserProfile())?.name.trim();
      _userName = name == null || name.isEmpty ? null : name;
    } on Exception {
      _userName = null;
    }
    if (_disposed) return;
    notifyListeners();
  }


  Future<void> loadLastRecommendation() async {
    final last = await _lastRecommendations.load(
      tools: _openableTools(),
      userId: _auth.currentUserId,
    );
    if (_disposed) return;
    _lastRecommendation = last;
    notifyListeners();
  }

  Future<void> loadRecommendation() async {
    final load = ++_loads;
    _recommendationLoading = true;
    notifyListeners();
    try {
      final now = _now();
      final data = await _statsRepository.dataSince(
        DateTime(now.year, now.month, now.day - 29),
      );
      if (_disposed || load != _loads) return;

      // The weather feeds its own recommendation; a failure here must not
      // cost the personal one, so it degrades to no weather at all.
      WeatherReading? reading;
      try {
        reading = await _weather.currentWeather();
      } on Exception {
        reading = null;
      }
      if (_disposed || load != _loads) return;
      _weatherReading = reading;

      final lastDay = now.subtract(const Duration(days: 1));
      final history = UserHistory(
        recentCheckIns: [
          for (final checkIn in data.checkIns)
            if (!checkIn.timestamp.isBefore(lastDay)) checkIn,
        ],
        sessions: data.sessions,
        weather: reading == null ? null : _usableWeather(reading),
      );
      final tools = _openableTools();
      // Two recommendations at once: the personal one and the one for the
      // weather, so the screen can show both cards.
      final recommendation = _recommender.recommend(history, tools);
      final strategy = _strategyName(_recommender.strategy);
      final weatherRecommendation = _recommender.weatherRecommendation(
        history,
        tools,
      );
      final weatherStrategy = _strategyName(_recommender.weatherStrategy);

      if (recommendation == null) {
        _recommendation = null;
        _strategy = null;
        _recommendationLogId = null;
      } else if (!_isOnScreen(_recommendation, _strategy, recommendation, strategy)) {
        _recommendation = recommendation;
        _strategy = strategy;
        _recommendationLogId = _recommendationLog.logShown(
          recommendation,
          strategy: strategy,
        );
        _recommendationOpened = false;
        // A new recommendation replaces the saved one for the next launch.
        unawaited(
          _lastRecommendations.save(
            recommendation,
            userId: _auth.currentUserId,
          ),
        );
      }

      if (weatherRecommendation == null) {
        _weatherRecommendation = null;
        _weatherStrategy = null;
        _weatherRecommendationLogId = null;
      } else if (!_isOnScreen(
        _weatherRecommendation,
        _weatherStrategy,
        weatherRecommendation,
        weatherStrategy,
      )) {
        _weatherRecommendation = weatherRecommendation;
        _weatherStrategy = weatherStrategy;
        _weatherRecommendationLogId = _recommendationLog.logShown(
          weatherRecommendation,
          strategy: weatherStrategy,
        );
        _weatherRecommendationOpened = false;
      }
    } finally {
      // A newer load owns the flag once it has started, and a disposed view
      // model has no listeners left to tell.
      if (load == _loads && !_disposed) {
        _recommendationLoading = false;
        notifyListeners();
      }
    }
  }

  void openRecommendation() {
    final id = _recommendationLogId;
    final recommendation = _recommendation;
    if (id == null || recommendation == null || _recommendationOpened) return;
    _recommendationOpened = true;
    _recommendationLog.logOpened(id, toolId: recommendation.tool.id);
  }

  void openWeatherRecommendation() {
    final id = _weatherRecommendationLogId;
    final recommendation = _weatherRecommendation;
    if (id == null || recommendation == null || _weatherRecommendationOpened) {
      return;
    }
    _weatherRecommendationOpened = true;
    _recommendationLog.logOpened(id, toolId: recommendation.tool.id);
  }

  /// The weather to recommend from: the fresh one when the location behind it
  /// is current, the last known one when the fetch failed, nothing otherwise.
  Weather? _usableWeather(WeatherReading reading) {
    final weather = reading.weather;
    if (weather == null) return null;
    switch (reading.outcome) {
      case WeatherOutcome.ready:
        // A stale location means the weather is where the user was, not where
        // they are, so it is not recommended as current.
        if (reading.location?.isStale ?? false) return null;
        return weather;
      case WeatherOutcome.offline:
      case WeatherOutcome.unavailable:
        return weather;
      case WeatherOutcome.noLocation:
        return null;
    }
  }

  /// Opens whatever screen can fix a refused location: the phone's location
  /// switch or the app's permission screen, depending on why it was refused.
  Future<void> fixLocationAccess() async {
    switch (_weatherReading?.location?.outcome) {
      case LocationAvailability.serviceDisabled:
        await _weather.openLocationSettings();
      case LocationAvailability.permissionPermanentlyDenied:
        await _weather.openAppSettings();
      case LocationAvailability.permissionDenied:
        await _weather.ensureLocationAvailable();
      case LocationAvailability.ready:
      case LocationAvailability.noReading:
      case null:
        break;
    }
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

  bool _isOnScreen(
    Recommendation? current,
    String? currentStrategy,
    Recommendation recommendation,
    String strategy,
  ) {
    return current != null &&
        current.tool.id == recommendation.tool.id &&
        current.reason == recommendation.reason &&
        currentStrategy == strategy;
  }

  String _strategyName(RecommendationStrategy strategy) => switch (strategy) {
    WeatherBasedStrategy() => 'Weather based',
    MoodBasedStrategy() => 'Mood based',
    FrequencyBasedStrategy() => 'Frequency based',
    _ => 'Default',
  };

  @override
  void dispose() {
    _disposed = true;
    _weather.dispose();
    super.dispose();
  }
}
