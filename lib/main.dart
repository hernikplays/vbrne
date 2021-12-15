import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vbrne/communication.dart';
import 'package:workmanager/workmanager.dart';

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
// TODO: Přidat analysis options
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
      home: MyHomePage(title: 'Přihlásit se'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _mailcontroller = TextEditingController();
  final TextEditingController _passcontroller = TextEditingController();
  bool rememberChecked = false;

  @override
  void initState() {
    super.initState();
    c.ziskejUdaje().then((value) async {
      if (value != null) {
        // jsou uložené údaje

        var connectivityResult = await (Connectivity().checkConnectivity());
        if (connectivityResult == ConnectivityResult.none) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Nastala chyba při kontaktování serveru, zkontrolujte připojení"),
            ),
          );
        }

        var result =
            await c.login(value["mail"]!, value["pass"]!, rememberChecked);
        print("aa");
        print(c.cookie == null);
        if (result == false) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Nepodařilo se přihlásit, zkontrolujte správnost údajů a stav BRNOiD."),
            ),
          );
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (ctx) => MainPage(title: "BRNOiD")));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Container(
        color: Color(0xffcb0e21),
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Text(
                  "V Brně",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 50.0),
                ),
              ),
              Text(
                "BRNOiD v Mobilu",
                style: TextStyle(color: Colors.white, fontSize: 20.0),
              ),
              Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Container(
                  width: MediaQuery.of(context).size.width - 50,
                  child: TextField(
                    controller: _mailcontroller,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                        labelText: "E-Mail",
                        labelStyle: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Container(
                  width: MediaQuery.of(context).size.width - 50,
                  child: TextField(
                    controller: _passcontroller,
                    obscureText: true,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                        labelText: "Heslo",
                        labelStyle: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: rememberChecked,
                      onChanged: (value) {
                        setState(() {
                          rememberChecked = !rememberChecked;
                        });
                      },
                    ),
                    InkWell(
                      child: Text(
                        "Zapamatovat si",
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        setState(() {
                          rememberChecked = !rememberChecked;
                        });
                      },
                    )
                  ],
                  mainAxisAlignment: MainAxisAlignment.center,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: TextButton(
                  child: Text(
                    "Přihlásit se",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    var connectivityResult =
                        await (Connectivity().checkConnectivity());
                    print(connectivityResult);
                    if (connectivityResult == ConnectivityResult.none) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Nastala chyba při kontaktování serveru, zkontrolujte připojení"),
                        ),
                      );
                    }

                    var result = await c.login(_mailcontroller.text,
                        _passcontroller.text, rememberChecked);
                    if (result == false) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Nepodařilo se přihlásit, zkontrolujte e-mail a heslo."),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (ctx) => MainPage(title: "BRNOiD")));
                    }
                  },
                ),
              ),
            ],
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
        ),
      ),
    );
  }
}

// rozcestník
class MainPage extends StatefulWidget {
  MainPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (val) async {
              switch (val) {
                case "Odhlásit se":
                  final storage = new FlutterSecureStorage();
                  await storage.delete(key: "vbrne_user");
                  await storage.delete(key: "vbrne_pass");
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) => MyHomePage(title: "Přihlásit se")));
                  break;
                case "Nastavení":
                  // TODO: Nastavení
                  break;
                default:
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Odhlásit se', 'Nastavení'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Container(
          width: double.infinity,
          child: GridView.count(
            crossAxisCount: 2,
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (builder) => MHDMain()));
                },
                child: Container(
                  child: Center(
                    child: Text(
                      "MHD",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 30.0,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage("assets/mhd.png"),
                          fit: BoxFit.cover)),
                ),
              )
            ],
          )),
    );
  }
}

class MHDMain extends StatefulWidget {
  MHDMain({Key? key}) : super(key: key);

  @override
  _MHDMainState createState() => _MHDMainState();
}

