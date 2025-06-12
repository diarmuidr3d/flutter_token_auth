class AuthConfig {
  final String appURL;
  final String path;
  final String signInPath;
  final String signOutPath;
  final String validateTokenPath;
  final String passwordPath;
  final String createAccountPath;
  final String appIdKey;

  const AuthConfig({
    required this.appURL,
    this.path = '/auth',
    this.signInPath = '/sign_in',
    this.signOutPath = '/sign_out',
    this.validateTokenPath = '/validate_token',
    this.passwordPath = '/password',
    this.createAccountPath = '/',
    this.appIdKey = 'app_id',
  });

  Uri get signInUrl => Uri.https(appURL, path + signInPath);
  Uri get signOutUrl => Uri.https(appURL, path + signOutPath);
  Uri get validateTokenUrl => Uri.https(appURL, path + validateTokenPath);
  Uri get passwordUrl => Uri.https(appURL, path + passwordPath);
  Uri get createAccountUrl => Uri.https(appURL, path + createAccountPath);
}
