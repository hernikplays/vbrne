import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Komunikátor s webem
class Communicator {
  String? _cookie;
  Communicator();
  String? get cookie => _cookie;

  /// Ověří, zda cookie je platný a funguje
  Future<bool> validateCookie() async {
    var req =
        http.Request('GET', Uri.parse("https://www.brnoid.cz/cs/muj-ucet"));
    req.followRedirects = false;
    req.headers['Cookie'] = this.cookie!;
    var res = await req.send();
    if (res.statusCode == 302)
      return false;
    else
      return true;
  }

  Future<Map<String, String>?> ziskejUdaje() async {
    // zkontrolovat secure storage pokud je něco uložené
    final storage = new FlutterSecureStorage();
    var mail = await storage.read(key: "vbrne_user");
    var pass = await storage.read(key: "vbrne_pass");
    if (mail == null || pass == null) return null;
    return {"mail": mail, "pass": pass};
  }

  /// Získá nosiče z [Moje nosiče](https://www.brnoid.cz/cs/moje-nosice)
  Future<List<Nosic>> ziskatNosice() async {
    var nosice = <Nosic>[];

    var res = await http.get(Uri.parse("https://www.brnoid.cz/cs/moje-nosice"),
        headers: {HttpHeaders.cookieHeader: this.cookie!}); // ziskame stranku
    var vsechnyNosice =
        RegExp(r'<tr>.+?(?=<\/tr>)', dotAll: true).allMatches(res.body).skip(1);
    for (var nosic in vsechnyNosice) {
      var s = nosic.group(0).toString();
      var id = RegExp(r'(?<=for=").+?(?=")')
          .firstMatch(s)!
          .group(0)
          .toString(); // ziska ID nosice

      var panPlatnost = RegExp(r'(?<=italic">).+?(?=<)')
          .allMatches(s)
          .toList(); // ziska odhalenou cast cisla karty + zadanou platnost
      var cislo = panPlatnost[0].group(0).toString();
      var platiDo = panPlatnost[1].group(0).toString();

      var nosicCislo = RegExp(r'(?<=">).+?(?=<\/label)')
          .firstMatch(s)!
          .group(0)
          .toString(); // Nosič č. X

      var n =
          Nosic(id: id, platiDo: platiDo, cislo: cislo, nosicCislo: nosicCislo);
      nosice.add(n);
    }
    return nosice;
  }

