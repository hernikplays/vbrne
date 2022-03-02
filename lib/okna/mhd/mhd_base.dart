import 'package:flutter/material.dart';
import 'package:vbrne/communication.dart';
import 'package:vbrne/okna/mhd/mhd_home.dart';

import '../domov.dart';
import 'mhd_nosice.dart';
import 'nakup/nakup_nosic.dart';

enum Cast { JIZDENKY, NOSICE, REVIZOR }
Cast selection = Cast.JIZDENKY;

class MHDBase extends StatefulWidget {
  MHDBase({Key? key, required this.c}) : super(key: key);

  final Communicator c;

  @override
  _MHDBaseState createState() => _MHDBaseState();
}

class _MHDBaseState extends State<MHDBase> {
  var content = <Widget>[];
  var title = "Jízdenky";

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (selection) {
      case Cast.JIZDENKY:
        body = MHDMain(c: widget.c);
        break;
      /*case Cast.REVIZOR:
        body = NakupVyberNosic(c: widget.c);
        break;*/
      case Cast.NOSICE:
        body = NosicePage(c: widget.c);
        break;
      default:
        body = MHDMain(c: widget.c);
        break;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("MHD"),
      ),
      body: body,
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
              selectedColor: Colors.redAccent,
            ),
            ListTile(
                selected: selection == Cast.JIZDENKY,
                title: Text(
                  "Jízdenky",
                ),
                onTap: () {
                  setState(() {
                    selection = Cast.JIZDENKY;
                    Navigator.pop(context);
                  });
                },
                leading: Icon(Icons.list),
                selectedColor: Colors.redAccent),
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
                leading: Icon(Icons.assignment_ind),
                selectedColor: Colors.redAccent),
            ListTile(
                title: Text("Mé nosiče"),
                onTap: () {
                  setState(() {
                    selection = Cast.NOSICE;
                    Navigator.pop(context);
                  });
                },
                selected: selection == Cast.NOSICE,
                leading: Icon(Icons.credit_card),
                selectedColor: Colors.redAccent)
          ],
        ),
      ),
    );
  }
}
