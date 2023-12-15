import 'package:flutter/material.dart';
import 'package:snapinsight/loading_screen.dart';
import 'package:snapinsight/MainWorking.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapinsight/main.dart';

class ButtonSummaryPage extends StatefulWidget {
  final List<ButtonPressData> buttonPresses;

  const ButtonSummaryPage({Key? key, required this.buttonPresses})
      : super(key: key);

  @override
  _ButtonSummaryPageState createState() => _ButtonSummaryPageState();
}

class _ButtonSummaryPageState extends State<ButtonSummaryPage> {
  TimeOfDay time = TimeOfDay.now();
  Timer? timer;

  Map<String, double> buttonCountMap = {};

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      setState(() {
        time = TimeOfDay.now();
      });
    });
    calculateButtonPresses();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void calculateButtonPresses() {
    widget.buttonPresses.forEach((buttonPress) {
      if (buttonCountMap.containsKey(buttonPress.label)) {
        buttonCountMap[buttonPress.label] =
            buttonCountMap[buttonPress.label]! + 1;
      } else {
        buttonCountMap[buttonPress.label] = 1;
      }
    });
  }

  int calculateTotalButtonPresses() {
    return widget.buttonPresses.length;
  }

  String getMessageForFeedback(
      Map<String, double> buttonCountMap, int totalButtonPresses) {
    final badPercentage =
        (buttonCountMap['Bad'] ?? 0) / totalButtonPresses * 100;
    final satisfactoryPercentage =
        (buttonCountMap['Satisfactory'] ?? 0) / totalButtonPresses * 100;

    if (badPercentage > 20) {
      return "Warning: Need an urgent visit";
    } else if (satisfactoryPercentage > 50) {
      return "Need Update: Satisfactory is greater than 30%";
    } else {
      return "No issues detected.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalButtonPresses = calculateTotalButtonPresses();
    final screenWidth = MediaQuery.of(context).size.width;

    if (widget.buttonPresses.isEmpty) {
      // Display the loading screen if the data is empty
      return LoadingScreen();
    } else {
      final feedbackMessage =
          getMessageForFeedback(buttonCountMap, totalButtonPresses);

      // If data is available, display the normal content
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xffC69554),
          title: Center(
            child: Text(
              'Real Time Feedback',
              style: TextStyle(
                fontSize: screenWidth < 600 ? 18 : 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        body: Container(
          color: Color.fromARGB(255, 250, 224, 200),
          child: ListView(
            padding: EdgeInsets.all(screenWidth < 600 ? 4.0 : 8.0),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Users Feedback Summary',
                      style: TextStyle(
                        fontSize: screenWidth < 600 ? 16 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Number of Total Feedbacks Received: $totalButtonPresses',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    feedbackMessage, // Display the feedback message
                    style: TextStyle(
                      fontSize: 16,
                      color: feedbackMessage.contains("Warning")
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15.0, 0.0, 0.0, 0.0),
                        child: Text(
                          'Feedback',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        'No. Of Feedback',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0.0, 0.0, 15.0, 0.0),
                        child: Text(
                          'Percentage',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: buttonCountMap.length,
                    itemBuilder: (context, index) {
                      final label = buttonCountMap.keys.elementAt(index);
                      final count = buttonCountMap[label];
                      final percentage = (count! / totalButtonPresses * 100)
                          .toStringAsFixed(2);

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(15.0, 0.0, 0.0, 0.0),
                              child: Text(label),
                            ),
                          ),
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                            child: Text(count.toString()),
                          )),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(0.0, 0.0, 15.0, 0.0),
                            child: Text('$percentage%'),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Feedback Distribution',
                      style: TextStyle(
                        fontSize: screenWidth < 600 ? 16 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Bar Chart
                  SfCartesianChart(
                    plotAreaBackgroundColor: Color(0xffC69554),
                    backgroundColor: Color.fromARGB(255, 250, 224, 200),
                    primaryXAxis: CategoryAxis(),
                    primaryYAxis: NumericAxis(
                      interval: 20,
                      minimum: 0,
                      maximum: 100,
                      labelFormat: '{value}%',
                    ),
                    series: <ChartSeries<ChartData, String>>[
                      ColumnSeries<ChartData, String>(
                        dataSource: generateChartData(buttonCountMap),
                        xValueMapper: (ChartData data, _) => data.label,
                        yValueMapper: (ChartData data, _) {
                          final clampedValue =
                              (data.value / totalButtonPresses * 100)
                                  .clamp(0, 100);
                          return clampedValue.toInt();
                        },
                        dataLabelSettings: DataLabelSettings(isVisible: true),
                        pointColorMapper: (ChartData data, _) => data.color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(15.0, 0.0, 7.0, 0.0),
                    child: Text(
                      'Real-time feedback project designed in collaboration with Muslim Hands, empowering voices and fostering impactful change. Together, we strive to build a brighter future, and valuable insight at a time.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'Supervisor:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(0, 8, 55, 8),
                            child:
                                Text('Dr. Engr. Ahmad Khan Naqshbandi Shazli'),
                          ),
                          Text(
                            'Developers:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(0, 8, 20, 8),
                            child: Text(
                                '1. Muhammad Haroon Rafique (Team-Leader)\n2. Husnain Khalid\n3. Iqra Tariq\n4. Bakhtawar Shabbir'),
                          ),
                        ],
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
