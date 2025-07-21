Implements a basic system for managing token-based authentication. This is designed specifically to interact neatly with https://github.com/lynndylanhurley/devise_token_auth.

[![Flutter Test](https://github.com/diarmuidr3d/flutter_token_auth/actions/workflows/flutter_build.yml/badge.svg)](https://github.com/diarmuidr3d/flutter_token_auth/actions/workflows/flutter_build.yml) [![Publish to pub.dev](https://github.com/diarmuidr3d/flutter_token_auth/actions/workflows/publish.yml/badge.svg)](https://github.com/diarmuidr3d/flutter_token_auth/actions/workflows/publish.yml) ![Pub Version](https://img.shields.io/pub/v/flutter_token_auth)

## Features
- Persisting of user in local storage to avoid re-authentication
- Validation of token to ensure user is authenticated
- Login / Logout
- Test mocking

## Getting started
The first time that `AuthManager` is instantiated on the app launch it must be instantiated with an `AuthConfig`. The only required url there is your server's url (eg: `app.example.com`) provided that the other paths follow the defaults.
This is best placed in your `main.dart` file.
```dart
AuthManager(config: AuthConfig(appUrl: "app.example.com"));
```

## Usage
```dart
AuthManager.login('user@example.com', 'password'); // login a user
AuthManager.currentUser; // get the current user
await AuthManager.loadFromStorage(); // on app load, retreive the cached local user
```

There are additional settings to be passed in in `AuthConfig`, see the interface in https://github.com/diarmuidr3d/flutter_token_auth/blob/main/lib/src/auth_config.dart for example

## Additional information

### Publishing a new version
Update `pubspec.yaml` with the new version number
Edit `CHANGELOG.md` with the changes
`git commit "v0.3.5"` commit the changes
`git tag v0.3.5` tag the changes
Push your changes `git push origin branch`
Push the tag `git push v0.3.5`