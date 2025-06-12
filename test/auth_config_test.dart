import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_token_auth/flutter_token_auth.dart';

void main() {
  late AuthConfig config;
  group('AuthConfig', () {
    setUp(() {
      config = AuthConfig(appURL: 'test.example.com');
    });
    group('AuthConfig URL Generation', () {
      test('should generate correct URLs from config', () {
        expect(
          config.signInUrl.toString(),
          equals('https://test.example.com/auth/sign_in'),
        );
        expect(
          config.signOutUrl.toString(),
          equals('https://test.example.com/auth/sign_out'),
        );
        expect(
          config.validateTokenUrl.toString(),
          equals('https://test.example.com/auth/validate_token'),
        );
        expect(
          config.passwordUrl.toString(),
          equals('https://test.example.com/auth/password'),
        );
        expect(
          config.createAccountUrl.toString(),
          equals('https://test.example.com/auth/'),
        );
      });

      test('should handle custom paths', () {
        final customConfig = AuthConfig(
          appURL: 'api.example.com',
          path: '/v1/auth',
          signInPath: '/login',
          createAccountPath: '/register',
        );

        expect(
          customConfig.signInUrl.toString(),
          equals('https://api.example.com/v1/auth/login'),
        );
        expect(
          customConfig.createAccountUrl.toString(),
          equals('https://api.example.com/v1/auth/register'),
        );
      });

      test('should handle custom app id key', () {
        final customConfig = AuthConfig(
          appURL: 'api.example.com',
          appIdKey: 'farm_id',
        );

        expect(customConfig.appIdKey, equals('farm_id'));
      });
    });
  });
}
