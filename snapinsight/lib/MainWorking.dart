import 'package:flutter/material.dart';
import 'package:snapinsight/Summarypage.dart';
import 'package:snapinsight/loading_screen.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class ButtonPressData {
  final String label;
  final String date;
  final String time;

  ButtonPressData({
    required this.label,
    String? date,
    String? time,
  })  : date = date ?? 'N/A',
        time = time ?? 'N/A';

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'date': date,
      'time': time,
    };
  }
}

class ChartData {
  final String label;
  final double value;
  final Color color; // Add a Color property for each category

  ChartData(this.label, this.value, this.color);
}

class ButtonPage extends StatefulWidget {
  @override
  _ButtonPageState createState() => _ButtonPageState();
}

class _ButtonPageState extends State<ButtonPage> {
  List<ButtonPressData> buttonPresses = [];
  ScrollController _scrollController = ScrollController();
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    loadButtonPressesFromLocalStorage();
    fetchButtonPressData();
    _startAutoRefresh();
  }

  Future<void> loadButtonPressesFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString('buttonPresses');
    if (jsonData != null) {
      final List<dynamic> parsedData = jsonDecode(jsonData);
      final loadedData = parsedData
          .map((data) => ButtonPressData(
              label: data['label'], date: data['date'], time: data['time']))
          .toList();
      setState(() {
        buttonPresses = loadedData;
      });
    }
  }

  @override
  void dispose() {
    _stopAutoRefresh(); // Cancel the auto-refresh timer
    super.dispose();
  }

  Future<void> fetchButtonPressData() async {
    final url =
        'https://buttonflutterfirebase-default-rtdb.firebaseio.com/buttonPresses.json';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<ButtonPressData> loadedData = [];

      data.forEach((key, value) {
        if (value != null && value is Map<String, dynamic>) {
          final buttonPress = ButtonPressData(
            label: value['label'] ?? 'N/A',
            date: value['date'] ?? 'N/A',
            time: value['time'] ?? 'N/A',
          );
          loadedData.add(buttonPress);
        }
      });

      setState(() {
        buttonPresses = loadedData;
      });

      // Save the data to local storage
      saveButtonPressesToLocalStorage(buttonPresses);
    } else {
      print(
          'Failed to fetch button press data. Status code: ${response.statusCode}');
    }
  }

  Future<void> saveButtonPressesToLocalStorage(
      List<ButtonPressData> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = data.map((buttonPress) => buttonPress.toJson()).toList();
    prefs.setString('buttonPresses', jsonEncode(jsonData));
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 100),
      curve: Curves.bounceIn,
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: Duration(milliseconds: 100),
      curve: Curves.bounceIn,
    );
  }

  void _navigateToSummaryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ButtonSummaryPage(buttonPresses: buttonPresses),
      ),
    );
  }

  Future<void> _autoRefreshData() async {
    while (true) {
      await Future.delayed(
          Duration(milliseconds: 100)); // 10 milliseconds interval
      await fetchButtonPressData();
    }
  }

  void _startAutoRefresh() {
    // Start auto-refresh
    _refreshTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
      fetchButtonPressData();
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (buttonPresses.isEmpty) {
      // Display the loading screen if the data is empty
      return LoadingScreen(); // Display the loading screen
    } else {
      // If data is available, display the normal content
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xffC69554),
          title: Center(
            child: Text(
              'Project Title: Real Time Feedback',
              style: TextStyle(
                fontSize: screenWidth < 600 ? 16 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        body: Container(
          color: Color.fromARGB(255, 250, 224, 200),
          padding: EdgeInsets.all(screenWidth < 600 ? 4.0 : 8.0),
          margin: EdgeInsets.all(0),
          child: Column(
            children: [
              Text(
                'Feedbacks',
                style: TextStyle(
                  fontSize: screenWidth < 600 ? 16 : 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: Scrollbar(
                  child: ListView(
                    controller: _scrollController, // Set the controller here
                    children: buttonPresses
                        .map((buttonPress) => ListTile(
                              title: Text(buttonPress.label),
                              subtitle: Text(
                                  '${buttonPress.date} ${buttonPress.time}'),
                            ))
                        .toList(),
                  ),
                ),
              ),
              Row(
                children: [
                  // SizedBox(
                  //   height: 10,
                  //   width: 10,
                  // ),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Color(0xffC69554),
                        ),
                      ),
                      onPressed: _scrollToBottom,
                      child: Center(
                        child: Icon(
                          Icons.move_down,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Color(0xffC69554),
                          ),
                        ),
                        onPressed: _navigateToSummaryPage,
                        child: Center(
                          child: Icon(
                            Icons.dashboard_customize,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Color(0xffC69554),
                        ),
                      ),
                      onPressed: _scrollToTop,
                      child: Center(
                        child: Icon(
                          Icons.move_up,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }
}


  List<ChartData> generateChartData(Map<String, double> buttonCountMap) {
    List<ChartData> chartData = [];
    final List<Color> paletteColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.black,
      // Add more colors as needed
    ];

    buttonCountMap.forEach((label, count) {
      final colorIndex =
          buttonCountMap.keys.toList().indexOf(label) % paletteColors.length;
      chartData
          .add(ChartData(label, count.toDouble(), paletteColors[colorIndex]));
    });

    return chartData;
  }

