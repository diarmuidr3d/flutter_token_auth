import 'package:test/test.dart';
import 'package:flutter_token_auth/flutter_token_auth.dart';

void main() {
  group('Response Class Testing', () {
    test('should create Response from data', () {
      final response = Response(body: '{"test": true}', statusCode: 200);

      expect(response.statusCode, equals(200));
      expect(response.body, equals('{"test": true}'));
      expect(response.success, isTrue);
      expect(response.jsonBody['test'], isTrue);
    });

    test('should handle different status codes', () {
      final successResponse = Response(body: '{}', statusCode: 201);
      final errorResponse = Response(body: 'Error', statusCode: 400);

      expect(successResponse.success, isTrue);
      expect(errorResponse.success, isFalse);
    });
  });
}
