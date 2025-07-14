import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
class WeatherScreen extends StatefulWidget {
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _controller = TextEditingController();
  final _service = WeatherService();
  WeatherModel? _weather;
  bool _loading = false;

  void _getWeather() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _loading = true);
    try {
      final result = await _service.fetchWeather(_controller.text.trim());
      setState(() => _weather = result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to get weather.")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email ?? "User";

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFeaebf6), // soft lavender
              Color(0xFF62bafe), ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: [
                // Greeting & Date
                Text(
                  "${_greeting()}, $userName 👋",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat.yMMMMd().format(DateTime.now()),
                  style: TextStyle(color: Colors.grey[800], fontSize: 16),
                ),
                const SizedBox(height: 24),

                // City input
                TextField(
                  controller: _controller,
                  style: GoogleFonts.nunito(),
                  decoration: InputDecoration(
                    labelText: "Enter Your City",
                    labelStyle: GoogleFonts.nunito(),
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    // focusedBorder: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(12),
                    //   borderSide: BorderSide( width: 2),
                    // ),
                    filled: false, // No fill for outline-only look
                  ),
                ),

                const SizedBox(height: 16),

                // Get Weather Button
                OutlinedButton.icon(
                  onPressed: _loading ? null : _getWeather,
                  icon: Icon(Icons.cloud_outlined, color: Color(0xFF62BAFE)),
                  label: Text(
                    "Get Weather",
                    style: TextStyle(color: Color(0xFF62BAFE)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF62BAFE), width: 2),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                // Weather Card
                if (_loading)
                  Center(child: CircularProgressIndicator())
                else if (_weather != null)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(_weather!.cityName,
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("${_weather!.temperature.toStringAsFixed(1)} °C",
                              style: TextStyle(fontSize: 20, color: Colors.blue[700])),
                          const SizedBox(height: 8),
                          Text(_weather!.description,
                              style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                          const SizedBox(height: 16),
                          Image.network(
                            "http://openweathermap.org/img/wn/${_weather!.icon}@2x.png",
                            height: 80,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      Image.asset("assets/images/cloud.png", height: 180),
                      SizedBox(height: 20),
                      Text(
                        "Search for your city to see the weather 🌦️",
                        style: TextStyle(fontSize: 18, color: Colors.grey[800]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
