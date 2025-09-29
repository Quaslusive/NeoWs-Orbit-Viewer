import 'package:http/http.dart' as http;

class Httpx {
  static final http.Client _c = http.Client();
  static http.Client get client => _c;
}

