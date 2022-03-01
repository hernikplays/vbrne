import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vbrne/communication.dart';
import 'package:workmanager/workmanager.dart';

import 'okna/prihlaseni.dart';

/*
  Copyright 2021, Matyáš Caras and contributors

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Communicator c = Communicator();

/// Spustí se při kliknutí na oznámení
void selectNotification(String? payload) async {
  if (payload != null) {
    debugPrint('notification payload: $payload');
  }
  /*await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => SecondScreen(payload)),
    );*/
}

/// Zkontroluje a ukáže oznámení o vypršení
Future<bool> ukazVyprseniOznameni() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) return Future.value(false);
  if (c.cookie == null) {
    var value = await c.ziskejUdaje();
    if (value != null) {
      // jsou uložené údaje

      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        return Future.value(false);
      }

      var result = await c.login(value["mail"]!, value["pass"]!, true);
      print("b");
      print(c.cookie == null);
      if (result == false) {
        return Future.value(false);
      } else {
        return Future.value(false);
      }
    }
  }

  // kontrola jestli se má oznámení odeslat
  var today = DateTime.now();
  var jizdenky = await c.ziskejJizdenky();
  if (jizdenky == null) return Future.error("Chyba při získávání jízdenek");

  if (jizdenky[0].platiDo.subtract(Duration(days: 7)).isBefore(today)) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('vyprseni', 'jizdenka_vyprseni',
            channelDescription: 'Oznámení o vypršení předplatní jízdenky',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0,
        'Brzy vám vyprší předplatní jízdenka!',
        'Nezapomeňte si koupit novou',
        platformChannelSpecifics,
        payload: 'vyprsi');
  }
  Workmanager().cancelByUniqueName("2");
  return Future.value(true);
}

// Workmanager Callback
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    print(task);
    var t = ukazVyprseniOznameni();
    return t;
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(
    callbackDispatcher,
  );
  Workmanager().registerPeriodicTask("2", "checkExp",
      frequency: Duration(minutes: 15),
      backoffPolicyDelay: Duration(seconds: 15));
  runApp(MyApp());

  // Notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('launcher_icon');
  await flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(android: initializationSettingsAndroid),
      onSelectNotification: selectNotification);
}

class MyApp extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'V Brně',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: Prihlaseni(c: c),
    );
  }
}
