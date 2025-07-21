import 'dart:convert';

import 'package:http/http.dart' as http;

extension ResponseExtension on http.Response {
  bool get success => statusCode >= 200 && statusCode <= 299;

  dynamic get jsonBody => json.decode(body);
}
