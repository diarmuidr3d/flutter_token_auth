import 'package:http/http.dart' as http;

import 'auth_config.dart';
import 'client.dart';
import 'local_storage.dart';
import 'user.dart';

/// Manages user authentication and API requests.
///
/// This class provides methods for user login, registration, password changes,
/// and authenticated API requests. It handles token management and local storage
/// of authentication credentials.
class AuthManager {
  static AuthManager _singleton = AuthManager._internal();
  late AuthConfig config;
  late AuthClient httpClient;

  /// Creates or returns the singleton instance of AuthManager.
  ///
  /// [config] is the configuration for the authentication API. This parameter
  /// is required on first instantiation.
  ///
  /// Throws [Exception] if the config is not set.
  factory AuthManager({AuthConfig? config, AuthClient? httpClient}) {
    if (config != null) {
      _singleton.config = config;
    }
    if (httpClient != null) {
      _singleton.httpClient = httpClient;
    }
    return _singleton;
  }

  AuthManager._internal();

  static final LocalStorage _secureStorage = LocalStorage();

  /// Gets the currently logged-in user.
  ///
  /// Returns the [User] object if a user is logged in, otherwise returns null.
  User? user;

  User? get currentUser => user;

  /// Authenticates a user with email and password.
  ///
  /// [email] is the user's email address.
  /// [password] is the user's password.
  ///
  /// Returns a [User] object if login is successful, otherwise returns null.
  ///
  /// Throws [Exception] if the login request fails.
  Future<User?> login(String email, String password) async {
    return httpClient.login(email, password);
  }

  /// Creates a new user account.
  ///
  /// [email] is the new user's email address.
  /// [password] is the new user's password.
  /// [name] is the new user's display name.
  ///
  /// Returns a [User] object if account creation is successful, otherwise returns null.
  ///
  /// Throws [Exception] if the account creation request fails.
  Future<User?> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    return httpClient.createAccount(
      email: email,
      password: password,
      name: name,
    );
  }

  /// Changes the password for the currently logged-in user.
  ///
  /// [password] is the new password for the user.
  ///
  /// Returns a [User] object with updated authentication tokens if successful,
  /// otherwise returns null.
  ///
  /// Throws [Exception] if the password change request fails or if no user is logged in.
  Future<User?> changePassword({required String password}) async {
    return httpClient.changePassword(password: password);
  }

  /// Logs out the current user and clears stored authentication data.
  ///
  /// This method sends a sign-out request to the server, clears the current user,
  /// and removes all authentication tokens from local storage.
  Future<void> logout() async {
    await httpClient.logout();
  }

  Future<void> clear() async {
    user = null;
    await _secureStorage.delete(key: userAccessTokenKey);
    await _secureStorage.delete(key: userClientKey);
    await _secureStorage.delete(key: userUidKey);
    await _secureStorage.delete(key: appIdKey);
  }

  /// Loads user authentication data from local storage.
  ///
  /// Returns a [User] object if authentication data is found in storage,
  /// otherwise returns null.
  ///
  /// This method reconstructs the user object from stored tokens and user data.
  Future<User?> loadFromStorage() async {
    String? accessToken = await _secureStorage.read(key: userAccessTokenKey);
    var client = await _secureStorage.read(key: userClientKey);
    var uid = await _secureStorage.read(key: userUidKey);
    var email = await _secureStorage.read(key: userEmailKey);
    var appId = await _secureStorage.read(key: appIdKey);
    user = User(
      accessToken: accessToken,
      client: client,
      uid: uid,
      email: email,
      appId: int.parse(appId!),
    );
    return user;
  }

  /// Checks if a user is currently logged in by loading from storage and validating the token.
  ///
  /// Returns true if a user is logged in and their token is valid, false otherwise.
  ///
  /// This method first attempts to load user data from storage if no user is currently set,
  /// then validates the authentication token with the server.
  Future<bool> checkLoggedIn() async {
    user ??= await loadFromStorage();
    return validateToken();
  }

  /// Validates the current user's authentication token with the server.
  ///
  /// Returns true if the token is valid, false otherwise.
  ///
  /// This method sends a request to the server to verify that the current
  /// authentication token is still valid and updates the token if necessary.
  Future<bool> validateToken() async {
    return httpClient.validateToken();
  }

  Future<void> writeKeysToStore() async {
    if (user == null || user!.accessToken == null) {
      return;
    }
    await _secureStorage.write(
      key: userAccessTokenKey,
      value: user!.accessToken!,
    );
    await _secureStorage.write(key: userClientKey, value: user!.client!);
    await _secureStorage.write(key: userUidKey, value: user!.uid!);
    await _secureStorage.write(key: userEmailKey, value: user!.email!);
    await _secureStorage.write(key: appIdKey, value: user!.appId!.toString());
  }

  /// Sends an authenticated POST request to the specified URL.
  ///
  /// [url] is the target URL for the request.
  /// [headers] are optional additional headers to include in the request.
  /// [body] is the optional request body data.
  ///
  /// Returns a [Response] object containing the server's response.
  ///
  /// Throws [Exception] if the user is not logged in or if the URL validation fails.
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Map<String, Object?>? body,
  }) async {
    return await httpClient.post(url, headers: headers, body: body);
  }

  /// Sends an authenticated GET request to the specified URL.
  ///
  /// [url] is the target URL for the request.
  /// [headers] are optional additional headers to include in the request.
  /// [queryParams] are optional query parameters to add to the URL.
  ///
  /// Returns a [Response] object containing the server's response.
  ///
  /// Throws [Exception] if the user is not logged in or if the URL validation fails.
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    return await httpClient.getWithParams(
      url,
      headers: headers,
      queryParams: queryParams,
    );
  }

  /// Sends an authenticated PUT request to the specified URL.
  ///
  /// [url] is the target URL for the request.
  /// [headers] are optional additional headers to include in the request.
  /// [body] is the optional request body data.
  ///
  /// Returns a [Response] object containing the server's response.
  ///
  /// Throws [Exception] if the user is not logged in or if the URL validation fails.
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Map<String, Object?>? body,
  }) async {
    return httpClient.put(url, headers: headers, body: body);
  }

  /// Sends an authenticated DELETE request to the specified URL.
  ///
  /// [url] is the target URL for the request.
  /// [headers] are optional additional headers to include in the request.
  /// [body] is the optional request body data.
  ///
  /// Returns a [Response] object containing the server's response.
  ///
  /// Throws [Exception] if the user is not logged in or if the URL validation fails.
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Map<String, Object?>? body,
  }) async {
    return httpClient.delete(url, headers: headers, body: body);
  }

  /// Replaces the singleton instance with a new AuthManager for testing purposes.
  ///
  /// [authManager] is the new AuthManager instance to use as the singleton.
  ///
  /// This method is intended for use in unit tests to provide a mock or test
  /// implementation of the AuthManager.
  void replaceForTesting(AuthManager authManager) {
    _singleton = authManager;
  }
}
