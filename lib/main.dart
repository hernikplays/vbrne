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
              title: Text("Domů"),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (ctx) =>
                        MainPage(title: 'Domů', cookie: widget.cookie)));
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
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) =>
                              NakupVyberNosic(cookie: widget.cookie)));
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
  var listky = await Communicator.ziskejJizdenky(cookie);
  if (listky == null) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          "Při komunikaci se serverem došlo k chybě, zkontrolujte připojení"),
    ));
  } else if (listky.length == 0) {
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
                        listek.platiOd,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Text("Platí do: "),
                      Text(
                        listek.platiDo,
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
                  )
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
              title: Text("Domů"),
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (ctx) =>
                        MainPage(title: 'Domů', cookie: widget.cookie)));
              },
            ),
            ListTile(
              title: Text(
                "Jízdenky",
              ),
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (ctx) => MHDMain(cookie: widget.cookie)));
              },
              leading: Icon(Icons.list),
            ),
            ListTile(
                title: Text("Zakoupit předplatní jízdenku"),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) =>
                              NakupVyberNosic(cookie: widget.cookie)));
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
  NakupVyberNosic({Key? key, required this.cookie}) : super(key: key);

  final String cookie;

  @override
  _NakupVyberNosicState createState() => _NakupVyberNosicState();
}

class _NakupVyberNosicState extends State<NakupVyberNosic> {
  var content = <Widget>[];
  var itemy = <Nosic>[]; // vsechny nosice uzivatele
  var vybranyObjekt; // vybrany nosic

  void ziskejNosice() {
    Communicator.ziskatNosice(widget.cookie).then((nosice) {
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
    Communicator.validateCookie(widget.cookie).then((valid) {
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
                DropdownButton<String>(
                  items: (itemy.length == 0)
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
                TextButton(
                    onPressed: () {
                      if (vybranyObjekt == null) return;
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (ctx) => NakupVybratKategorii(
                              cookie: widget.cookie, nosicId: vybranyObjekt)));
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
                    builder: (ctx) =>
                        MainPage(title: 'Domů', cookie: widget.cookie)));
              },
            ),
            ListTile(
              title: Text(
                "Jízdenky",
              ),
              onTap: () {
                Navigator.pushReplacement(
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
                Navigator.pushReplacement(
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

class NakupVybratKategorii extends StatefulWidget {
  // zde vybereme kategorii
  NakupVybratKategorii({Key? key, required this.cookie, required this.nosicId})
      : super(key: key);

  final String cookie;
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
    Communicator.validateCookie(widget.cookie).then((valid) {
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
        headers: {HttpHeaders.cookieHeader: widget.cookie}).then((res) {
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
                DropdownButton<String>(
                  items: (itemy.length == 0)
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
                TextButton(
                    onPressed: () {
                      if (vybranyObjekt == null) return;
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (ctx) => NakupVybratJizdenku(
                              cookie: widget.cookie,
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
                    builder: (ctx) =>
                        MainPage(title: 'Domů', cookie: widget.cookie)));
              },
            ),
            ListTile(
              title: Text(
                "Jízdenky",
              ),
              onTap: () {
                Navigator.pushReplacement(
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
                Navigator.pushReplacement(
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

class NakupVybratJizdenku extends StatefulWidget {
  // zde vybereme kategorii
  NakupVybratJizdenku(
      {Key? key,
      required this.cookie,
      required this.nosicId,
      required this.kategorie})
      : super(key: key);

  final String cookie;
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

    // získáme kategorie
    ziskejJizdenky();
  }

  void ziskejJizdenky() {
    http.get(
        Uri.parse(
            "https://www.brnoid.cz/cs/koupit-jizdenku-ids?controller=buy-ticket-ids&customer_token=${widget.nosicId.replaceAll("token_", "")}&id_category=17&id_subcategory=${widget.kategorie}#select-category"),
        headers: {HttpHeaders.cookieHeader: widget.cookie}).then((res) {
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
                    items: (itemy.length == 0) ? null : itemy,
                    value: vybranyObjekt,
                    icon: Icon(Icons.confirmation_number_rounded),
                    isExpanded: true,
                    onChanged: (newValue) {
                      setState(() {
                        if (newValue!.contains(RegExp(r'\+\d zón'))) {
                          vybiratZony = true;
                        }
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
                    builder: (ctx) =>
                        MainPage(title: 'Domů', cookie: widget.cookie)));
              },
            ),
            ListTile(
              title: Text(
                "Jízdenky",
              ),
              onTap: () {
                Navigator.pushReplacement(
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
                Navigator.pushReplacement(
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
