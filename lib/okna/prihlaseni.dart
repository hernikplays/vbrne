import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../communication.dart';
import 'domov.dart';

class Prihlaseni extends StatefulWidget {
  Prihlaseni({Key? key, required this.c}) : super(key: key);

  final Communicator c;

  @override
  _PrihlaseniState createState() => _PrihlaseniState();
}

class _PrihlaseniState extends State<Prihlaseni> {
  final TextEditingController _mailcontroller = TextEditingController();
  final TextEditingController _passcontroller = TextEditingController();
  bool rememberChecked = false;

  @override
  void initState() {
    super.initState();
    widget.c.ziskejUdaje().then((value) async {
      if (value != null) {
        // jsou uložené údaje

        var connectivityResult = await (Connectivity().checkConnectivity());
        if (connectivityResult == ConnectivityResult.none) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Nastala chyba při kontaktování serveru, zkontrolujte připojení"),
            ),
          );
        }

        var result = await widget.c
            .login(value["mail"]!, value["pass"]!, rememberChecked);
        print("aa");
        print(widget.c.cookie == null);
        if (result == false) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Nepodařilo se přihlásit, zkontrolujte správnost údajů a stav BRNOiD."),
            ),
          );
        } else {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (ctx) => MainPage(
                        c: widget.c,
                      )));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Přihlášení")),
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

                    var result = await widget.c.login(_mailcontroller.text,
                        _passcontroller.text, rememberChecked);
                    if (result == false) {
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
                              builder: (ctx) => MainPage(c: widget.c)));
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