class _MHDMainState extends State<MHDMain> {
  var content = <Widget>[];
  var title = "Jízdenky";
  @override
  void initState() {
    super.initState();
    c.validateCookie().then((result) {
      if (!result) {
        // nefunkční cookie
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (buildContext) => MyHomePage(title: 'Přihlásit se'),
          ),
        );
      } else {
        vemListky(context, c.cookie!).then((value) {
          setState(() {
            content.addAll(value);
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MHD"),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          child: DefaultTextStyle(
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.black),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: content,
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text("BRNOiD - MHD")),
            ListTile(
              title: Text("Domů"),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (ctx) => MainPage(title: 'Domů')));
              },
            ),
            ListTile(
              selected: true,
              title: Text(
                "Jízdenky",
              ),
              onTap: () {
                Navigator.pop(context);
              },
              leading: Icon(Icons.list),
            ),
            ListTile(
                title: Text("Zakoupit předplatní jízdenku"),
                onTap: () {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (ctx) => NakupVyberNosic()));
                },
                leading: Icon(Icons.directions_bus)),
            ListTile(
                title: Text("Kontroly revizorem"),
                onTap: () {/* TODO */},
                leading: Icon(Icons.assignment_ind)),
            ListTile(
              title: Text("Mé nosiče"),
              onTap: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (ctx) => NosicePage()));
              },
              leading: Icon(Icons.credit_card),
            )
          ],
        ),
      ),
    );
  }
}

Future<List<Widget>> vemListky(context, cookie) async {
  var content = <Widget>[];
  var listky = await c.ziskejJizdenky();
  if (listky == null) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          "Při komunikaci se serverem došlo k chybě, zkontrolujte připojení"),
    ));
  } else if (listky.isEmpty) {
    content = [Center(child: Text("Nemáte žádné jízdenky"))];
  } else {
    for (var listek in listky) {
      content.add(Padding(
        padding: EdgeInsets.only(top: 15.0, right: 5, left: 5),
        child: Container(
            width: double.infinity,
            child: DefaultTextStyle(
              child: Column(
                children: [
                  Text("Jízdenka ${listek.nazev}"),
                  Row(
                    children: [
                      Text("Platí od: "),
                      Text(
                        "${listek.platiOd.day}. ${listek.platiOd.month}. ${listek.platiOd.year}, ${listek.platiOd.hour}:${listek.platiOd.minute}",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Text("Platí do: "),
                      Text(
                        "${listek.platiDo.day}. ${listek.platiDo.month}. ${listek.platiDo.year}, ${listek.platiDo.hour}:${listek.platiDo.minute}",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Text("Cena: "),
                      Text(
                        listek.cena,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  (listek.platiTed)?Text("Platí",style:TextStyle(color:Colors.green))
                ],
              ),
              style: TextStyle(fontSize: 18.0, color: Colors.black),
            )),
      ));
    }
  }
  return content;
}

class NosicePage extends StatefulWidget {
  NosicePage({Key? key}) : super(key: key);

  @override
  _NosicePage createState() => _NosicePage();
}

class _NosicePage extends State<NosicePage> {
  final content = <Widget>[];

  @override
  void initState() {
    super.initState();
    c.validateCookie().then((valid) {
      if (!valid)
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (ctx) => MyHomePage(title: 'Přihlásit se')));

      c.ziskatNosice().then((nosice) {
        // TODO: Kontrolovat platnost
        if (nosice.isEmpty) {
          content.add(Center(
            child: Text("Nemáte žádné nosiče"),
          ));
        } else {
          for (var nosic in nosice) {
            content.add(Padding(
              padding: EdgeInsets.only(top: 10, left: 10, right: 10),
              child: Column(
                children: [
                  Text(nosic.nosicCislo),
                  Row(
                    children: [
                      Text(
                        "Platí do: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(nosic.platiDo)
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        "Číslo karty: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(nosic.cislo)
                    ],
                  ),
                ],
              ),
            ));
          }
          setState(() {});
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mé nosiče"),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          child: DefaultTextStyle(
            child: Column(
                children: content,
                crossAxisAlignment: CrossAxisAlignment.center),
            style: TextStyle(fontSize: 18.0, color: Colors.black),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text("BRNOiD - MHD")),
            ListTile(
              title: Text("Domů"),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (ctx) => MainPage(title: 'Domů')));
              },
            ),
            ListTile(
              title: Text(
                "Jízdenky",
              ),
              onTap: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (ctx) => MHDMain()));
              },
              leading: Icon(Icons.list),
            ),
            ListTile(
                title: Text("Zakoupit předplatní jízdenku"),
                onTap: () {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (ctx) => NakupVyberNosic()));
                },
                leading: Icon(Icons.directions_bus)),
            ListTile(
                title: Text("Kontroly revizorem"),
                onTap: () {/* TODO */},
                leading: Icon(Icons.assignment_ind)),
            ListTile(
              title: Text("Mé nosiče"),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
              leading: Icon(Icons.credit_card),
            )
          ],
        ),
      ),
    );
  }
}

class NakupVyberNosic extends StatefulWidget {
  NakupVyberNosic({Key? key}) : super(key: key);

