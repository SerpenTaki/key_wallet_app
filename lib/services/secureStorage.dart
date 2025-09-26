import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage{
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  dynamic writeSecureData(String key, String value) async {
    await storage.write(key: key, value: value);
    print("Dato salvata correttamente");
  }

  dynamic readSecureData(String key) async {
    final value = await storage.read(key: key) ?? 'Nessun valore trovato';
    print("Valore letto: $value");
    return value;
  }

  dynamic deleteSecureData(String key) async {
    await storage.delete(key: key);
    print("Dato eliminata correttamente");
  }
}