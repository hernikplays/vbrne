// rozcestník
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vbrne/communication.dart';
import 'package:vbrne/okna/prihlaseni.dart';

import 'mhd/mhd_base.dart';
import 'mhd/mhd_home.dart';

class MainPage extends StatefulWidget {
  MainPage({Key? key, required this.c}) : super(key: key);

  final Communicator c;

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BRNOiD"),
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
                          builder: (ctx) => Prihlaseni(c: widget.c)));
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
                          builder: (builder) => MHDBase(c: widget.c)));
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
