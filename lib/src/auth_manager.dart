import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_config.dart';
import 'local_storage.dart';
import 'response.dart';
import 'user.dart';

/// Manages user authentication and API requests.
///
/// This class provides methods for user login, registration, password changes,
/// and authenticated API requests. It handles token management and local storage
/// of authentication credentials.
class AuthManager {
  static AuthManager _singleton = AuthManager._internal();
  late AuthConfig config;
  late http.Client _httpClient;

  /// Creates or returns the singleton instance of AuthManager.
  ///
  /// [config] is the configuration for the authentication API. This parameter
  /// is required on first instantiation.
  ///
  /// Throws [Exception] if the config is not set.
  factory AuthManager({AuthConfig? config, http.Client? httpClient}) {
    if (config != null) {
      _singleton.config = config;
    }
    if (httpClient != null) {
      _singleton._httpClient = httpClient;
    }
    // ignore: unnecessary_null_comparison
    if (_singleton.config == null) {
      throw Exception('AuthConfig is not set');
    }
    return _singleton;
  }

  AuthManager._internal() {
    _httpClient = http.Client();
  }

  static final LocalStorage _secureStorage = LocalStorage();

  User? _user;

  /// Gets the currently logged-in user.
  ///
  /// Returns the [User] object if a user is logged in, otherwise returns null.
  User? get currentUser => _user;

  /// Authenticates a user with email and password.
  ///
  /// [email] is the user's email address.
  /// [password] is the user's password.
  ///
  /// Returns a [User] object if login is successful, otherwise returns null.
  ///
  /// Throws [Exception] if the login request fails.
  Future<User?> login(String email, String password) async {
    var response = await _httpClient.post(
      config.signInUrl,
      headers: defaultHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return handleUserResponse(response);
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
    var response = await _httpClient.post(
      config.createAccountUrl,
      headers: defaultHeaders,
      body: jsonEncode({
        'email': email,
        'password': password,
        'password_confirmation': password,
        'name': name,
      }),
    );
    return handleUserResponse(response);
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
    Map<String, String> headers = Map<String, String>.from(defaultHeaders);
    headers.addAll(_accessValues);
    var response = await _httpClient.put(
      config.passwordUrl,
      headers: headers,
      body: jsonEncode({
        'password': password,
        'password_confirmation': password,
      }),
    );
    return handleUserResponse(response);
  }

  User? handleUserResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('Failed to login');
    }
    var respHeaders = response.headers;
    var body = json.decode(response.body);
    _user = User(
      accessToken: respHeaders['access-token'],
      client: respHeaders['client'],
      uid: respHeaders['uid'],
      appId: body["data"]['app_id'],
      id: body["data"]['id'],
      email: body["data"]['email'],
      name: body["data"]['name'],
    );
    writeKeysToStore();
    return _user;
  }

  /// Logs out the current user and clears stored authentication data.
  ///
  /// This method sends a sign-out request to the server, clears the current user,
  /// and removes all authentication tokens from local storage.
  Future<void> logout() async {
    await delete(config.signOutUrl);
    await clear();
  }

  Future<void> clear() async {
    _user = null;
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
    _user = User(
      accessToken: accessToken,
      client: client,
      uid: uid,
      email: email,
      appId: int.parse(appId!),
    );
    return _user;
  }

  /// Checks if a user is currently logged in by loading from storage and validating the token.
  ///
  /// Returns true if a user is logged in and their token is valid, false otherwise.
  ///
  /// This method first attempts to load user data from storage if no user is currently set,
  /// then validates the authentication token with the server.
  Future<bool> checkLoggedIn() async {
    _user ??= await loadFromStorage();
    return validateToken();
  }

  /// Validates the current user's authentication token with the server.
  ///
  /// Returns true if the token is valid, false otherwise.
  ///
  /// This method sends a request to the server to verify that the current
  /// authentication token is still valid and updates the token if necessary.
  Future<bool> validateToken() async {
    if (_user == null || _user!.accessToken == null) {
      return false;
    }
    var headers = _accessValues;
    headers['content-type'] = 'application/json';
    headers['accept'] = 'application/json';
    var response = await _httpClient.get(
      config.validateTokenUrl,
      headers: headers,
    );
    if (response.statusCode != 200) {
      return false;
    }
    handleResponse(response);
    return true;
  }

  Map<String, String> get _accessValues => {
    'uid': _user!.uid!,
    'access-token': _user!.accessToken!,
    'client': _user!.client!,
  };

  Future<void> writeKeysToStore() async {
    if (_user == null || _user!.accessToken == null) {
      return;
    }
    await _secureStorage.write(
      key: userAccessTokenKey,
      value: _user!.accessToken!,
    );
    await _secureStorage.write(key: userClientKey, value: _user!.client!);
    await _secureStorage.write(key: userUidKey, value: _user!.uid!);
    await _secureStorage.write(key: userEmailKey, value: _user!.email!);
    await _secureStorage.write(key: appIdKey, value: _user!.appId!.toString());
  }

  void handleResponse(http.Response response) {
    var headers = response.headers;
    String? accessToken = headers['access-token'];
    if (accessToken == "") return;
    _user!.accessToken = accessToken;
    _user!.client = headers['client'];
    _user!.uid = headers['uid'];
    writeKeysToStore();
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
  Future<Response> post(
    Uri url, {
    Map<String, String>? headers,
    Map<String, Object?>? body,
  }) async {
    _validate(url);
    var response = await _httpClient.post(
      addAppToUrl(url),
      headers: buildHeaders(headers),
      body: jsonEncode(body),
    );
    handleResponse(response);
    return Response.fromHttpResponse(response);
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
  Future<Response> get(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    url = _validate(url);
    final urlToSend = addAppToUrl(url, queryParams: queryParams);
    var response = await _httpClient.get(
      urlToSend,
      headers: buildHeaders(headers),
    );
    handleResponse(response);
    return Response.fromHttpResponse(response);
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
  Future<Response> put(
    Uri url, {
    Map<String, String>? headers,
    Map<String, Object?>? body,
  }) async {
    _validate(url);
    var response = await _httpClient.put(
      addAppToUrl(url),
      headers: buildHeaders(headers),
      body: jsonEncode(body),
    );
    handleResponse(response);
    return Response.fromHttpResponse(response);
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
  Future<Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Map<String, Object?>? body,
  }) async {
    _validate(url);
    var response = await _httpClient.delete(
      addAppToUrl(url),
      headers: buildHeaders(headers),
      body: jsonEncode(body),
    );
    handleResponse(response);
    return Response.fromHttpResponse(response);
  }

  Uri _validate(Uri uri) {
    uri = _validateUri(uri);
    userMustBeLoggedIn();
    return uri;
  }

  Uri _validateUri(Uri uri) {
    if (uri.host != config.appURL) {
      uri = uri.replace(host: config.appURL);
    }
    return uri;
  }

  bool userMustBeLoggedIn() {
    if (_user == null || _user!.accessToken == null) {
      throw Exception('User not logged in');
    }
    return true;
  }

  Uri addAppToUrl(Uri url, {Map<String, dynamic>? queryParams}) {
    queryParams ??= <String, dynamic>{};
    queryParams['app_id'] = _user!.appId!.toString();
    return url.replace(queryParameters: queryParams);
  }

  Map<String, String> buildHeaders(Map<String, String>? headers) {
    headers ??= {};
    headers.addAll(_accessValues);
    headers['content-type'] = 'application/json';
    headers['accept'] = 'application/json';
    return headers;
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

  static const Map<String, String> defaultHeaders = {
    'content-type': 'application/json',
    'accept': 'application/json',
  };
}
