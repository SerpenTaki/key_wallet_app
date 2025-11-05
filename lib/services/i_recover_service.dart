abstract class IRecoverService{
  Future<bool> checkIfRight(String publicKey, String privateKeyString);
}