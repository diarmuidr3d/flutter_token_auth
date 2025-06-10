Implements a basic system for managing token-based authentication. This is designed specifically to interact neatly with https://github.com/lynndylanhurley/devise_token_auth.

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

## Additional information
TODO
