import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_token_auth/flutter_token_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final config = AuthConfig(appURL: 'example.test');
  final httpClient = MockClient((request) async {
    return http.Response(
      request.body,
      200,
      headers: {
        'access-token': '123access-token',
        'client': '456client',
        'uid': '789uid',
      },
    );
  });
  late User user;

  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
  });

  group('AuthClient', () {
    late AuthClient client;
    setUp(() {
      FakeAuthManager();
      user = MockUser.create();
      client = AuthClient(config: config, httpClient: httpClient);
    });
    group('headers', () {
      test('should have correct default headers', () {
        expect(
          AuthClient.defaultHeaders['content-type'],
          equals('application/json'),
        );
        expect(AuthClient.defaultHeaders['accept'], equals('application/json'));
      });
    });

    group('with logged in user', () {
      setUp(() {
        client.authManager.user = user;
      });

      group('addAppToUrl', () {
        test('should add app id to url', () async {
          final url = Uri.parse('https://test.example.com/auth/sign_in');
          final newUrl = client.addAppToUrl(url);
          expect(
            newUrl.queryParameters['app_id'],
            equals(user.appId.toString()),
          );
        });
      });

      group('post', () {
        test('should send correct body', () async {
          final url = Uri.https('example.test', 'some/path');
          final body = {'email': 'test@example.com'};
          final response = await client.post(url, body: body);
          expect(response.body, equals(jsonEncode(body)));
        });
        test('does not fail for null values', () async {
          final url = Uri.https('example.test', 'some/path');
          final body = {'email': null};
          final response = await client.post(url, body: body);
          expect(response.body, equals(jsonEncode(body)));
        });
        test('should store the response header tokens', () async {
          final url = Uri.https('example.test', 'some/path');
          final body = {'email': 'test@example.com'};
          await client.post(url, body: body);
          expect(
            client.authManager.user!.accessToken,
            equals('123access-token'),
          );
          expect(client.authManager.user!.client, equals('456client'));
          expect(client.authManager.user!.uid, equals('789uid'));
        });
      });
    });

    group('createAccount', () {
      test('should send correct body and handle response', () async {
        final responseBody = jsonEncode({
          'data': {
            'id': 1,
            'email': 'test@example.com',
            'name': 'Test User',
            'app_id': 123,
          },
        });
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(
            request.url.toString(),
            equals(config.createAccountUrl.toString()),
          );
          expect(
            request.body,
            equals(
              jsonEncode({
                'email': 'test@example.com',
                'password': 'password123',
                'password_confirmation': 'password123',
                'name': 'Test User',
              }),
            ),
          );
          return http.Response(
            responseBody,
            200,
            headers: {
              'access-token': '123access-token',
              'client': '456client',
              'uid': '789uid',
            },
          );
        });
        final client = AuthClient(config: config, httpClient: mockClient);
        final user = await client.createAccount(
          email: 'test@example.com',
          password: 'password123',
          name: 'Test User',
        );
        expect(user, isNotNull);
        expect(user!.email, equals('test@example.com'));
        expect(user.name, equals('Test User'));
        expect(user.accessToken, equals('123access-token'));
        expect(user.client, equals('456client'));
        expect(user.uid, equals('789uid'));
      });

      test('should throw exception for non-200 status code', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Error', 400);
        });
        final client = AuthClient(config: config, httpClient: mockClient);
        expect(
          () async => await client.createAccount(
            email: 'test@example.com',
            password: 'password123',
            name: 'Test User',
          ),
          throwsException,
        );
      });
    });

    group('login', () {
      test('should send correct body and handle response', () async {
        final responseBody = jsonEncode({
          'data': {
            'id': 1,
            'email': 'test@example.com',
            'name': 'Test User',
            'app_id': 123,
          },
        });
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.url.toString(), equals(config.signInUrl.toString()));
          expect(
            request.body,
            equals(
              jsonEncode({
                'email': 'test@example.com',
                'password': 'password123',
              }),
            ),
          );
          return http.Response(
            responseBody,
            200,
            headers: {
              'access-token': '123access-token',
              'client': '456client',
              'uid': '789uid',
            },
          );
        });
        final client = AuthClient(config: config, httpClient: mockClient);
        final user = await client.login('test@example.com', 'password123');
        expect(user, isNotNull);
        expect(user!.email, equals('test@example.com'));
        expect(user.name, equals('Test User'));
        expect(user.accessToken, equals('123access-token'));
        expect(user.client, equals('456client'));
        expect(user.uid, equals('789uid'));
      });

      test('should throw exception for non-200 status code', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Error', 400);
        });
        final client = AuthClient(config: config, httpClient: mockClient);
        expect(
          () async => await client.login('test@example.com', 'password123'),
          throwsException,
        );
      });
    });
  });
}
