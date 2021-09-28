import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
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

  Future<Map<String, String>?> ziskejUdaje() async {
    // zkontrolovat secure storage pokud je něco uložené
    final storage = new FlutterSecureStorage();
    var mail = await storage.read(key: "vbrne_user");
    var pass = await storage.read(key: "vbrne_pass");
    if (mail == null || pass == null) return null;
    return {"mail": mail, "pass": pass};
  }

  @override
  void initState() {
    super.initState();
    ziskejUdaje().then((value) async {
      if (value != null) {
        // jsou uložené údaje

        var connectivityResult = await (Connectivity().checkConnectivity());
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

        var result = await Communicator.login(
            value["mail"]!, value["pass"]!, rememberChecked);
        if (result == null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text("Nepodařilo se přihlásit, zkontrolujte e-mail a heslo."),
            ),
          );
        } else {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (ctx) => MainPage(title: "BRNOiD", cookie: result)));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
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

                    var result = await Communicator.login(_mailcontroller.text,
                        _passcontroller.text, rememberChecked);
                    if (result == null) {
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
                              builder: (ctx) =>
                                  MainPage(title: "BRNOiD", cookie: result)));
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
  var content = <Widget>[];
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
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) =>
                              ZakoupitJizdenku(cookie: widget.cookie)));
                },
                leading: Icon(Icons.directions_bus)),
            ListTile(
                title: Text("Kontroly revizorem"),
                onTap: () {/* TODO */},
                leading: Icon(Icons.assignment_ind)),
            ListTile(
              title: Text("Mé nosiče"),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (ctx) => NosicePage(cookie: widget.cookie)));
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
  // TODO: převést do COmmunicator.dart a zmenit regexp s lookbacky
  var content = <Widget>[];
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
    return <Widget>[];
  }
  var jizdenkyTable =
      RegExp(r"<tr>.+?(?=\/tr)", dotAll: true).allMatches(res.body);
  if (jizdenkyTable.length == 1) {
    //TODO: žádné jízdenky ?
    content = [Center(child: Text("Nemáte žádné platné jizdenky"))];
  }
  for (var jizdenka in jizdenkyTable.skip(1)) {
    var r = jizdenka.group(0).toString();

    var najitJmeno = RegExp(r"(?=<strong>).+?(?=<\/strong)", dotAll: true)
        .allMatches(r)
        .toList();
    var jmeno = najitJmeno[0].group(0).toString().replaceAll("<strong>", "");
    var nosic = najitJmeno[1].group(0).toString().replaceAll("<strong>", "");

// TODO: filtrovat neplatne jizdenky
    var platnost = RegExp(r'(?=<div class="label).+?(?=<\/div)')
        .firstMatch(r)!
        .group(0)
        .toString()
        .replaceAll(RegExp(r'<div class="label .+">'), "");
    if (platnost == "Neaktivn&iacute;") continue;

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

    content.add(Padding(
      padding: EdgeInsets.only(top: 15.0, right: 5, left: 5),
      child: Container(
          width: double.infinity,
          child: DefaultTextStyle(
            child: Column(
              children: [
                Text("Jízdenka $jmeno"),
                Row(
                  children: [
                    Text("Platí od: "),
                    Text(
                      platiOd,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )
                  ],
                ),
                Row(
                  children: [
                    Text("Platí do: "),
                    Text(
                      platiDo,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )
                  ],
                ),
                Row(
                  children: [
                    Text("Cena: "),
                    Text(
                      cena,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )
                  ],
                )
              ],
            ),
            style: TextStyle(fontSize: 18.0, color: Colors.black),
          )),
    ));
  }
  return content;
}

class NosicePage extends StatefulWidget {
  NosicePage({Key? key, required this.cookie}) : super(key: key);

  final String cookie;

  @override
  _NosicePage createState() => _NosicePage();
}

class _NosicePage extends State<NosicePage> {
  final content = <Widget>[];

