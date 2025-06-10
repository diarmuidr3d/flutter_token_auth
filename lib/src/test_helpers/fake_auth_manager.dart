import 'package:http/http.dart' as http;
import 'package:flutter_token_auth/token_auth.dart';

import 'method_counters.dart';

class FakeAuthManager implements AuthManager {
  static final FakeAuthManager _authManager = FakeAuthManager._new();
  // ignore: unused_field
  late AuthConfig _config;

  FakeAuthManager._new();

  factory FakeAuthManager({
    AuthConfig? config,
    bool clear = true,
    bool withLoggedInUser = false,
  }) {
    AuthManager().replaceForTesting(_authManager);
    if (clear) _authManager.clear();
    if (withLoggedInUser) {
      _authManager._user = MockUser.create();
      _authManager.allowLogin = true;
    }
    if (config != null) {
      _authManager._config = config;
    }
    return _authManager;
  }

  User? _user;

  bool allowLogin = false;
  int timesLoginCalled = 0;
  Map<String, String> loginCalledWith = {};
  int timesCreateAccountCalled = 0;
  Map<String, String> createAccountCalledWith = {};

  MethodCounters methodCounters = MethodCounters();

  @override
  Future<void> clear() async {
    _user = null;
    allowLogin = false;
    timesLoginCalled = 0;
    loginCalledWith = {};
    methodCounters.clear();
  }

  @override
  Uri addAppToUrl(Uri url, {Map<String, dynamic>? queryParams}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> checkLoggedIn() async {
    if (allowLogin) {
      if (_user == null) return false;
      return _user!.isSignedIn;
    }
    throw UnimplementedError();
  }

  @override
  get currentUser => _user;

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
      _user = MockUser.create(email: email);
      return _user;
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
      return _user != null && _user!.isSignedIn;
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
      _user = MockUser.create(email: email, name: name);
      return _user;
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
      return _user;
    }
    throw UnimplementedError();
  }
}
