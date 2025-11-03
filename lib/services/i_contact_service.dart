abstract class IContactService{
  ///Cerca i wallet associati a una mail
  Future<List<Map<String, dynamic>>> searchWalletsByEmail(String email);
  /// Cerca i wallet tramite NFC
  Future<List<Map<String, dynamic>>> searchWalletsByNfc(String hBytes, String standard);
}