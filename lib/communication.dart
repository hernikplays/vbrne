import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Komunikátor s webem
class Communicator {
  /// Ověří, zda cookie je platný a funguje
  static Future<bool> validateCookie(String cookie) async {
    var req =
        http.Request('GET', Uri.parse("https://www.brnoid.cz/cs/muj-ucet"));
    req.followRedirects = false;
    req.headers['Cookie'] = cookie;
    var res = await req.send();
    if (res.statusCode == 302)
      return false;
    else
      return true;
  }

  /// Získá nosiče z [Moje nosiče](https://www.brnoid.cz/cs/moje-nosice)
  static Future<List<Nosic>> ziskatNosice(String cookie) async {
    var nosice = <Nosic>[];

    var res = await http.get(Uri.parse("https://www.brnoid.cz/cs/moje-nosice"),
        headers: {HttpHeaders.cookieHeader: cookie}); // ziskame stranku
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
  static Future<String?> login(String user, String pass, bool remember) async {
    if (user.length == 0 || pass.length == 0) return null;
    var error = false;
    var res = await http.post(Uri.parse('https://www.brnoid.cz/cs/overeni'),
        body: {
          'email': user,
          'password': pass,
          'SubmitLogin': ""
        }).catchError((error) {
      error = true;
    });
    if (error) return null;
    if (res.headers['location'] != "https://www.brnoid.cz/cs/muj-ucet") {
      // v případě špatného hesla
      return null;
    }
    var cookie = res.headers['set-cookie'];
    if (remember) {
      // save username and password
      final storage = new FlutterSecureStorage();
      await storage.write(key: 'vbrne_user', value: user);
      await storage.write(key: 'vbrne_pass', value: pass);
    }
    return cookie;
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
