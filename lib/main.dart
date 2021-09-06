import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vbrne/communication.dart';

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

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        color: Color(0xffcb0e21),
        width: double.infinity,
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
                onPressed: () {
                  if (_mailcontroller.text.length == 0 ||
                      _mailcontroller.text.length == 0) return;
                  http.post(Uri.parse('https://www.brnoid.cz/cs/overeni'),
                      body: {
                        'email': _mailcontroller.text,
                        'password': _passcontroller.text,
                        'SubmitLogin': ""
                      }).catchError((error) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "Nastala chyba při kontaktování serveru, zkontrolujte připojení"),
                      ),
                    );
                  }).then((res) async {
                    if (res.headers['location'] !=
                        "https://www.brnoid.cz/cs/muj-ucet") {
                      // v případě špatného hesla
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Nepodařilo se přihlásit, zkontrolujte e-mail a heslo."),
                        ),
                      );
                      return;
                    }
                    var cookie = res.headers['set-cookie'];
                    if (rememberChecked) {
                      // save username and password
                      final storage = new FlutterSecureStorage();
                      await storage.write(
                          key: 'vbrne_user', value: _mailcontroller.text);
                      await storage.write(
                          key: 'vbrne_pass', value: _passcontroller.text);
                    }
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (buildContext) => MainPage(
                                  cookie: cookie!,
                                  title: 'V Brně',
                                )));
                  });
                },
              ),
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.center,
        ),
      ),
    );
  }
}

// rozcestník
class MainPage extends StatefulWidget {
  MainPage({Key? key, required this.title, required this.cookie})
      : super(key: key);

  final String title;
  final String cookie;

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
          width: double.infinity,
          child: GridView.count(
            crossAxisCount: 2,
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (builder) =>
                              MHDMain(cookie: widget.cookie)));
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
  MHDMain({Key? key, required this.cookie}) : super(key: key);

  final String cookie;
  @override
  _MHDMainState createState() => _MHDMainState();
}

class _MHDMainState extends State<MHDMain> {
  var content = <TableRow>[
    TableRow(children: [
      TableCell(
          child: Text("Název produktu",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ))),
      TableCell(
          child: Text("Platnost od",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ))),
      TableCell(
          child: Text("Platnost do",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ))),
      TableCell(
          child: Text("Cena",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )))
    ])
  ];
  var title = "Jízdenky";
  @override
  void initState() {
    super.initState();
    Communicator.validateCookie(widget.cookie).then((result) {
      if (!result) {
        // nefunkční cookie
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (buildContext) => MyHomePage(title: 'Přihlásit se'),
          ),
        );
      } else {
        vemListky(context, widget.cookie).then((value) {
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
      body: Container(
        width: double.infinity,
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          DefaultTextStyle(
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black),
              child: Padding(
                child: Table(
                  children: content,
                ),
                padding: EdgeInsets.only(top: 10.0),
              ))
        ]),
      ),
    );
  }
}

Future<List<TableRow>> vemListky(context, cookie) async {
  var content = <TableRow>[];
  var res = await http.get(Uri.parse("https://www.brnoid.cz/cs/moje-jizdenky"),
      headers: {HttpHeaders.cookieHeader: cookie}).catchError((err) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          "Při komunikaci se serverem došlo k chybě, zkontrolujte připojení"),
    ));
    print(err);
  });
  if (res.statusCode >= 400) {
    // CHYBA
    print("chyba");
    return <TableRow>[];
  }
  var jizdenkyTable =
      RegExp(r"<tr>.+?(?=\/tr)", dotAll: true).allMatches(res.body);
  if (jizdenkyTable.length == 1) {
    //TODO: žádné jízdenky ?
  }
  for (var jizdenka in jizdenkyTable.skip(1)) {
    var r = jizdenka.group(0).toString();
    print(r);

    var najitJmeno = RegExp(r"(?=<strong>).+?(?=<\/strong)", dotAll: true)
        .allMatches(r)
        .toList();
    var jmeno = najitJmeno[0].group(0).toString().replaceAll("<strong>", "");
    var nosic = najitJmeno[1].group(0).toString().replaceAll("<strong>", "");

// TODO: filtrovat neplatne jizdenky
    /*var platnost = RegExp(r'(?=<div class="label).+?(?=<\/div)')
        .firstMatch(r)!
        .group(0)
        .toString()
        .replaceAll(RegExp(r'<div class="label .+">'), "");*/

    var platiOdDo =
        RegExp(r'(?=<span).+?(?=<\/span)', dotAll: true).allMatches(r).toList();
    var platiOd =
        "${platiOdDo[0].group(0).toString().replaceAll(RegExp(r'<span.+>'), "")}, ${platiOdDo[1].group(0).toString().replaceAll(RegExp(r'<span.+>'), "")}";
    var platiDo =
        "${platiOdDo[2].group(0).toString().replaceAll(RegExp(r'<span.+>'), "")}, ${platiOdDo[3].group(0).toString().replaceAll(RegExp(r'<span.+>'), "")}";

    nosic =
        "$nosic - ${platiOdDo[4].group(0).toString().replaceAll(RegExp(r'<span.+>'), "")}";

    var cena =
        RegExp(r"[0-9,]+ Kč(?=<\/div)").firstMatch(r)!.group(0).toString();

    content.add(TableRow(children: [
      TableCell(child: Text(jmeno)),
      TableCell(child: Text(platiOd)),
      TableCell(child: Text("$platiDo")),
      TableCell(child: Text(cena))
    ]));
  }
  return content;
}
