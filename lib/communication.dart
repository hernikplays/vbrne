import 'package:http/http.dart' as http;

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
}