  @override
  _NakupVyberNosicState createState() => _NakupVyberNosicState();
}

class _NakupVyberNosicState extends State<NakupVyberNosic> {
  var content = <Widget>[];
  var itemy = <Nosic>[]; // vsechny nosice uzivatele
  var vybranyObjekt; // vybrany nosic

  void ziskejNosice() {
    c.ziskatNosice().then((nosice) {
      if (nosice.length < 1) {
        //TODO: uživatel nemá nosič
      } else {
        itemy = nosice;
        setState(() {});
      }
    });
  }

  @override
  void initState() {
    super.initState();
    c.validateCookie().then((valid) {
      if (!valid)
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (ctx) => MyHomePage(title: 'Přihlásit se')));
    });

    // získáme nosiče
    ziskejNosice();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Zakoupit předplatní jízdenku"),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
                  child: Text(
                    "Vyberte nosič, na který chcete zakoupit jízdenku",
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width / 1.3,
                  child: DropdownButton<String>(
                    items: (itemy.isEmpty)
                        ? null
                        : itemy.map<DropdownMenuItem<String>>((Nosic value) {
                            return DropdownMenuItem<String>(
                                child: Text(value.nosicCislo,
                                    style: TextStyle(fontSize: 20)),
                                value: value.id);
                          }).toList(),
                    value: vybranyObjekt,
                    icon: Icon(Icons.credit_card),
                    isExpanded: true,
                    onChanged: (newValue) {
                      setState(() {
                        vybranyObjekt = newValue!;
                      });
                    },
                  ),
                ),
                TextButton(
                    onPressed: () {
                      if (vybranyObjekt == null) return;
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (ctx) =>
                              NakupVybratKategorii(nosicId: vybranyObjekt)));
                    },
                    child: Text("Pokračovat")),
              ],
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text("BRNOiD - MHD")),
            ListTile(
              title: Text("Domů"),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (ctx) => MainPage(title: 'Domů')));
              },
            ),
            ListTile(
              title: Text(
                "Jízdenky",
              ),
              onTap: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (ctx) => MHDMain()));
              },
              leading: Icon(Icons.list),
            ),
            ListTile(
                title: Text("Zakoupit předplatní jízdenku"),
                selected: true,
                onTap: () {
                  Navigator.pop(context);
                },
                leading: Icon(Icons.directions_bus)),
            ListTile(
                title: Text("Kontroly revizorem"),
                onTap: () {/* TODO */},
                leading: Icon(Icons.assignment_ind)),
            ListTile(
              title: Text("Mé nosiče"),
              onTap: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (ctx) => NosicePage()));
              },
              leading: Icon(Icons.credit_card),
            )
          ],
        ),
      ),
    );
  }
}

class NakupVybratKategorii extends StatefulWidget {
  // zde vybereme kategorii
  NakupVybratKategorii({Key? key, required this.nosicId}) : super(key: key);

  final String nosicId;

  @override
  _VybratKategoriiState createState() => _VybratKategoriiState();
}

class _VybratKategoriiState extends State<NakupVybratKategorii> {
  var content = <Widget>[];
  var itemy = <RegExpMatch>[]; // vsechny kategorie uzivatele
  var itemyId; // id jednotlivych kategorii
  var vybranyObjekt; // vybrana kategorie

