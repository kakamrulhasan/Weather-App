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
      // ------- Daily (7–10 days forecast) -------
      final daily = (deData['daily'] as Map<String, dynamic>);
      final dDates = List<String>.from(daily['time']);
      final dMax = List<num>.from(daily['temperature_2m_max']);
      final dMin = List<num>.from(daily['temperature_2m_min']);

      final outDaily = <_Daily>[];

      for (int i = 0; i < dDates.length; i++) {
        outDaily.add(
          _Daily(
            DateTime.parse(dDates[i]),
            dMin[i].toDouble(),
            dMax[i].toDouble(),
          ),
        );
      }

      _dailies = outDaily;

      // today's high-low (used under big temp)
      _hi = outDaily.first.tMax;
      _lo = outDaily.first.tMin;

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
        _dailies = outDaily;
        _hi = outDaily.first.tMax;
        _lo = outDaily.first.tMin;
      });
    } catch (e) {
      throw Exception(e.toString());
    } finally {
      setState(() {
        _loading = false;
      });
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _fetch(_searchCtr.text),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue, Colors.blueAccent, Colors.white70],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: Colors.white),
                        controller: _searchCtr,
                        onSubmitted: (v) => _fetch(v),
                        decoration: InputDecoration(
                          labelText: 'Enter city(e.g.. Comilla)',
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _loading
                          ? null
                          : () => _fetch(_searchCtr.text),
                      child: Text('Go'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_loading) const LinearProgressIndicator(),
                if (_error != null)
                  Text(_error!, style: TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                Column(
                  children: [
                    Text(
                      'MY LOCATION',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _resolvedCity ?? 'Bangladesh',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_tempC != null) ...[
                  Center(
                    child: Text(
                      '${_tempC!.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 96,
                      ),
                    ),
                  ),
                ],
                if (_windKph != null)
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Sunny condition likely through today, wind up to ${_windKph} km/h',
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (_hourlies.isNotEmpty)
                  Card(
                    color: Colors.white,
                    child: SizedBox(
                      height: 112,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _hourlies.length,
                        itemBuilder: (context, i) => const SizedBox(width: 12),
                        separatorBuilder: (context, i) {
                          final h = _hourlies[i];
                          final label = i == 0 ? 'now' : h.t.hour.toString();
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(label),
                              Icon(codeToIcons(h.code)),
                              Text('${h.temp.toStringAsFixed(0)}°C'),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                if (_dailies.isNotEmpty)
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "10-Day Forecast",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),

                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: 7, // show 7 like screenshot
                            itemBuilder: (context, i) {
                              final d = _dailies[i];
                              final dayName = (i == 0)
                                  ? "Today"
                                  : [
                                      "Mon",
                                      "Tue",
                                      "Wed",
                                      "Thu",
                                      "Fri",
                                      "Sat",
                                      "Sun",
                                    ][d.date.weekday - 1];

                              // bar line width calculation
                              final barMin = _dailies
                                  .map((e) => e.tMin)
                                  .reduce((a, b) => a < b ? a : b);
                              final barMax = _dailies
                                  .map((e) => e.tMax)
                                  .reduce((a, b) => a > b ? a : b);

                              final barWidth =
                                  ((d.tMax - barMin) / (barMax - barMin)) * 120;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    // DAY NAME
                                    SizedBox(width: 60, child: Text(dayName)),

                                    // ICON
                                    Icon(
                                      codeToIcons(_hourlies.first.code),
                                      size: 22,
                                    ),

                                    const SizedBox(width: 12),

                                    // BAR
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Container(
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade300,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          Container(
                                            height: 6,
                                            width: barWidth,
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // TEMPS
                                    Text("${d.tMin.toInt()}°"),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${d.tMax.toInt()}°",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
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
