import 'package:flutter_test/flutter_test.dart';
import 'package:lung_chaing_farm/models/user.dart';

void main() {
  group('User', () {
    test('fromJson creates a valid User object with all fields', () {
      final Map<String, dynamic> json = {
        'id': 1,
        'email': 'test@example.com',
        'role': 'USER',
        'farm_name': 'Test Farm',
        'token': 'some_jwt_token',
      };

      final user = User.fromJson(json);

      expect(user.id, 1);
      expect(user.email, 'test@example.com');
      expect(user.role, 'USER');
      expect(user.farmName, 'Test Farm');
      expect(user.token, 'some_jwt_token');
    });

    test(
      'fromJson creates a valid User object with nullable fields as null',
      () {
        final Map<String, dynamic> json = {'email': 'test@example.com'};

        final user = User.fromJson(json);

        expect(user.id, isNull);
        expect(user.email, 'test@example.com');
        expect(user.role, isNull);
        expect(user.farmName, isNull);
        expect(user.token, isNull);
      },
    );

    test(
      'toJson converts a User object to a valid JSON map with all fields',
      () {
        final user = User(
          id: 1,
          email: 'test@example.com',
          role: 'USER',
          farmName: 'Test Farm',
          token: 'some_jwt_token',
        );

        final json = user.toJson();

        expect(json['id'], 1);
        expect(json['email'], 'test@example.com');
        expect(json['role'], 'USER');
        expect(json['farm_name'], 'Test Farm');
        expect(json['token'], 'some_jwt_token');
      },
    );

    test(
      'toJson converts a User object to a valid JSON map with nullable fields as null',
      () {
        final user = User(email: 'test@example.com');

        final json = user.toJson();

        expect(json['id'], isNull);
        expect(json['email'], 'test@example.com');
        expect(json['role'], isNull);
        expect(json['farm_name'], isNull);
        expect(json['token'], isNull);
      },
    );
  });
}
