import 'dart:convert';

import 'package:http/http.dart' as http;

class Response {
  Response({required this.body, required this.statusCode});

  factory Response.fromHttpResponse(http.Response response) {
    return Response(body: response.body, statusCode: response.statusCode);
  }

  int statusCode;
  String body;

  bool get success => statusCode >= 200 && statusCode <= 299;

  dynamic get jsonBody => json.decode(body);
}
