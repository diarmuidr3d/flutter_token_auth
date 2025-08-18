import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_token_auth/flutter_token_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final config = AuthConfig(appURL: 'https://example.test');
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
  });
}
