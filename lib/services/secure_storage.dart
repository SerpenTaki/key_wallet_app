import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:key_wallet_app/services/i_secure_storage.dart';

class SecureStorage implements ISecureStorage {
  final FlutterSecureStorage storage;

  // Costruttore: se non viene fornito uno storage, usa quello di default. Ci consente di iniettare il mock
  SecureStorage({FlutterSecureStorage? storage}) : storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> writeSecureData(String key, String value) async {
    await storage.write(key: key, value: value);
    //print("Dato salvata correttamente");
  }

  @override
  Future<String?> readSecureData(String key) async {
    final value = await storage.read(key: key);
    return value;
  }

  @override
  Future<void> deleteSecureData(String key) async {
    await storage.delete(key: key);
    //print("Dato eliminata correttamente");
  }
}
