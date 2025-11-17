import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class weatherScreen extends StatefulWidget {
  const weatherScreen({super.key});

  @override
  State<weatherScreen> createState() => _weatherScreenState();
}

class _weatherScreenState extends State<weatherScreen> {
  final _searchCtr = TextEditingController(text: 'comilla');
  bool _loading = false;
  String? _error;
  String? _resolvedCity;

  double? _tempC;
  double? _windKph;
  int? _wCode;
  String? _wText;
  double? _hi, _lo;
  List<_Hourly> _hourlies = [];
  List<_Daily> _dailies = [];
  Future<({String? city, double? lat, double? lon})> geolocation(
    String city,
  ) async {
    try {
      final url = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=$city&count=1&format=json',
      );
      final res = await http.get(url);
      print('resss: ${res.body}');
      if (res.statusCode != 200) {
        throw Exception('Geocoding failed ${res.statusCode}');
      }
      final deData = jsonDecode(res.body) as Map<String, dynamic>;
      final result = (deData['results'] as List?) ?? [];
      if (result.isEmpty) throw Exception('city not found');
      final m = result.first as Map<String, dynamic>;
      final lat = (m['latitude'] as num).toDouble();
      final lon = (m['longitude'] as num).toDouble();
      final name = "${m['name']},${m['country']}";

      print('lat:$lat,lan:$lon,name:$name');
      return (city: name, lat: lat, lon: lon);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> _fetch(String city) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final getGeoData = await geolocation(city);
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${getGeoData.lat}'
        '&longitude=${getGeoData.lon}'
        '&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset'
        '&hourly=temperature_2m,weather_code,wind_speed_10m'
        '&current=temperature_2m,wind_speed_10m,weather_code'
        '&timezone=auto',
      );

      final res = await http.get(url);
      print('get weather data: ${res.body}');
      if (res.statusCode != 200)
        throw Exception('Weather faild ${res.statusCode}');
      final deData = jsonDecode(res.body) as Map<String, dynamic>;
      final current = deData['current'] as Map<String, dynamic>;
      final temC = (current['temperature_2m'] as num).toDouble();
      final windKph = (current['wind_speed_10m'] as num).toDouble();
      final wCode = (current['weather_code'] as num).toInt();
      final wText = (current['weather_code'].toString());

      final hourly = (deData['hourly'] as Map<String, dynamic>);
      final hTimes = List<String>.from(hourly['time'] as List);
      final hTemps = List<num>.from(hourly['temperature_2m'] as List);
      final hCodes = List<num>.from(hourly['weather_code'] as List);

      final outHourly = <_Hourly>[];

      for (var i = 0; i < hTimes.length; i++) {
        outHourly.add(
          _Hourly(
            DateTime.parse(hTimes[i]),
            (hTemps[i]).toDouble(),
            (hCodes[i]).toInt(),
          ),
        );
      }
      setState(() {
        _resolvedCity = getGeoData.city;
        _tempC = temC;
        _wCode = wCode;
        _wText = codeToText(wCode);
        _windKph = windKph;
        _hourlies = outHourly;
        
      });
    } catch (e) {
      throw Exception(e.toString());
    } finally {
      setState(() {});
    }
  }

  String codeToText(int? c) {
    if (c == null) {
      return "--";
    }
    if (c == 0) {
      return "clean sky";
    }
    if ([1, 2, 3].contains(c)) {
      return "Mainly Clear";
    }
    if ([45, 48].contains(c)) {
      return 'fog';
    }
    if ([51, 53, 55, 56, 57].contains(c)) {
      return 'Drizzle';
    }
    if ([61, 63, 65, 66, 67].contains(c)) {
      return 'Rain';
    }
    if ([71, 73, 75, 77].contains(c)) {
      return 'snow';
    }
    if ([80, 81, 82].contains(c)) {
      return 'rain showers';
    }
    if ([85, 86].contains(c)) {
      return 'snow showers';
    }

    if (c == 95) {
      return 'thunderston';
    }
    if (c == 96) {
      return 'hail';
    }
    return 'cloudy';
  }

  IconData codeToIcons(int? c) {
    if (c == 0) {
      return Icons.sunny;
    }
    if ([1, 2, 3].contains(c)) {
      return Icons.cloud_outlined;
    }
    if ([45, 48].contains(c)) {
      return Icons.foggy;
    }
    if ([51, 53, 55, 56, 57].contains(c)) {
      return Icons.grading_sharp;
    }
    if ([61, 63, 65, 66, 67].contains(c)) {
      return Icons.water_drop;
    }
    if ([71, 73, 75, 77].contains(c)) {
      return Icons.ac_unit;
    }
    if ([80, 81, 82].contains(c)) {
      return Icons.deblur_rounded;
    }
    if ([85, 86].contains(c)) {
      return Icons.snowing;
    }

    if (c == 95) {
      return Icons.thunderstorm;
    }
    if (c == 96) {
      return Icons.thunderstorm;
    }
    return Icons.cloud;
  }

  @override
  void initState() {
    super.initState();
    _fetch('Comilla');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('weather app')));
  }
}

class _Hourly {
  final DateTime t;
  final double temp;
  final int code;
  _Hourly(this.t, this.temp, this.code);
}

class _Daily {
  final DateTime date;
  final double tMin, tMax;
  _Daily(this.date, this.tMin, this.tMax);
}
