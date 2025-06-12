import 'dart:math';

import 'package:flutter_token_auth/flutter_token_auth.dart';

class MockUser extends User {
  static MockUser create({
    String? name,
    String? email,
    String? accessToken,
    String? client,
    String? uid,
    int? appId,
    int? id,
  }) {
    email ??= '123@example.com';
    id ??= Random().nextInt(1000000);
    return MockUser(
      email: email,
      name: name ?? 'Some User',
      accessToken: accessToken ?? Random().nextInt(1000000).toString(),
      client: client ?? Random().nextInt(1000000).toString(),
      uid: uid ?? email,
      appId: appId,
      id: id,
    );
  }

  MockUser({
    super.uid,
    super.accessToken,
    super.client,
    super.email,
    super.appId,
    super.id,
    super.name,
  });
}
