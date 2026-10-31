import 'package:flutter/material.dart';

import '../../../data/repositories/weather_repository.dart';
import '../../../data/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// One line on the home screen saying what the weather context is: the current
/// weather where the user is, the last known one when the fetch failed, or why
/// there is none — with the settings screen that can fix a refused location.
class WeatherContextLine extends StatelessWidget {
  const WeatherContextLine({super.key, required this.reading, this.onFixLocation});

  /// Null while the first read is still in flight.
  final WeatherReading? reading;

  /// Called when the line points at a settings screen that can fix the
  /// location, like the phone's location switch or the app's permission one.
  final VoidCallback? onFixLocation;

  @override
  Widget build(BuildContext context) {
    final line = _describe(reading);
    if (line == null) return const SizedBox.shrink();

    final actionable = line.actionable && onFixLocation != null;
    final text = Text(
      line.text,
      style: AppText.body.copyWith(
        fontSize: 13,
        color: actionable ? AppColors.primary : AppColors.textMuted,
        fontWeight: actionable ? FontWeight.w600 : FontWeight.w400,
      ),
    );
    if (!actionable) return text;
    return InkWell(onTap: onFixLocation, child: text);
  }

  ({String text, bool actionable})? _describe(WeatherReading? reading) {
    final current = reading;
    if (current == null) return null;
    final weather = current.weather;

    switch (current.outcome) {
      case WeatherOutcome.ready:
        if (weather != null && current.location?.isStale != true) {
          return (
            text:
                'Right now where you are: ${weather.roundedTemperature}°C · '
                '${weather.conditionLabel}',
            actionable: false,
          );
        }
        // A stale location means the weather is where the user was, not where
        // they are, so it is not shown as current.
        return (
          text: 'Your location is a while old — suggestions are general today.',
          actionable: false,
        );
      case WeatherOutcome.offline:
      case WeatherOutcome.unavailable:
        if (weather != null) {
          return (
            text:
                'Last known weather: ${weather.roundedTemperature}°C · '
                '${weather.conditionLabel}',
            actionable: false,
          );
        }
        return (
          text: 'No connection right now — suggestions are general today.',
          actionable: false,
        );
      case WeatherOutcome.noLocation:
        return switch (current.location?.outcome) {
          // A switched-off GPS and a denied permission are fixed in different
          // settings screens, so they are told apart.
          LocationAvailability.serviceDisabled => (
            text: 'Location is off — turn it on for weather-aware suggestions.',
            actionable: true,
          ),
          LocationAvailability.permissionDenied ||
          LocationAvailability.permissionPermanentlyDenied => (
            text: 'Allow location access for weather-aware suggestions.',
            actionable: true,
          ),
          _ => (
            text: 'No location right now — suggestions are general today.',
            actionable: false,
          ),
        };
    }
  }
}
