import 'package:flutter_token_auth/token_auth.dart';

void main() {
  var user = User(email: 'test@test.com');
  user.login('password'); // login user
  print(user.accessToken);

  AuthManager().logout(); // logout user

  AuthManager().login('test@test.com', 'password'); // login user
  //lets say the app is restarted
  AuthManager().loadFromStorage(); // get user from local storage
  print(AuthManager().currentUser); // get the current user from memory

  user.changePassword('newpassword'); // change password
  user.createAccount('password'); // create account
}
