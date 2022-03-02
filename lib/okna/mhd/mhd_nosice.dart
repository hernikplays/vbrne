import 'package:flutter/material.dart';
import 'package:vbrne/communication.dart';
import 'package:vbrne/okna/prihlaseni.dart';

class NosicePage extends StatefulWidget {
  NosicePage({Key? key, required this.c}) : super(key: key);

  final Communicator c;

  @override
  _NosicePage createState() => _NosicePage();
}

class _NosicePage extends State<NosicePage> {
  final content = <Widget>[
    Center(
      child: CircularProgressIndicator(
        color: Colors.redAccent,
      ),
    )
  ];

  @override
  void initState() {
    super.initState();
    widget.c.validateCookie().then((valid) {
      if (!valid)
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (ctx) => Prihlaseni(c: widget.c)));

      widget.c.ziskatNosice().then((nosice) {
        content.clear();
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
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        child: DefaultTextStyle(
          child: Column(
              children: content, crossAxisAlignment: CrossAxisAlignment.center),
          style: TextStyle(
              fontSize: 18.0, color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
    );
  }
}
