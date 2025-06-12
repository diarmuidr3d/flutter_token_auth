import 'package:http/http.dart' as http;
import 'package:flutter_token_auth/flutter_token_auth.dart';

import 'method_counters.dart';

class FakeAuthManager implements AuthManager {
  static final FakeAuthManager _authManager = FakeAuthManager._new();
  @override
  late AuthConfig config;

  FakeAuthManager._new();

  factory FakeAuthManager({
    AuthConfig? config = const AuthConfig(appURL: 'https://example.test'),
    bool clear = true,
    bool withLoggedInUser = false,
  }) {
    AuthManager(config: config).replaceForTesting(_authManager);
    if (clear) _authManager.clear();
    if (withLoggedInUser) {
      _authManager.user = MockUser.create();
      _authManager.allowLogin = true;
    }
    return _authManager;
  }

  User? user;

  bool allowLogin = false;
  int timesLoginCalled = 0;
  Map<String, String> loginCalledWith = {};
  int timesCreateAccountCalled = 0;
  Map<String, String> createAccountCalledWith = {};

  MethodCounters methodCounters = MethodCounters();

  @override
  Future<void> clear() async {
    user = null;
    allowLogin = false;
    timesLoginCalled = 0;
    loginCalledWith = {};
    timesCreateAccountCalled = 0;
    createAccountCalledWith = {};
    methodCounters.clear();
  }

  @override
  Uri addAppToUrl(Uri url, {Map<String, dynamic>? queryParams}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> checkLoggedIn() async {
    if (allowLogin) {
      if (user == null) return false;
      return user!.isSignedIn;
    }
    throw UnimplementedError();
  }

  @override
  get currentUser => user;

  @override
  Future<Response> get(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) {
    throw UnimplementedError();
  }

  @override
  handleResponse(http.Response response) {
    throw UnimplementedError();
  }

  @override
  Future<User?> loadFromStorage() {
    throw UnimplementedError();
  }

  @override
  Future<User?> login(String email, String password) async {
    timesLoginCalled++;
    loginCalledWith = {'email': email, 'password': password};
    if (allowLogin) {
      user = MockUser.create(email: email);
      return user;
    }
    throw UnimplementedError();
  }

  @override
  Future<Response> post(
    Uri url, {
    Map<String, String>? headers,
    Map<String, Object?>? body,
  }) {
    throw UnimplementedError();
  }

  @override
  void replaceForTesting(AuthManager authManager) {}

  @override
  Future<bool> validateToken() {
    throw UnimplementedError();
  }

  @override
  writeKeysToStore() {
    throw UnimplementedError();
  }

  @override
  Map<String, String> buildHeaders(headers) {
    throw UnimplementedError();
  }

  @override
  Future<Response> put(
    Uri url, {
    Map<String, String>? headers,
    Map<String, Object?>? body,
  }) {
    throw UnimplementedError();
  }

  @override
  bool userMustBeLoggedIn() {
    if (allowLogin) {
      return user != null && user!.isSignedIn;
    }
    throw UnimplementedError();
  }

  @override
  Future<Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Map<String, Object?>? body,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    throw UnimplementedError();
  }

  @override
  Future<User?> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    timesCreateAccountCalled++;
    createAccountCalledWith = {
      'email': email,
      'password': password,
      'name': name,
    };
    if (allowLogin) {
      user = MockUser.create(email: email, name: name);
      return user;
    }
    throw UnimplementedError();
  }

  @override
  User? handleUserResponse(http.Response response) {
    throw UnimplementedError();
  }

  @override
  Future<User?> changePassword({required String password}) async {
    methodCounters['changePassword'].call({'password': password});
    if (allowLogin) {
      return user;
    }
    throw UnimplementedError();
  }
}
