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
  /// How often the weather is re-read while the Tool Hub is visible.
  ///
  /// The location behind the weather is cached for 30 minutes
  /// ([LocationService.freshness]), so polling faster than that would only
  /// re-read the same place. 45 minutes sits past that cache — each poll gets
  /// a fresh position — and inside the 30-60 minute window: the goal is the
  /// general conditions of the user's area, not precise tracking.
  static const Duration defaultWeatherPollInterval = Duration(minutes: 45);

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
    Duration? weatherPollInterval,
  }) : _repository = repository ?? const ToolRepository(),
       _statsRepository = statsRepository ?? StatsRepository(),
       _recommender = recommender ?? ToolRecommender(),
       _analytics = analytics ?? AnalyticsRepository(),
       _recommendationLog = recommendationLog ?? RecommendationLogRepository(),
       _auth = auth ?? AuthRepository(),
       // One repository for the whole view model, so every read goes through
       // the same in-flight guard in [_readWeather].
       _weather = weather ?? WeatherRepository(),
       _lastRecommendations =
           lastRecommendations ?? LastRecommendationRepository(),
       _weatherPollInterval = weatherPollInterval ?? defaultWeatherPollInterval,
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
  final Duration _weatherPollInterval;
  Timer? _weatherPollTimer;
  Future<WeatherReading>? _weatherReadInFlight;
  bool _pollingRequested = false;
  bool _foreground = true;

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
  Weather? _appliedWeather;
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

  /// The weather-based recommendation, shown in its own section on the home
  /// screen. Null until [loadRecommendation] finishes, and when the weather
  /// has no opinion or could not be read.
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
        reading = await _readWeather();
      } on Exception {
        reading = null;
      }
      if (_disposed || load != _loads) return;
      _weatherReading = reading;
      _appliedWeather = reading == null ? null : _usableWeather(reading);

      final lastDay = now.subtract(const Duration(days: 1));
      final history = UserHistory(
        recentCheckIns: [
          for (final checkIn in data.checkIns)
            if (!checkIn.timestamp.isBefore(lastDay)) checkIn,
        ],
        sessions: data.sessions,
        weather: _appliedWeather,
      );
      final tools = _openableTools();
      // Two recommendations at once: the personal one and the one for the
      // weather, so the screen can show both cards.
      final recommendation = _recommender.recommend(history, tools);
      final strategy = _strategyName(_recommender.strategy);
      _applyWeatherRecommendation(_appliedWeather);

      if (recommendation == null) {
        _recommendation = null;
        _strategy = null;
        _recommendationLogId = null;
      } else if (!_isOnScreen(
        _recommendation,
        _strategy,
        recommendation,
        strategy,
      )) {
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
    } finally {
      // A newer load owns the flag once it has started, and a disposed view
      // model has no listeners left to tell.
      if (load == _loads && !_disposed) {
        _recommendationLoading = false;
        notifyListeners();
      }
    }
  }

  /// Starts the periodic weather read, for while the Tool Hub screen is
  /// visible. Calling it again while it runs changes nothing.
  void startWeatherPolling() {
    _pollingRequested = true;
    _syncWeatherPollTimer();
  }

  /// Stops the periodic weather read, for when the screen goes away.
  void stopWeatherPolling() {
    _pollingRequested = false;
    _syncWeatherPollTimer();
  }

  /// The app left or re-entered the foreground. Polling only runs while the
  /// app is in front; coming back reads at once, because the weather may have
  /// changed while the app was away.
  void onAppLifecycleChanged(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncWeatherPollTimer();
    if (_foreground && _pollingRequested) unawaited(_pollWeather());
  }

  /// The timer runs only while the screen is visible and the app is in the
  /// foreground; [dispose] cancels it too, so it never outlives this view
  /// model.
  void _syncWeatherPollTimer() {
    final shouldRun = _pollingRequested && _foreground && !_disposed;
    if (shouldRun && _weatherPollTimer == null) {
      _weatherPollTimer = Timer.periodic(
        _weatherPollInterval,
        (_) => unawaited(_pollWeather()),
      );
    } else if (!shouldRun && _weatherPollTimer != null) {
      _weatherPollTimer!.cancel();
      _weatherPollTimer = null;
    }
  }

  /// One timer tick: reads the weather and refreshes the recommendation only
  /// when the condition behind it changed.
  Future<void> _pollWeather() async {
    if (_disposed) return;
    try {
      final reading = await _readWeather();
      if (_disposed) return;
      _applyWeatherReading(reading);
    } on Exception {
      // A failed read keeps the last known weather and the recommendation on
      // screen; the next tick tries again.
    }
  }

  /// One weather read at a time: while a read is in flight, whoever asks next
  /// gets the same future instead of starting another, so reads never
  /// overlap. The HTTP call and the JSON parse run in their own isolate
  /// ([WeatherService]), so the UI thread only waits for the finished reading.
  Future<WeatherReading> _readWeather() {
    final inFlight = _weatherReadInFlight;
    if (inFlight != null) return inFlight;
    final read = _weather.currentWeather();
    _weatherReadInFlight = read;
    unawaited(
      read.then(
        (_) => _clearWeatherRead(read),
        onError: (_) => _clearWeatherRead(read),
      ),
    );
    return read;
  }

  void _clearWeatherRead(Future<WeatherReading> read) {
    if (identical(_weatherReadInFlight, read)) _weatherReadInFlight = null;
  }

  /// Applies a polled reading: the recommendation is rebuilt and the
  /// listeners told only when the condition it keys on changed, so the card
  /// does not flicker on every tick.
  void _applyWeatherReading(WeatherReading reading) {
    final weather = _usableWeather(reading);
    _weatherReading = reading;
    if (_conditionKey(_appliedWeather) == _conditionKey(weather)) return;
    _appliedWeather = weather;
    _applyWeatherRecommendation(weather);
    notifyListeners();
  }

  /// Rebuilds the weather-based recommendation from [weather] and swaps it in
  /// when it differs from the one on screen, logging the new one.
  void _applyWeatherRecommendation(Weather? weather) {
    // The weather strategy reads only the weather out of the history.
    final history = UserHistory(
      recentCheckIns: const [],
      sessions: const [],
      weather: weather,
    );
    final recommendation = _recommender.weatherRecommendation(
      history,
      _openableTools(),
    );
    final strategy = _strategyName(_recommender.weatherStrategy);
    if (recommendation == null) {
      _weatherRecommendation = null;
      _weatherStrategy = null;
      _weatherRecommendationLogId = null;
    } else if (!_isOnScreen(
      _weatherRecommendation,
      _weatherStrategy,
      recommendation,
      strategy,
    )) {
      _weatherRecommendation = recommendation;
      _weatherStrategy = strategy;
      _weatherRecommendationLogId = _recommendationLog.logShown(
        recommendation,
        strategy: strategy,
      );
      _weatherRecommendationOpened = false;
    }
  }

  /// What the weather recommendation keys on — rain, cold, clear sun, or
  /// nothing — in the order [WeatherBasedStrategy] checks them. The exact
  /// temperature is not part of it, so a tick that only moves the thermometer
  /// does not rebuild the card.
  String? _conditionKey(Weather? weather) {
    if (weather == null) return null;
    if (weather.isRainy) return 'rainy';
    if (weather.isCold) return 'cold';
    if (weather.isClearAndSunny) return 'sunny';
    return 'mild';
  }

  /// The user tapped the recommended card on the home screen: the interaction
  /// event of the recommendation-engagement business question, logged next to
  /// the opened event so taps can be told apart from impressions.
  void openRecommendation() {
    final id = _recommendationLogId;
    final recommendation = _recommendation;
    if (id == null || recommendation == null || _recommendationOpened) return;
    _recommendationOpened = true;
    _recommendationLog.logTapped(id, toolId: recommendation.tool.id);
    _recommendationLog.logOpened(id, toolId: recommendation.tool.id);
  }

  /// Same as [openRecommendation], for the weather-based card.
  void openWeatherRecommendation() {
    final id = _weatherRecommendationLogId;
    final recommendation = _weatherRecommendation;
    if (id == null || recommendation == null || _weatherRecommendationOpened) {
      return;
    }
    _weatherRecommendationOpened = true;
    _recommendationLog.logTapped(id, toolId: recommendation.tool.id);
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
    // The poll timer must not keep running once the view model is gone.
    _weatherPollTimer?.cancel();
    _weatherPollTimer = null;
    _weather.dispose();
    super.dispose();
  }
}
