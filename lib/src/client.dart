import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_config.dart';
import 'auth_manager.dart';
import 'user.dart';

class AuthClient extends http.BaseClient {
  final http.Client _httpClient;
  final AuthConfig config;
  final AuthManager authManager;

  AuthClient({required this.config, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client(),
      authManager = AuthManager(config: config) {
    authManager.httpClient = this;
  }

  Future<User?> login(String email, String password) async {
    var response = await _sendUnstreamed(
      'POST',
      config.signInUrl,
      defaultHeaders,
      jsonEncode({'email': email, 'password': password}),
      null,
      skipUserValidation: true,
    );
    return handleUserResponse(response);
  }

  Future<void> logout() async {
    await delete(config.signOutUrl);
    await authManager.clear();
  }

  Future<User?> changePassword({required String password}) async {
    var response = await put(
      config.passwordUrl,
      headers: defaultHeaders,
      body: jsonEncode({
        'password': password,
        'password_confirmation': password,
      }),
    );
    return handleUserResponse(response);
  }

  Future<User?> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    var response = await post(
      config.createAccountUrl,
      body: jsonEncode({
        'email': email,
        'password': password,
        'password_confirmation': password,
        'name': name,
      }),
    );
    return handleUserResponse(response);
  }

  Future<bool> validateToken() async {
    if (user == null || user!.accessToken == null) {
      return false;
    }
    var response = await get(config.validateTokenUrl);
    if (response.statusCode != 200) {
      return false;
    }
    handleResponse(response);
    return true;
  }

  @override
  Future<http.StreamedResponse> send(
    http.BaseRequest request, {
    bool skipUserValidation = false,
  }) async {
    if (!skipUserValidation) request.headers.addAll(authHeaders());
    final response = _httpClient.send(request);
    response.then(handleResponse);
    return response;
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) =>
      _sendUnstreamed(
        'HEAD',
        url,
        headers,
        null,
        null,
        skipUserValidation: true,
      );

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
      _sendUnstreamed('GET', url, headers, null, null);

  Future<http.Response> getWithParams(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    url = _validate(url);
    final urlToSend = addAppToUrl(url, queryParams: queryParams);
    return get(urlToSend, headers: headers);
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => _sendUnstreamed('POST', url, headers, body, encoding);

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => _sendUnstreamed('PUT', url, headers, body, encoding);

  @override
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => _sendUnstreamed('PATCH', url, headers, body, encoding);

  @override
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => _sendUnstreamed('DELETE', url, headers, body, encoding);

  Future<http.Response> _sendUnstreamed(
    String method,
    Uri url,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding, {
    bool skipUserValidation = false,
  }) async {
    url = _validate(url, skipUserValidation: skipUserValidation);
    if (!skipUserValidation) url = addAppToUrl(url);
    var request = http.Request(method, url);

    if (headers != null) request.headers.addAll(headers);
    if (encoding != null) request.encoding = encoding;
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List) {
        request.bodyBytes = body.cast<int>();
      } else if (body is Map) {
        request.body = jsonEncode(body);
      } else {
        throw ArgumentError('Invalid request body "$body".');
      }
    }

    return http.Response.fromStream(
      await send(request, skipUserValidation: skipUserValidation),
    );
  }

  Map<String, String> authHeaders() {
    var headers = <String, String>{};
    headers.addAll({
      'uid': user!.uid!,
      'access-token': user!.accessToken!,
      'client': user!.client!,
    });
    headers['content-type'] = 'application/json';
    headers['accept'] = 'application/json';
    return headers;
  }

  void handleResponse(http.BaseResponse response) {
    var headers = response.headers;
    String? accessToken = headers['access-token'];
    if (accessToken?.isEmpty ?? true) return;
    authManager.user!.accessToken = accessToken;
    authManager.user!.client = headers['client'];
    authManager.user!.uid = headers['uid'];
    authManager.writeKeysToStore();
  }

  User? handleUserResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to login. Status code: ${response.statusCode}. Body: ${response.body}',
      );
    }
    var respHeaders = response.headers;
    var body = json.decode(response.body);
    authManager.user = User(
      accessToken: respHeaders['access-token'],
      client: respHeaders['client'],
      uid: respHeaders['uid'],
      appId: body["data"][config.appIdKey],
      id: body["data"]['id'],
      email: body["data"]['email'],
      name: body["data"]['name'],
    );
    authManager.writeKeysToStore();
    return user;
  }

  Uri _validate(Uri uri, {bool skipUserValidation = false}) {
    if (uri.host != config.appURL && uri.origin != config.appURL) {
      uri = uri.replace(host: config.appURL);
    }
    if (!skipUserValidation) userMustBeLoggedIn();
    return uri;
  }

  User? get user => authManager.user;

  bool userMustBeLoggedIn() {
    if (user == null || user!.accessToken == null) {
      throw Exception('User must be logged in to make this request');
    }
    return true;
  }

  Uri addAppToUrl(Uri url, {Map<String, dynamic>? queryParams}) {
    final Map<String, String> paramsToAdd = {};
    if (url.queryParameters.isNotEmpty) {
      paramsToAdd.addAll(url.queryParameters);
    }
    if (queryParams != null) {
      queryParams.forEach((key, value) {
        paramsToAdd[key] = value.toString();
      });
    }
    paramsToAdd[config.appIdKey] = user!.appId!.toString();
    return url.replace(queryParameters: paramsToAdd);
  }

  static const Map<String, String> defaultHeaders = {
    'content-type': 'application/json',
    'accept': 'application/json',
  };
}
