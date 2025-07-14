import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

  class WeatherService {
  final String apiKey = 'apikey'; // Replace with your real API key

  Future<WeatherModel> fetchWeather(String city) async {
  final url = Uri.parse(
  'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric',
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
  final jsonData = json.decode(response.body);
  return WeatherModel.fromJson(jsonData);
  } else {
  throw Exception("Failed to load weather data");
  }
  }
  }
