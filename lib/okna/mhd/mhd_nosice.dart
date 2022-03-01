import 'package:flutter/material.dart';
import 'package:vbrne/communication.dart';
import 'package:vbrne/okna/prihlaseni.dart';

import '../domov.dart';
import 'mhd_home.dart';
import 'nakup/nakup_nosic.dart';

class NosicePage extends StatefulWidget {
  NosicePage({Key? key, required this.c}) : super(key: key);

  final Communicator c;

  @override
  _NosicePage createState() => _NosicePage();
}

class _NosicePage extends State<NosicePage> {
  final content = <Widget>[];

  @override
  void initState() {
    super.initState();
    widget.c.validateCookie().then((valid) {
      if (!valid)
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (ctx) => Prihlaseni(c: widget.c)));

      widget.c.ziskatNosice().then((nosice) {
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
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (ctx) => MainPage(c: widget.c)));
              },
            ),
            ListTile(
              title: Text(
                "Jízdenky",
              ),
              onTap: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (ctx) => MHDMain(c: widget.c)));
              },
              leading: Icon(Icons.list),
            ),
            ListTile(
                title: Text("Zakoupit předplatní jízdenku"),
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) => NakupVyberNosic(c: widget.c)));
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
