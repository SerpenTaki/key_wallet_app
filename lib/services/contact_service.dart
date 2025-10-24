import 'package:cloud_firestore/cloud_firestore.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cerca i wallet associati a un'email.
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
  Future<List<Map<String, dynamic>>> searchWalletsByNfc(String hBytes, String standard) async {
    if (hBytes.isEmpty || standard.isEmpty) return [];

    final walletQuery = await _firestore
        .collection('wallets')
        .where('hBytes', isEqualTo: hBytes)
        .where('standard', isEqualTo: standard)
        .get();

    if (walletQuery.docs.isEmpty) {
      return []; // Nessun Wallet trovato
    }

    return walletQuery.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Aggiunge un nuovo walletId alla lista dei contatti del senderWallet.
  Future<void> addContact(String senderWalletId, String contactWalletId) async {
    if (senderWalletId == contactWalletId) return; // Non si può aggiungere se stessi

    final DocumentReference senderDocRef = _firestore.collection('wallets').doc(senderWalletId);

    await senderDocRef.update({
      'contacts': FieldValue.arrayUnion([contactWalletId])
    });
  }
}