  @override
  void initState() {
    super.initState();
    Communicator.validateCookie(widget.cookie).then((valid) {
      if (!valid)
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (ctx) => MyHomePage(title: 'Přihlásit se')));

      Communicator.ziskatNosice(widget.cookie).then((nosice) {
        // TODO: Kontrolovat platnost
        if (nosice.length == 0) {
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
                  )
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
              title: Text(
                "Jízdenky",
              ),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (ctx) => MHDMain(cookie: widget.cookie)));
              },
              leading: Icon(Icons.list),
            ),
            ListTile(
                title: Text("Zakoupit předplatní jízdenku"),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) =>
                              ZakoupitJizdenku(cookie: widget.cookie)));
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

class ZakoupitJizdenku extends StatefulWidget {
  ZakoupitJizdenku({Key? key, required this.cookie}) : super(key: key);

  final String cookie;

  @override
  _ZakoupitJizdenkuState createState() => _ZakoupitJizdenkuState();
}

class _ZakoupitJizdenkuState extends State<ZakoupitJizdenku> {
  var content = <Widget>[];
  var vybranyNosic;

  @override
  void initState() {
    super.initState();
    Communicator.validateCookie(widget.cookie).then((valid) {
      if (!valid)
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (ctx) => MyHomePage(title: 'Přihlásit se')));
    });

    // získáme nosiče
    Communicator.ziskatNosice(widget.cookie).then((nosice) {
      if (nosice.length < 1) {
        //TODO: uživatel nemá nosič
      } else {
        vybranyNosic = nosice[0].id;
        content = [
          Padding(
            padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
            child: Text(
              "Vyberte nosič, na který chcete zakoupit jízdenku",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          DropdownButton(
            items: nosice.map<DropdownMenuItem<String>>((Nosic value) {
              return DropdownMenuItem(
                  child: Text(value.nosicCislo, style: TextStyle(fontSize: 20)),
                  value: value.id);
            }).toList(),
            value: vybranyNosic,
            icon: Icon(Icons.credit_card),
            onChanged: (newValue) {
              setState(() {
                vybranyNosic = newValue;
              });
            },
          ),
          TextButton(
              onPressed: () {
                http
                    .get(Uri.parse(
                        "https://www.brnoid.cz/cs/koupit-jizdenku-ids?controller=buy-ticket-ids&customer_token=${vybranyNosic.replace("token_", "")}&id_category=17#select-category"))
                    .then((res) {
                  var optionRegex = RegExp(r'(?<=">).+?(?=<\/option)')
                      .allMatches(res.body)
                      .skip(1);
                  var valueRegex = RegExp(r'(?<=">).+?(?=<\/option)')
                      .allMatches(res.body)
                      .skip(1)
                      .toList();
                  var f = 0;
                  content = [
                    Padding(
                      padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
                      child: Text(
                        "Vyberte kategorii jízdného",
                        style: TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    DropdownButton(
                      items: optionRegex
                          .map<DropdownMenuItem<String>>((RegExpMatch moznost) {
                        f += 1;
                        return DropdownMenuItem(
                            child: Text(moznost.group(0).toString(),
                                style: TextStyle(fontSize: 20)),
                            value: valueRegex[f - 1].group(0).toString());
                      }).toList(),
                      value: vybranyNosic,
                      icon: Icon(Icons.credit_card),
                      onChanged: (newValue) {
                        setState(() {
                          vybranyNosic = newValue;
                        });
                      },
                    ),
                    TextButton(
                        onPressed: () {
                          http
                              .get(Uri.parse(
                                  "https://www.brnoid.cz/cs/koupit-jizdenku-ids?controller=buy-ticket-ids&customer_token=${vybranyNosic.replace("token_", "")}&id_category=17#select-category"))
                              .then((res) {
                            var optionRegex = RegExp(r'(?<=">).+?(?=<\/option)')
                                .allMatches(res.body)
                                .skip(1);
                            var valueRegex = RegExp(r'(?<=">).+?(?=<\/option)')
                                .allMatches(res.body)
                                .skip(1);
                          });
                        },
                        child: Text("Pokračovat"))
                  ];
                });
              },
              child: Text("Pokračovat"))
        ];
        setState(() {});
      }
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
              children: content,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text("BRNOiD - MHD")),
            ListTile(
              title: Text(
                "Jízdenky",
              ),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (ctx) => MHDMain(cookie: widget.cookie)));
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
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (ctx) => NosicePage(cookie: widget.cookie)));
              },
              leading: Icon(Icons.credit_card),
            )
          ],
        ),
      ),
    );
  }
}