  /// Přihlášení
  Future<bool> login(String user, String pass, bool remember) async {
    if (user.isEmpty || pass.isEmpty) return false;
    try {
      var res = await http.post(Uri.parse('https://www.brnoid.cz/cs/overeni'),
          body: {'email': user, 'password': pass, 'SubmitLogin': ""});
      if (res.headers['location'] != "https://www.brnoid.cz/cs/muj-ucet") {
        // v případě špatného hesla
        return false;
      }
      var cookie = res.headers['set-cookie'];
      if (remember) {
        // save username and password
        final storage = new FlutterSecureStorage();
        await storage.write(key: 'vbrne_user', value: user);
        await storage.write(key: 'vbrne_pass', value: pass);
      }
      this._cookie = cookie;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Jizdenka>?> ziskejJizdenky() async {
    var c = false;
    var jizdenky = <Jizdenka>[];
    var res = await http.get(
        Uri.parse("https://www.brnoid.cz/cs/moje-jizdenky"),
        headers: {HttpHeaders.cookieHeader: this.cookie!}).catchError((err) {
      print(err);
      c = true;
    });
    if (res.statusCode >= 400 || c) {
      // CHYBA
      print("chyba");
      return null;
    }
    var jizdenkyTable =
        RegExp(r"<tr>.+?(?=\/tr)", dotAll: true).allMatches(res.body);
    if (jizdenkyTable.length == 1) {
      return [];
    }
    for (var jizdenka in jizdenkyTable.skip(1)) {
      var r = jizdenka.group(0).toString();

      var najitJmeno = RegExp(r"(?=<strong>).+?(?=<\/strong)", dotAll: true)
          .allMatches(r)
          .toList();
      var jmeno = najitJmeno[0].group(0).toString().replaceAll("<strong>", "");
      var nosic = najitJmeno[1].group(0).toString().replaceAll("<strong>", "");

// TODO: filtrovat neplatne jizdenky
      var platnost = RegExp(r'(?=<div class="label).+?(?=<\/div)')
          .firstMatch(r)!
          .group(0)
          .toString()
          .replaceAll(RegExp(r'<div class="label .+">'), "");
      //if (platnost == "Neaktivn&iacute;") continue;

      var platiOdDo = RegExp(r'(?=<span).+?(?=<\/span)', dotAll: true)
          .allMatches(r)
          .toList();
      var platiOd =
          "${platiOdDo[0].group(0).toString().replaceAll(RegExp(r'<span.+>'), "")}, ${platiOdDo[1].group(0).toString().replaceAll(RegExp(r'<span.+>'), "")}";
      var platiDo =
          "${platiOdDo[2].group(0).toString().replaceAll(RegExp(r'<span.+>'), "")}, ${platiOdDo[3].group(0).toString().replaceAll(RegExp(r'<span.+>'), "")}";

      // předělat "platiDo" na DateTime
      var platiDoSplit = platiDo.split(r" ");

      var platiDoDen = platiDoSplit[0].replaceAll(".", "");
      platiDoDen =
          ((int.parse(platiDoDen)) < 10) ? "0" + platiDoDen : platiDoDen;

      var platiDoMesic = platiDoSplit[1].replaceAll(".", "");
      platiDoMesic =
          ((int.parse(platiDoMesic)) < 10) ? "0" + platiDoMesic : platiDoMesic;

      var platiDoRok = platiDoSplit[2].replaceAll(",", "");

      var platiDoDate = DateTime.parse(
          "$platiDoRok-$platiDoMesic-$platiDoDen ${platiDoSplit[3]}:00");

      // předělat "platiOd" na DateTime
      var platiOdSplit = platiOd.split(r" ");

      var platiOdDen = platiOdSplit[0].replaceAll(".", "");
      platiOdDen =
          ((int.parse(platiOdDen)) < 10) ? "0" + platiOdDen : platiOdDen;

      var platiOdMesic = platiOdSplit[1].replaceAll(".", "");
      platiOdMesic =
          ((int.parse(platiOdMesic)) < 10) ? "0" + platiOdMesic : platiOdMesic;

      var platiOdRok = platiOdSplit[2].replaceAll(",", "");

      var platiOdDate = DateTime.parse(
          "$platiOdRok-$platiOdMesic-$platiOdDen ${platiOdSplit[3]}:59");

      nosic =
          "$nosic - ${platiOdDo[4].group(0).toString().replaceAll(RegExp(r'<span.+>'), "")}";

      var cena =
          RegExp(r"[0-9,]+ Kč(?=<\/div)").firstMatch(r)!.group(0).toString();

      jizdenky.add(Jizdenka(
          cena: cena,
          platiOd: platiOdDate,
          platiDo: platiDoDate,
          nosic: nosic,
          nazev: jmeno,
          platiTed: (platnost == "Neaktivn&iacute;") ? false : true));
    }
    return jizdenky;
  }
}

/// Představuje nosič
class Nosic {
  /// Unikátní ID nosiče
  final String id;

  /// Platnost nosiče
  final String platiDo;

  /// Číslo karty
  final String cislo;

  /// Nosič č. X
  final String nosicCislo;

  Nosic(
      {required this.id,
      required this.platiDo,
      required this.cislo,
      required this.nosicCislo});
}

class Jizdenka {
  /// Začátek platnosti
  final DateTime platiOd; // TODO: Převést na DateTime

  /// Konec platnosti
  final DateTime platiDo; // TODO: Převést na DateTime

  /// Cena za jízdenku
  final String cena;

  /// Název jízdenky
  final String nazev;

  /// Identifikator nosiče, na kterém je jízdenka
  final String nosic;

  /// Udává, jestli jízdenka je v moment vytvoření instance platná
  final bool platiTed;

  Jizdenka(
      {required this.platiOd,
      required this.platiDo,
      required this.cena,
      required this.nazev,
      required this.nosic,
      required this.platiTed});
}
