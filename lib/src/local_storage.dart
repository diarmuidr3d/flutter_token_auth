import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String userAccessTokenKey = 'userAccessToken';
const String userClientKey = 'userClient';
const String userUidKey = 'userUid';
const String userEmailKey = 'userEmail';
const String appIdKey = 'appId';

class LocalStorage {
  static final LocalStorage _singleton = LocalStorage._internal();

  var _storage = const FlutterSecureStorage();

  factory LocalStorage() {
    return _singleton;
  }

  LocalStorage._internal();

  void setMockStoreForTest(FlutterSecureStorage store) {
    _storage = store;
  }

  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  Future<void> write({required String key, required String value}) async {
    return await _storage.write(key: key, value: value);
  }

  Future<void> delete({required String key}) async {
    return await _storage.delete(key: key);
  }
}
