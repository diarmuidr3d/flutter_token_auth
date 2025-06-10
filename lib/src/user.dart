import 'package:flutter_token_auth/src/auth_manager.dart';

class User {
  User({
    this.uid,
    this.accessToken,
    this.client,
    String? email,
    this.appId,
    this.id,
    this.name,
  }) : _email = email;

  String? uid;
  String? accessToken;
  String? client;
  final String? _email;
  int? appId;
  int? id;
  String? name;

  bool get loggedIn => accessToken != null;

  static User get currentUser {
    return AuthManager().currentUser!;
  }

  bool get isSignedIn => loggedIn;

  String? get email => _email;

  Future<User> login(String password) async {
    User? newUser = await AuthManager().login(_email!, password);

    if (newUser != null) {
      return newUser;
    } else {
      return this;
    }
  }

  Future<User> createAccount(String password) async {
    User? newUser = await AuthManager().createAccount(
      email: _email!,
      password: password,
      name: name!,
    );

    if (newUser != null) {
      return newUser;
    } else {
      return this;
    }
  }

  Future<User> changePassword(String password) async {
    User? newUser = await AuthManager().changePassword(password: password);

    if (newUser != null) {
      return newUser;
    } else {
      return this;
    }
  }
}
