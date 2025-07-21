import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:flutter_token_auth/flutter_token_auth.dart';

void main() {
  group('Response Class Testing', () {
    test('should create Response from data', () {
      final response = http.Response('{"test": true}', 200);

      expect(response.statusCode, equals(200));
      expect(response.body, equals('{"test": true}'));
      expect(response.success, isTrue);
      expect(response.jsonBody['test'], isTrue);
    });

    test('should handle different status codes', () {
      final successResponse = http.Response('{}', 201);
      final errorResponse = http.Response('Error', 400);

      expect(successResponse.success, isTrue);
      expect(errorResponse.success, isFalse);
    });
  });
}
