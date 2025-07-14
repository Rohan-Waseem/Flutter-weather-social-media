class WeatherModel {
  final String cityName;
  final double temperature;
  final String description;
  final String icon;

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.icon,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'] ?? '',
      temperature: json['main']['temp']?.toDouble() ?? 0.0,
      description: json['weather'][0]['description'] ?? '',
      icon: json['weather'][0]['icon'] ?? '',
    );
  }
}
