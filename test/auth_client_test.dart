import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_token_auth/flutter_token_auth.dart';
import 'package:flutter_token_auth/src/client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final config = AuthConfig(appURL: 'https://example.test');
  final httpClient = MockClient((request) async {
    return http.Response('{}', 200);
  });
  late User user;

  group('AuthClient', () {
    late AuthClient client;
    setUp(() {
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
    });
  });
}
