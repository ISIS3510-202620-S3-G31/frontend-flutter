/// The city and country a check-in was made from. Never the coordinates.
class Place {
  const Place({required this.city, required this.country, this.countryCode});

  final String city;
  final String country;

  /// ISO 3166 code, like "CO". Maps place a country by it without guessing
  /// from the name.
  final String? countryCode;

  Map<String, Object?> toMap() => {
    'city': city,
    'country': country,
    'countryCode': ?countryCode,
  };
}
