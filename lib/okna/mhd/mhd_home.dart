import 'package:flutter/material.dart';
import 'package:vbrne/communication.dart';
import 'package:vbrne/okna/prihlaseni.dart';

class MHDMain extends StatefulWidget {
  MHDMain({Key? key, required this.c}) : super(key: key);

  final Communicator c;

  @override
  _MHDMainState createState() => _MHDMainState();
}

class _MHDMainState extends State<MHDMain> {
  final content = <Widget>[
    Center(
      child: CircularProgressIndicator(
        color: Colors.redAccent,
      ),
    )
  ];
  var title = "Jízdenky";
  @override
  void initState() {
    super.initState();
    widget.c.validateCookie().then((result) {
      content.clear();
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
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        child: DefaultTextStyle(
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 18, color: Theme.of(context).colorScheme.onPrimary),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: content,
          ),
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
                    (listek.platiTed == Platnost.PLATI)
                        ? Text("Platí",
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold))
                        : (listek.platiTed == Platnost.PRED)
                            ? Text("Bude platit",
                                style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold))
                            : Text("Neplatí",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold))
                  ],
                ),
                style: TextStyle(
                    fontSize: 18.0,
                    color: Theme.of(context).colorScheme.onPrimary),
              )),
        ));
        content.add(Divider(
            thickness: 2,
            height: 40,
            color: Theme.of(context).colorScheme.onBackground));
      }
    }
    return content;
  }
}
