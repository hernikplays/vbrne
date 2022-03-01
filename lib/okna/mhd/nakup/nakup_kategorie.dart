import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vbrne/communication.dart';
import 'package:vbrne/okna/prihlaseni.dart';

import '../../domov.dart';
import '../mhd_home.dart';
import '../mhd_nosice.dart';
import 'nakup_jizdenka.dart';

class NakupVybratKategorii extends StatefulWidget {
  // zde vybereme kategorii
  NakupVybratKategorii({Key? key, required this.nosicId, required this.c})
      : super(key: key);

  final String nosicId;
  final Communicator c;

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
    widget.c.validateCookie().then((valid) {
      if (!valid)
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (ctx) => Prihlaseni(c: widget.c)));
    });

    // získáme kategorie
    ziskejKategorie();
  }

  void ziskejKategorie() {
    http.get(
        Uri.parse(
            "https://www.brnoid.cz/cs/koupit-jizdenku-ids?controller=buy-ticket-ids&customer_token=${widget.nosicId.replaceAll("token_", "")}&id_category=17#select-category"),
        headers: {HttpHeaders.cookieHeader: widget.c.cookie!}).then((res) {
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
                              kategorie: vybranyObjekt,
                              c: widget.c)));
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
                        builder: (ctx) => NosicePage(c: widget.c)));
              },
              leading: Icon(Icons.credit_card),
            )
          ],
        ),
      ),
    );
  }
}
