abstract class ISecureStorage {

  Future<void> writeSecureData(String key, String value);

  Future<String?> readSecureData(String key);

  Future<void> deleteSecureData(String key);
}