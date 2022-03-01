import 'package:flutter/material.dart';
import 'package:vbrne/communication.dart';
import 'package:vbrne/okna/prihlaseni.dart';

import '../../domov.dart';
import '../mhd_home.dart';
import '../mhd_nosice.dart';
import 'nakup_kategorie.dart';

class NakupVyberNosic extends StatefulWidget {
  NakupVyberNosic({Key? key, required this.c}) : super(key: key);

  final Communicator c;

  @override
  _NakupVyberNosicState createState() => _NakupVyberNosicState();
}

class _NakupVyberNosicState extends State<NakupVyberNosic> {
  var content = <Widget>[];
  var itemy = <Nosic>[]; // vsechny nosice uzivatele
  var vybranyObjekt; // vybrany nosic

  void ziskejNosice() {
    widget.c.ziskatNosice().then((nosice) {
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
    widget.c.validateCookie().then((valid) {
      if (!valid)
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (ctx) => Prihlaseni(c: widget.c)));
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
                          builder: (ctx) => NakupVybratKategorii(
                              nosicId: vybranyObjekt, c: widget.c)));
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
