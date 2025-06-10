import 'package:test/test.dart';
import 'package:flutter_token_auth/token_auth.dart';

void main() {
  setUp(() {
    AuthManager().replaceForTesting(FakeAuthManager());
    FakeAuthManager().clear();
  });

  group('MockUser', () {
    test('should create mock users with MockUser factory', () {
      final user = MockUser.create();
      expect(user, isNotNull);
      expect(user.email, isNotNull);
      expect(user.isSignedIn, isTrue);
    });

    test('should create mock users with custom parameters', () {
      final user = MockUser.create(
        email: 'custom@example.com',
        name: 'Custom User',
        appId: 999,
      );

      expect(user.email, equals('custom@example.com'));
      expect(user.name, equals('Custom User'));
      expect(user.appId, equals(999));
    });

    test('should generate random values for mock users', () {
      final user1 = MockUser.create();
      final user2 = MockUser.create();

      // Access tokens should be different (randomly generated)
      expect(user1.accessToken, isNot(equals(user2.accessToken)));
      expect(user1.id, isNot(equals(user2.id)));
    });
  });
}