  @override
  void initState() {
    super.initState();
    c.validateCookie().then((valid) {
      if (!valid)
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (ctx) => MyHomePage(title: 'Přihlásit se')));
    });

    // získáme kategorie
    ziskejKategorie();
  }

  void ziskejKategorie() {
    http.get(
        Uri.parse(
            "https://www.brnoid.cz/cs/koupit-jizdenku-ids?controller=buy-ticket-ids&customer_token=${widget.nosicId.replaceAll("token_", "")}&id_category=17#select-category"),
        headers: {HttpHeaders.cookieHeader: c.cookie!}).then((res) {
      var mozneSlevy = RegExp(r'(?<=<select).+?(?=<\/select)')
          .firstMatch(res.body)!
          .group(0)!
          .toString();

      itemy =
          RegExp(r'(?<=" >).+?(?=<\/option)').allMatches(mozneSlevy).toList();

      itemyId =
          RegExp(r'(?<=value=")\d+?(?=")').allMatches(mozneSlevy).toList();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Zakoupit předplatní jízdenku"),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
                  child: Text(
                    "Vyberte kategorii jízdného",
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width / 1.3,
                  child: DropdownButton<String>(
                    items: (itemy.isEmpty)
                        ? null
                        : itemy
                            .map<DropdownMenuItem<String>>((RegExpMatch value) {
                            return DropdownMenuItem<String>(
                                child: Text(value.group(0).toString(),
                                    style: TextStyle(fontSize: 20)),
                                value: itemyId[itemy.indexOf(value)]
                                    .group(0)
                                    .toString());
                          }).toList(),
                    value: vybranyObjekt,
                    icon: Icon(Icons.person),
                    isExpanded: true,
                    onChanged: (newValue) {
                      setState(() {
                        vybranyObjekt = newValue!;
                      });
                    },
                  ),
                ),
                TextButton(
                    onPressed: () {
                      if (vybranyObjekt == null) return;
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (ctx) => NakupVybratJizdenku(
                              nosicId: widget.nosicId,
                              kategorie: vybranyObjekt)));
                    },
                    child: Text("Pokračovat")),
              ],
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text("BRNOiD - MHD")),
            ListTile(
              title: Text("Domů"),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (ctx) => MainPage(title: 'Domů')));
              },
            ),
            ListTile(
              title: Text(
                "Jízdenky",
              ),
              onTap: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (ctx) => MHDMain()));
              },
              leading: Icon(Icons.list),
            ),
            ListTile(
                title: Text("Zakoupit předplatní jízdenku"),
                selected: true,
                onTap: () {
                  Navigator.pop(context);
                },
                leading: Icon(Icons.directions_bus)),
            ListTile(
                title: Text("Kontroly revizorem"),
                onTap: () {/* TODO */},
                leading: Icon(Icons.assignment_ind)),
            ListTile(
              title: Text("Mé nosiče"),
              onTap: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (ctx) => NosicePage()));
              },
              leading: Icon(Icons.credit_card),
            )
          ],
        ),
      ),
    );
  }
}

class NakupVybratJizdenku extends StatefulWidget {
  // zde vybereme kategorii
  NakupVybratJizdenku(
      {Key? key, required this.nosicId, required this.kategorie})
      : super(key: key);

  final String nosicId;
  final String kategorie;

  @override
  _VybratJizdenkuState createState() => _VybratJizdenkuState();
}

class _VybratJizdenkuState extends State<NakupVybratJizdenku> {
  var content = <Widget>[];
  var itemy = <
      DropdownMenuItem<
          String>>[]; // nazvy jednotlivych jizdenek kategorie uzivatele
  var itemyId; // id jednotlivych jizdenek
  var vybranyObjekt; // vybrana jizdenka
  var vybiratZony = false;
  var vyberZon = <Row>[];
  var zonyNavic = <String?>[];

