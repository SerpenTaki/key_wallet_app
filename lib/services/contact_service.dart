import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_wallet_app/services/i_contact_service.dart';

class ContactService implements IContactService{
  final FirebaseFirestore _firestore;

  ContactService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Cerca i wallet associati a un'email.
  @override
  Future<List<Map<String, dynamic>>> searchWalletsByEmail(String email) async {
    if (email.isEmpty) return [];

    // Trova tutti i wallet associati a quell'utente
    final walletQuery = await _firestore
        .collection('wallets')
        .where('email', isEqualTo: email)
        .get();

    return walletQuery.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Cerca i wallet tramite NFC
  @override
  Future<List<Map<String, dynamic>>> searchWalletsByNfc(String hBytes, String standard) async {
    if (hBytes.isEmpty || standard.isEmpty) return [];

    final walletQuery = await _firestore
        .collection('wallets')
        .where('hBytes', isEqualTo: hBytes)
        .where('standard', isEqualTo: standard)
        .get();

    return walletQuery.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}
