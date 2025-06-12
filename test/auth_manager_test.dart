import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_token_auth/flutter_token_auth.dart' hide Response;
import 'package:http/http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:flutter_token_auth/src/auth_config.dart';
import 'package:flutter_token_auth/src/auth_manager.dart';

void main() {
  group('AuthManager Tests', () {
    late AuthConfig config;

    group('with config', () {
      setUpAll(() {
        TestWidgetsFlutterBinding.ensureInitialized();
        FlutterSecureStorage.setMockInitialValues({});
      });

      setUp(() {
        config = AuthConfig(appURL: 'test.example.com');
        AuthManager(config: config);
      });

      tearDown(() async {
        await AuthManager().clear();
      });

      test('should create AuthManager with config', () {
        final authManager = AuthManager(config: config);
        expect(authManager, isNotNull);
      });

      test('should return same instance (singleton pattern)', () {
        final authManager1 = AuthManager(config: config);
        final authManager2 = AuthManager();
        expect(authManager1, equals(authManager2));
      });

      test(
        'should return null for currentUser when not logged in initially',
        () {
          expect(AuthManager().currentUser, isNull);
        },
      );

      test('should have correct default headers', () {
        expect(
          AuthManager.defaultHeaders['content-type'],
          equals('application/json'),
        );
        expect(
          AuthManager.defaultHeaders['accept'],
          equals('application/json'),
        );
      });

      group('login', () {
        late MockClient httpClient;
        setUp(() {
          httpClient = MockClient((request) async {
            return Response(
              json.encode({
                'data': {
                  'email': 'test@example.com',
                  'name': 'Test User',
                  'app_id': 123,
                  'id': 456,
                },
              }),
              200,
              headers: {
                'content-type': 'application/json',
                'access-token': '123access-token',
                'client': '456client',
                'uid': '789uid',
              },
            );
          });
          AuthManager(httpClient: httpClient, config: config);
        });

        test('should login a user', () async {
          final user = await AuthManager().login(
            'test@example.com',
            'password',
          );
          expect(user, isNotNull);
          expect(user!.isSignedIn, isTrue);
          expect(user.email, equals('test@example.com'));
          expect(user.name, equals('Test User'));
          expect(user.appId, equals(123));
          expect(user.id, equals(456));
          expect(user.accessToken, equals('123access-token'));
          expect(user.client, equals('456client'));
          expect(user.uid, equals('789uid'));
          // Avoids race condition with clear()
          await AuthManager().writeKeysToStore();
        });

        test('logged in user is stored in local storage', () async {
          await AuthManager().login('test@example.com', 'password');
          final loadedUser = await AuthManager().loadFromStorage();
          expect(loadedUser, isNotNull);
          expect(loadedUser!.isSignedIn, isTrue);
          expect(loadedUser.email, equals('test@example.com'));
          expect(loadedUser.appId, equals(123));
          expect(loadedUser.accessToken, equals('123access-token'));
          expect(loadedUser.client, equals('456client'));
          expect(loadedUser.uid, equals('789uid'));
        });

        group('with custom app id key', () {
          late MockClient httpClient;
          setUp(() {
            config = AuthConfig(
              appURL: 'test.example.com',
              appIdKey: 'farm_id',
            );
            httpClient = MockClient((request) async {
              return Response(
                json.encode({
                  'data': {
                    'email': 'test@example.com',
                    'name': 'Test User',
                    'farm_id': 123,
                    'id': 456,
                  },
                }),
                200,
                headers: {
                  'content-type': 'application/json',
                  'access-token': '123access-token',
                  'client': '456client',
                  'uid': '789uid',
                },
              );
            });
            AuthManager(httpClient: httpClient, config: config);
          });

          test('should login a user', () async {
            final user = await AuthManager().login(
              'test@example.com',
              'password',
            );
            expect(user, isNotNull);
            expect(user!.isSignedIn, isTrue);
            expect(user.appId, equals(123));
            // Avoids race condition with clear()
            await AuthManager().writeKeysToStore();
          });

          test('logged in user is stored in local storage', () async {
            await AuthManager().login('test@example.com', 'password');
            final loadedUser = await AuthManager().loadFromStorage();
            expect(loadedUser, isNotNull);
            expect(loadedUser!.isSignedIn, isTrue);
            expect(loadedUser.email, equals('test@example.com'));
            expect(loadedUser.appId, equals(123));
            expect(loadedUser.accessToken, equals('123access-token'));
            expect(loadedUser.client, equals('456client'));
            expect(loadedUser.uid, equals('789uid'));
          });
        });
      });

      group('addAppToUrl', () {
        setUp(() {
          AuthManager(config: config).user = MockUser(appId: 123);
        });

        test('should add app id to url', () async {
          final url = Uri.parse('https://test.example.com/auth/sign_in');
          final newUrl = AuthManager().addAppToUrl(url);
          expect(newUrl.queryParameters['app_id'], equals('123'));
        });

        group('with custom app id key', () {
          setUp(() {
            config = AuthConfig(
              appURL: 'test.example.com',
              appIdKey: 'farm_id',
            );
            AuthManager(config: config).user = MockUser(appId: 123);
          });

          test('should add app id to url', () async {
            final url = Uri.parse('https://test.example.com/auth/sign_in');
            final newUrl = AuthManager().addAppToUrl(url);
            expect(newUrl.queryParameters['farm_id'], equals('123'));
          });
        });
      });

      group('Error Handling and Authentication State', () {
        test('should return false for validateToken when no user', () async {
          final result = await AuthManager().validateToken();
          expect(result, isFalse);
        });

        test(
          'should validate that user must be logged in for authenticated operations',
          () {
            expect(() => AuthManager().userMustBeLoggedIn(), throwsException);
          },
        );
      });
    });
  });
}