  @override
  void initState() {
    super.initState();
    c.validateCookie().then((valid) {
      if (!valid)
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (ctx) => MyHomePage(title: 'Přihlásit se')));
    });

    // získáme kategorie
    ziskejJizdenky();
  }

  void ziskejJizdenky() {
    http.get(
        Uri.parse(
            "https://www.brnoid.cz/cs/koupit-jizdenku-ids?controller=buy-ticket-ids&customer_token=${widget.nosicId.replaceAll("token_", "")}&id_category=17&id_subcategory=${widget.kategorie}#select-category"),
        headers: {HttpHeaders.cookieHeader: c.cookie!}).then((res) {
      var mozneJizdenky = RegExp(r'(?<=id="products").+?(?=<\/select)')
          .firstMatch(res.body)!
          .group(0)!
          .toString();

      var options =
          RegExp(r'(?<=<optgroup).+?(?=">)|(?<=<option value).+?(?=<\/option)')
              .allMatches(mozneJizdenky)
              .skip(1)
              .toList();
      for (var k in options) {
        var match = k.group(0).toString();
        if (match.contains("label")) {
          // match je <optgroup>
          itemy.add(DropdownMenuItem<String>(
            child: Text(
              match.replaceAll("label=\"", ""),
            ),
            enabled: false,
          ));
        } else {
          // jizdenka
          var id = RegExp(r'(?<=")\d+?(?=")', dotAll: true)
              .firstMatch(match)!
              .group(0)
              .toString();
          var nazev = RegExp(r'(?<=>).+', dotAll: true)
              .firstMatch(match)!
              .group(0)
              .toString();
          itemy.add(DropdownMenuItem<String>(
            child: Text(nazev, softWrap: true, overflow: TextOverflow.fade),
            value: id,
          ));
        }
      }
      setState(() {});
    });
  }

  void pridejZonu(id, sourceZona, List<String> except) {
    var data = Map<String, dynamic>();
    data["ajax"] = "1";
    data["action"] = "get_neighbouring_zones";
    data["id_product"] = id;
    data["source"] = sourceZona;
    data["except"] = except.join(";");
    http.post(Uri.parse("https://www.brnoid.cz/cs/koupit-jizdenku-ids"),
        body: data, headers: {HttpHeaders.cookieHeader: c.cookie!}).then((res) {
      print(res.body);
      var r = res.body.replaceAll(RegExp(r'("|\[|\])'), "").split(",");
      print(r[0]);
    });
  }

  Future<void> ziskejZony(id, pocetZon) async {
    vyberZon = [];
    var res = await http.get(
        Uri.parse(
            "https://www.brnoid.cz/cs/koupit-jizdenku-ids?controller=buy-ticket-ids&customer_token=${widget.nosicId.replaceAll("token_", "")}&id_category=17&id_subcategory=${widget.kategorie}&id_product=$id#select-validity"),
        headers: {HttpHeaders.cookieHeader: c.cookie!});
    var inputMatcher = RegExp(
        r'(?<=name="zones\[3\]">).+(?=<\/select>)'); // tímto získáme možnosti pro 3. zónu, od které se pak odpíchneme k další
    var optionMatcher =
        RegExp(r'(?<=value=")\d+'); // tímto získáme každou zónu zvlášť
    var itemy = <DropdownMenuItem<String>>[];

    var options = inputMatcher.firstMatch(res.body)!.group(0).toString();

    var zony = optionMatcher.allMatches(options).toList();
    for (var zona in zony) {
      var z = zona.group(0).toString();
      print(z);
      itemy.add(DropdownMenuItem<String>(child: Text(z), value: z));
    }

    vyberZon.add(Row(children: [
      Text(
        "3. zóna: ",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      DropdownButton(
          items: itemy,
          onChanged: (newValue) {
            var vybrana = newValue!.toString();
            if (zonyNavic.isEmpty) {
              zonyNavic.add(vybrana);
            } else {
              zonyNavic[0] = vybrana;
            }
            pridejZonu(id, vybrana, [vybrana]);
            setState(() {});
          },
          value: (zonyNavic.isEmpty) ? null : zonyNavic[0])
    ], mainAxisAlignment: MainAxisAlignment.center));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Zakoupit předplatní jízdenku"),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
                  child: Text(
                    "Vyberte jízdenku",
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  child: DropdownButton<String>(
                    items: (itemy.isEmpty) ? null : itemy,
                    value: vybranyObjekt,
                    icon: Icon(Icons.confirmation_number_rounded),
                    isExpanded: true,
                    onChanged: (newValue) async {
                      var newName = itemy.firstWhere((element) {
                        if (element.value == newValue) {
                          return true;
                        } else
                          return false;
                      });
                      await ziskejZony(
                          newValue,
                          RegExp(r'\+\d zón')
                              .firstMatch(newName.child.toString())!
                              .group(0)
                              .toString()
                              .replaceAll(" zón", ""));
                      setState(() {
                        if (newName.child
                            .toString()
                            .contains(RegExp(r'\+\d zón'))) {
                          vybiratZony = true;
                        } else
                          vybiratZony = false;
                        vybranyObjekt = newValue;
                      });
                    },
                  ),
                  width: 300,
                ),
                Visibility(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
                        child: Text(
                          "Vyberte zóny",
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ...vyberZon
                    ],
                  ),
                  visible: vybiratZony,
                ),
                TextButton(
                    onPressed: () {
                      if (vybranyObjekt == null) return;
                      // TODO: Pokračuj na nákup
                    },
                    child: Text("Pokračovat")),
              ],
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text("BRNOiD - MHD")),
            ListTile(
              title: Text("Domů"),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (ctx) => MainPage(title: 'Domů')));
              },
            ),
            ListTile(
              title: Text(
                "Jízdenky",
              ),
              onTap: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (ctx) => MHDMain()));
              },
              leading: Icon(Icons.list),
            ),
            ListTile(
                title: Text("Zakoupit předplatní jízdenku"),
                selected: true,
                onTap: () {
                  Navigator.pop(context);
                },
                leading: Icon(Icons.directions_bus)),
            ListTile(
                title: Text("Kontroly revizorem"),
                onTap: () {/* TODO */},
                leading: Icon(Icons.assignment_ind)),
            ListTile(
              title: Text("Mé nosiče"),
              onTap: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (ctx) => NosicePage()));
              },
              leading: Icon(Icons.credit_card),
            )
          ],
        ),
      ),
    );
  }
}
