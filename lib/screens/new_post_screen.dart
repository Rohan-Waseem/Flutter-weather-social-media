import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_post_service.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';


class NewPostScreen extends StatefulWidget {
  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final picker = ImagePicker();
  final captionController = TextEditingController();
  final postService = FirebasePostService();
  final weatherService = WeatherService();

  File? _image;
  String _city = "";
  WeatherModel? _weather;
  bool _loading = false;

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take a photo'),
              onTap: () async {
                Navigator.of(context).pop(); // Close the sheet
                final picked = await picker.pickImage(source: ImageSource.camera);
                if (picked != null) {
                  setState(() => _image = File(picked.path));
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from gallery'),
              onTap: () async {
                Navigator.of(context).pop(); // Close the sheet
                final picked = await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  setState(() => _image = File(picked.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _submitPost() async {
    if (_image == null || _city.isEmpty || captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❗ Please complete all fields")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      _weather = await weatherService.fetchWeather(_city);
      final imageUrl = await postService.uploadImage(_image!);

      await postService.savePost(
        imageUrl: imageUrl,
        caption: captionController.text,
        city: _weather!.cityName,
        weather: _weather!.description,
        temperature: _weather!.temperature,
      );

      setState(() {
        _image = null;
        _city = "";
        captionController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Post uploaded! You can view it in the Feed tab."),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final outlineStyle = OutlinedButton.styleFrom(
      foregroundColor: Color(0xFF62bafe),
      side: BorderSide(color: Color(0xFF62bafe), width: 2),
      padding: EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Create Post", style: GoogleFonts.nunito()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFeaebf6), Color(0xFF62bafe)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.add_a_photo),
                      label: Text("Pick/Capture Image"),
                      style: outlineStyle,
                    ),
                    const SizedBox(height: 16),
                    if (_image != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_image!, height: 200, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: captionController,
                      style: GoogleFonts.nunito(),
                      decoration: InputDecoration(
                        labelText: "Caption",
                        labelStyle: GoogleFonts.nunito(),
                        prefixIcon: Icon(Icons.text_fields),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      style: GoogleFonts.nunito(),
                      decoration: InputDecoration(
                        labelText: "City",
                        labelStyle: GoogleFonts.nunito(),
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (val) => _city = val.trim(),
                    ),
                    const SizedBox(height: 24),
                    _loading
                        ? Center(child: CircularProgressIndicator())
                        : OutlinedButton.icon(
                      onPressed: _submitPost,
                      icon: Icon(Icons.cloud_upload),
                      label: Text("Post"),
                      style: outlineStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
