import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vbrne/communication.dart';
import 'package:vbrne/okna/prihlaseni.dart';

import '../../domov.dart';
import '../mhd_home.dart';
import '../mhd_nosice.dart';

class NakupVybratJizdenku extends StatefulWidget {
  // zde vybereme kategorii
  NakupVybratJizdenku(
      {Key? key,
      required this.nosicId,
      required this.kategorie,
      required this.c})
      : super(key: key);

  final String nosicId;
  final String kategorie;
  final Communicator c;

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
  var vyberZon = <Row>[];
  var zonyNavic = <String?>[];

  @override
  void initState() {
    super.initState();
    widget.c.validateCookie().then((valid) {
      if (!valid)
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (ctx) => Prihlaseni(c: widget.c)));
    });

    // získáme kategorie
    ziskejJizdenky();
  }

  void ziskejJizdenky() {
    http.get(
        Uri.parse(
            "https://www.brnoid.cz/cs/koupit-jizdenku-ids?controller=buy-ticket-ids&customer_token=${widget.nosicId.replaceAll("token_", "")}&id_category=17&id_subcategory=${widget.kategorie}#select-category"),
        headers: {HttpHeaders.cookieHeader: widget.c.cookie!}).then((res) {
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

  void pridejZonu(id, sourceZona, List<String> except) {
    var data = Map<String, dynamic>();
    data["ajax"] = "1";
    data["action"] = "get_neighbouring_zones";
    data["id_product"] = id;
    data["source"] = sourceZona;
    data["except"] = except.join(";");
    http.post(Uri.parse("https://www.brnoid.cz/cs/koupit-jizdenku-ids"),
        body: data,
        headers: {HttpHeaders.cookieHeader: widget.c.cookie!}).then((res) {
      print(res.body);
      var r = res.body.replaceAll(RegExp(r'("|\[|\])'), "").split(",");
      print(r[0]);
    });
  }

  Future<void> ziskejZony(id, pocetZon) async {
    vyberZon = [];
    var res = await http.get(
        Uri.parse(
            "https://www.brnoid.cz/cs/koupit-jizdenku-ids?controller=buy-ticket-ids&customer_token=${widget.nosicId.replaceAll("token_", "")}&id_category=17&id_subcategory=${widget.kategorie}&id_product=$id#select-validity"),
        headers: {HttpHeaders.cookieHeader: widget.c.cookie!});
    var inputMatcher = RegExp(
        r'(?<=name="zones\[3\]">).+(?=<\/select>)'); // tímto získáme možnosti pro 3. zónu, od které se pak odpíchneme k další
    var optionMatcher =
        RegExp(r'(?<=value=")\d+'); // tímto získáme každou zónu zvlášť
    var itemy = <DropdownMenuItem<String>>[];

    var options = inputMatcher.firstMatch(res.body)!.group(0).toString();

    var zony = optionMatcher.allMatches(options).toList();
    for (var zona in zony) {
      var z = zona.group(0).toString();
      print(z);
      itemy.add(DropdownMenuItem<String>(child: Text(z), value: z));
    }

    vyberZon.add(Row(children: [
      Text(
        "3. zóna: ",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      DropdownButton(
          items: itemy,
          onChanged: (newValue) {
            var vybrana = newValue!.toString();
            if (zonyNavic.isEmpty) {
              zonyNavic.add(vybrana);
            } else {
              zonyNavic[0] = vybrana;
            }
            pridejZonu(id, vybrana, [vybrana]);
            setState(() {});
          },
          value: (zonyNavic.isEmpty) ? null : zonyNavic[0])
    ], mainAxisAlignment: MainAxisAlignment.center));
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
                    items: (itemy.isEmpty) ? null : itemy,
                    value: vybranyObjekt,
                    icon: Icon(Icons.confirmation_number_rounded),
                    isExpanded: true,
                    onChanged: (newValue) async {
                      var newName = itemy.firstWhere((element) {
                        if (element.value == newValue) {
                          return true;
                        } else
                          return false;
                      });
                      await ziskejZony(
                          newValue,
                          RegExp(r'\+\d zón')
                              .firstMatch(newName.child.toString())!
                              .group(0)
                              .toString()
                              .replaceAll(" zón", ""));
                      setState(() {
                        if (newName.child
                            .toString()
                            .contains(RegExp(r'\+\d zón'))) {
                          vybiratZony = true;
                        } else
                          vybiratZony = false;
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
                      ...vyberZon
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
