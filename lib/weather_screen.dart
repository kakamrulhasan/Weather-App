import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class weatherScreen extends StatefulWidget {
  const weatherScreen({super.key});

  @override
  State<weatherScreen> createState() => _weatherScreenState();
}

class _weatherScreenState extends State<weatherScreen> {
  Future<void> geolocation(String city) async {
    final url = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search?name=$city&count=1&language=en&format=json',
    );
    final res = await http.get(url);
    print('resss: ${res.body}');
    if (res.statusCode!=200)throw Exception('Geocoding failed ${res.statusCode}');
      
    
  }

  @override
  void initState() {
    geolocation('comilla');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
