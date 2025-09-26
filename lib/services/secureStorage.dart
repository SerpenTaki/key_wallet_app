import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<void> writeSecureData(String key, String value) async {
    await storage.write(key: key, value: value);
    print("Dato salvata correttamente");
  }

  Future<String?> readSecureData(String key) async {
    final value = await storage.read(key: key);
    return value;
  }

  Future<void> deleteSecureData(String key) async {
    await storage.delete(key: key);
    print("Dato eliminata correttamente");
  }
}
