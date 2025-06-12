import 'package:test/test.dart';
import 'package:flutter_token_auth/token_auth.dart';

void main() {
  group('FakeAuthManager', () {
    late FakeAuthManager fakeAuth;
    setUp(() {
      fakeAuth = FakeAuthManager(clear: true);
    });

    test('should use FakeAuthManager for testing', () {
      final fakeAuth = FakeAuthManager(withLoggedInUser: true);
      expect(fakeAuth.currentUser, isNotNull);
      expect(fakeAuth.currentUser!.isSignedIn, isTrue);
    });
    test('should track login calls with FakeAuthManager', () async {
      final fakeAuth = FakeAuthManager(clear: true);
      fakeAuth.allowLogin = true;

      final user = await fakeAuth.login('test@example.com', 'password123');

      expect(fakeAuth.timesLoginCalled, equals(1));
      expect(fakeAuth.loginCalledWith['email'], equals('test@example.com'));
      expect(user, isNotNull);
    });

    test('should track createAccount calls with FakeAuthManager', () async {
      final fakeAuth = FakeAuthManager(clear: true);
      fakeAuth.allowLogin = true;

      final user = await fakeAuth.createAccount(
        email: 'new@example.com',
        password: 'password123',
        name: 'New User',
      );

      expect(fakeAuth.timesCreateAccountCalled, equals(1));
      expect(
        fakeAuth.createAccountCalledWith['email'],
        equals('new@example.com'),
      );
      expect(fakeAuth.createAccountCalledWith['name'], equals('New User'));
      expect(user, isNotNull);
      expect(user!.name, equals('New User'));
    });

    test('should track changePassword calls with FakeAuthManager', () async {
      final fakeAuth = FakeAuthManager(withLoggedInUser: true);

      await fakeAuth.changePassword(password: 'newpassword');

      expect(fakeAuth.methodCounters['changePassword'].timesCalled, equals(1));
      expect(
        fakeAuth.methodCounters['changePassword'].params.first['password'],
        equals('newpassword'),
      );
    });

    test('should handle checkLoggedIn with FakeAuthManager', () async {
      final fakeAuth = FakeAuthManager(withLoggedInUser: true);

      final isLoggedIn = await fakeAuth.checkLoggedIn();
      expect(isLoggedIn, isTrue);
    });

    test('should handle userMustBeLoggedIn with FakeAuthManager', () {
      final fakeAuth = FakeAuthManager(withLoggedInUser: true);

      expect(fakeAuth.userMustBeLoggedIn(), isTrue);
    });

    test('should handle failed login attempts', () async {
      expect(
        () => fakeAuth.login('test@example.com', 'wrongpassword'),
        throwsUnimplementedError,
      );
    });

    test('should clear state properly', () {
      final fakeAuth = FakeAuthManager(clear: false, withLoggedInUser: true);

      expect(fakeAuth.currentUser, isNotNull);
      expect(fakeAuth.timesLoginCalled, greaterThanOrEqualTo(0));

      fakeAuth.clear();

      expect(fakeAuth.currentUser, isNull);
      expect(fakeAuth.timesLoginCalled, equals(0));
      expect(fakeAuth.allowLogin, isFalse);
    });

    group('User Class Integration', () {
      test('should get current user from AuthManager', () {
        FakeAuthManager(withLoggedInUser: true);
        final currentUser = User.currentUser;

        expect(currentUser, isNotNull);
        expect(currentUser.isSignedIn, isTrue);
      });

      test('should handle user login method', () async {
        fakeAuth.allowLogin = true;

        final user = User(email: 'test@example.com');
        final loggedInUser = await user.login('password123');

        expect(loggedInUser, isNotNull);
        expect(fakeAuth.timesLoginCalled, equals(1));
      });

      test('should handle user createAccount method', () async {
        fakeAuth.allowLogin = true;

        final user = User(email: 'new@example.com', name: 'New User');
        final createdUser = await user.createAccount('password123');

        expect(createdUser, isNotNull);
        expect(fakeAuth.timesCreateAccountCalled, equals(1));
      });

      test('should handle user changePassword method', () async {
        final fakeAuth = FakeAuthManager(withLoggedInUser: true);

        final user = User.currentUser;
        final updatedUser = await user.changePassword('newpassword');

        expect(updatedUser, isNotNull);
        expect(
          fakeAuth.methodCounters['changePassword'].timesCalled,
          equals(1),
        );
      });
    });
  });
}
