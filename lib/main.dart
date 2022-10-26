import 'dart:developer';
import 'dart:io';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

void headlessTask(HeadlessTask task) async {
  if (Platform.isAndroid) {
    log("Checking permissions");
    var status = await Permission.locationAlways.status;
    var locationAlwaysGranted = status.isGranted;
    if (locationAlwaysGranted) {
      log("We have location permissions");
    }
  }
  BackgroundFetch.finish(task.taskId);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  headlessTask(HeadlessTask("abcd", true));

  BackgroundFetch.registerHeadlessTask(headlessTask);
  BackgroundFetch.configure(BackgroundFetchConfig(
    minimumFetchInterval: 15,
    stopOnTerminate: false,
    enableHeadless: true,
    startOnBoot: true,
    requiresBatteryNotLow: false,
    requiresStorageNotLow: false,
    requiresCharging: false,
    requiresDeviceIdle: false,
    requiredNetworkType: NetworkType.NONE
  ), (String taskId) {
    BackgroundFetch.finish(taskId);
  });
  BackgroundFetch.scheduleTask(TaskConfig(
    delay: 0,
    periodic: false,
    startOnBoot: true,
    taskId: "app_on_boot",
    enableHeadless: true
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class DemoModel extends ChangeNotifier {
  bool locationGranted = false;
  bool locationAlwaysGranted = false;

  void requestLocation() async {
    var status = await Permission.location.status;
    if (locationGranted != status.isGranted) {
      locationGranted = status.isGranted;
      notifyListeners();
    }

    if (locationGranted) {
      return;
    }

    final grant = Permission.location.request();
    locationGranted = await grant.isGranted;
    notifyListeners();
  }

  void requestLocationAlways() async {
    var status = await Permission.locationAlways.status;
    if (locationAlwaysGranted != status.isGranted) {
      locationAlwaysGranted = status.isGranted;
      notifyListeners();
    }

    if (locationAlwaysGranted) {
      return;
    }

    final grant = Permission.locationAlways.request();
    locationAlwaysGranted = await grant.isGranted;
    notifyListeners();
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Permissions Demo")),
      body: SingleChildScrollView(
        child: ChangeNotifierProvider.value(
          value: DemoModel(),
          child: buildContent()
        )
      )
    );
  }

  Widget buildContent() {
    return Consumer<DemoModel> (
      builder: (context, model, child) {
        if (!model.locationGranted) {
          return AlertDialog(
            title: const Text("Location Permission Required"),
            content: const Text("Please grant the location permission when prompted"),
            actions: [
              TextButton(
                onPressed: model.requestLocation,
                child: const Text("Accept")
              )
            ]
          );
        } else if(!model.locationAlwaysGranted) {
          return AlertDialog(
            title: const Text("Background Location Permission Required"),
            content: const Text("Please grant the location permission for 'Always' when prompted"),
            actions: [
              TextButton(
                onPressed: model.requestLocationAlways,
                child: const Text("Accept")
              )
            ]
          );

        } else {
          return const AlertDialog(
            title: Text("Permissions Demo"),
            content: Text("Check the debug logs for results"),
          );
        }
      }
    );
  }
}

