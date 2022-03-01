import 'package:flutter/material.dart';
import 'package:vbrne/communication.dart';
import 'package:vbrne/okna/prihlaseni.dart';

import '../domov.dart';
import 'mhd_nosice.dart';
import 'nakup/nakup_nosic.dart';

class MHDMain extends StatefulWidget {
  MHDMain({Key? key, required this.c}) : super(key: key);

  final Communicator c;

  @override
  _MHDMainState createState() => _MHDMainState();
}

class _MHDMainState extends State<MHDMain> {
  var content = <Widget>[];
  var title = "Jízdenky";
  @override
  void initState() {
    super.initState();
    widget.c.validateCookie().then((result) {
      if (!result) {
        // nefunkční cookie
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (buildContext) => Prihlaseni(c: widget.c),
          ),
        );
      } else {
        vemListky(context, widget.c.cookie!).then((value) {
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
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (ctx) => MainPage(c: widget.c)));
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
                          builder: (ctx) => NakupVyberNosic(c: widget.c)));
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

  Future<List<Widget>> vemListky(context, cookie) async {
    var content = <Widget>[];
    var listky = await widget.c.ziskejJizdenky();
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
                    (listek.platiTed)
                        ? Text("Platí", style: TextStyle(color: Colors.green))
                        : Text("Neplatí", style: TextStyle(color: Colors.red))
                  ],
                ),
                style: TextStyle(fontSize: 18.0, color: Colors.black),
              )),
        ));
      }
    }
    return content;
  }
}
