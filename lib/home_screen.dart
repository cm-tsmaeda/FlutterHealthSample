import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _methodChannel = MethodChannel('com.example.health_sample');
  Health? _health;
  DateTime? _walkingStartDate;
  String _currentSteps1 = '';
  String _currentSteps2 = '';
  String _currentSteps3 = '';

  final List<HealthDataType> _healthDataTypes = [
    HealthDataType.STEPS,
    // 基礎代謝 <- 今回は不要
    //HealthDataType.BASAL_ENERGY_BURNED,
    // 活動エネルギー消費
    HealthDataType.ACTIVE_ENERGY_BURNED,
    // 総カロリー消費
    //HealthDataType.TOTAL_CALORIES_BURNED,
  ];

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _healthDataTypes.add(HealthDataType.DISTANCE_WALKING_RUNNING);
    } else if (Platform.isAndroid) {
      _healthDataTypes.add(HealthDataType.DISTANCE_DELTA);
      _healthDataTypes.add(HealthDataType.TOTAL_CALORIES_BURNED);
      // 総カロリー消費(Android Health Connect)
      //_healthDataTypes.add(HealthDataType.TOTAL_CALORIES_BURNED);
    }
  }

  void _onButtonTapped() async {
    print('_onButtonTapped');
    try {
      await _methodChannel.invokeMethod('openPrivacyPolicy');
    } on PlatformException catch (error) {
      print('Error occurred: $error');
    }
  }

  void _onHealthInitButtonTapped() async {
    // Global Health instance
    _health = Health();

    if (_health == null) {
      print('Health is null');
      return;
    }
    final health = _health!;
    // configure the health plugin before use.
    await health.configure();

    // requesting access to the data types before reading them
    bool result = await health.requestAuthorization(_healthDataTypes);
    print('health.requestAuthorization $result');

    if (Platform.isAndroid) {
      result = await health.requestHealthDataHistoryAuthorization();
      print('health.requestHealthDataHistoryAuthorization $result');
      PermissionStatus status = await Permission.activityRecognition.request();
      print('Permission.activityRecognition $status');
      status = await Permission.location.request();
      print('Permission.location $status');
    }
  }

  void _onReadButtonTapped() async {
    if (_health == null) {
      print('Health is null');
      return;
    }

    final startDateStr = '2025-08-24T00:00:00+09:00'; // JSTにする必要がある
    //final startDateStr = '2025-08-31T00:00:00+09:00';
    //final startDateStr = '2025-08-28T00:00:00Z'; // こっちだとUTCになるのでNG
    final startDate = DateTime.parse(startDateStr);
    final endDate = startDate.add(const Duration(days: 7));

    final steps1 = await _getSteps1(startDate, endDate);
    final steps2 = await _getSteps2(startDate, endDate);
    final steps3 = await _getSteps3(startDate, endDate);

    print('steps1: $steps1');
    print('steps2: $steps2');
    print('steps3: $steps3');
  }

  // 歩数取得。getTotalStepsInIntervalによる取得
  Future<int?> _getSteps1(DateTime startDate, DateTime endDate) async {
    if (_health == null) {
      return null;
    }
    final health = _health!;
    return await health.getTotalStepsInInterval(startDate, endDate);
  }

  // 歩数取得。getHealthDataFromTypesによる取得
  Future<int?> _getSteps2(DateTime startDate, DateTime endDate) async {
    if (_health == null) {
      return null;
    }
    final health = _health!;

    List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
      types: _healthDataTypes,
      startTime: startDate,
      endTime: endDate,
    );

    health.removeDuplicates(healthData);

    print('============');
    healthData.forEach((data) {
      String log = "";
      log +=
          "${data.dateFrom} - ${data.dateTo}: ${data.sourceId}, ${data.sourceName}, ${data.sourcePlatform}, ${data.deviceModel}, ${data.recordingMethod}, ${data.type.name}, ${data.value}, ${data.unit.name}";
      print('Health data: $log');
    });

    num totalStepsCalclated = healthData.fold(0, (total, data) {
      if (data.type == HealthDataType.STEPS &&
          data.value is NumericHealthValue) {
        //final numValue = (data.value as NumericHealthValue).numericValue;
        //print('data.value: ${data.value.$type}, ${numValue}');
        return total + (data.value as NumericHealthValue).numericValue;
      }
      return total;
    });

    return totalStepsCalclated.toInt();
  }

  // 歩数取得。getHealthIntervalDataFromTypesによる取得
  // 歩数の集計はこちらで行うと思う
  Future<int?> _getSteps3(DateTime startDate, DateTime endDate) async {
    if (_health == null) {
      return null;
    }
    final health = _health!;

    List<HealthDataPoint> healthData = await health
        .getHealthIntervalDataFromTypes(
          types: _healthDataTypes,
          startDate: startDate,
          endDate: endDate,
          interval: 24 * 60 * 60, // 秒
        );

    health.removeDuplicates(healthData);

    print('============');
    healthData.forEach((data) {
      String log = "";
      log +=
          "${data.dateFrom} - ${data.dateTo}: ${data.sourceId}, ${data.sourceName}, ${data.sourcePlatform}, ${data.deviceModel}, ${data.recordingMethod}, ${data.type.name}, ${data.value}, ${data.unit.name}";
      print('Health data: $log');
    });

    num totalStepsCalclated = healthData.fold(0, (total, data) {
      if (data.type == HealthDataType.STEPS &&
          data.value is NumericHealthValue) {
        //final numValue = (data.value as NumericHealthValue).numericValue;
        //print('data.value: ${data.value.$type}, ${numValue}');
        return total + (data.value as NumericHealthValue).numericValue;
      }
      return total;
    });

    return totalStepsCalclated.toInt();
  }

  void _onWalkingStartButtonTapped() {
    _walkingStartDate = DateTime.now();
    setState(() {
      _currentSteps1 = 'getTotalStepsInInterval: 0';
      _currentSteps2 = 'getHealthDataFromTypes: 0';
      _currentSteps3 = 'getHealthIntervalDataFromTypes: 0';
    });
    print('_onWalkingStartButtonTapped: $_walkingStartDate');
  }

  void _onReadCurrentDataButtonTapped() async {
    if (_walkingStartDate == null) {
      print('_walkingStartDate is null');
      return;
    }
    final startDate = _walkingStartDate!;
    final endDate = DateTime.now();
    final steps1 = await _getSteps1(startDate, endDate);
    final steps2 = await _getSteps2(startDate, endDate);
    final steps3 = await _getSteps3(startDate, endDate);

    print('steps1: $steps1');
    print('steps2: $steps2');
    print('steps3: $steps3');
    setState(() {
      _currentSteps1 = 'getTotalStepsInInterval: ${steps1 ?? 0}';
      _currentSteps2 = 'getHealthDataFromTypes: ${steps2 ?? 0}';
      _currentSteps3 = 'getHealthIntervalDataFromTypes: ${steps3 ?? 0}';
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Text('Android用'),
          ElevatedButton(
            onPressed: _onButtonTapped,
            child: const Text('プライバシーポリシー'),
          ),
          SizedBox(height: 16),
          Text('ヘルス機能読み取り'),
          ElevatedButton(
            onPressed: _onHealthInitButtonTapped,
            child: const Text('health初期化'),
          ),
          ElevatedButton(
            onPressed: _onReadButtonTapped,
            child: const Text('過去データ読み取り'),
          ),
          SizedBox(height: 16),
          Text('リアルタイム読み取りの試し'),
          ElevatedButton(
            onPressed: _onWalkingStartButtonTapped,
            child: const Text('読み取り開始'),
          ),
          ElevatedButton(
            onPressed: _onReadCurrentDataButtonTapped,
            child: const Text('現時点データ読み取り'),
          ),
          Text('$_currentSteps1'),
          Text('$_currentSteps2'),
          Text('$_currentSteps3'),
        ],
      ),
    );
  }
}
