import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:key_wallet_app/models/wallet.dart';

void main() {
  // Inizializza il binding per i test di integrazione
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Test della Generazione del Wallet', () {

    // Q1: Misurazione del tempo di esecuzione
    // Q2: Mantenere il tempo di risposta sotto i 2 secondi
    testWidgets('La generazione del wallet deve essere inferiore a 2 secondi', (WidgetTester tester) async {

      // Definiamo i parametri di test
      const String testUserId = 'test_user_id_performance';
      const String testEmail = 'performance@test.com';
      const String testWalletName = 'Performance Test Wallet';
      const Color testColor = Colors.deepPurple;
      const String testHBytes = 'test_hbytes_123';
      const String testStandard = 'test_standard_abc';
      const String testDevice = 'test_device';
      const Duration timeThreshold = Duration(seconds: 2); // Soglia di 2 secondi

      // Misuriamo il tempo di esecuzione
      final stopwatch = Stopwatch()..start(); // Avvia il cronometro

      // --- AZIONE: Esegui la funzione da testare ---
      // Usiamo direttamente il metodo statico di Wallet che contiene tutta la logica.
      // Questo testa la parte più "pesante": la generazione delle chiavi crittografiche.
      final Wallet newWallet = await Wallet.generateNew(
        testUserId,
        testEmail,
        testWalletName,
        testColor,
        testHBytes,
        testStandard,
        testDevice,
      );

      stopwatch.stop(); // Ferma il cronometro
      final Duration executionTime = stopwatch.elapsed;

      // --- STAMPA E VERIFICA ---

      // Stampa il risultato per il requisito Q1
      print('--- Misurazione Prestazioni Generazione Wallet ---');
      print('Tempo di esecuzione: ${executionTime.inMilliseconds} ms');
      print('Soglia massima: ${timeThreshold.inMilliseconds} ms');

      // Verifica il risultato per il requisito Q2
      expect(executionTime, lessThan(timeThreshold),
          reason: 'La generazione del wallet ha impiegato ${executionTime.inMilliseconds} ms, superando la soglia di ${timeThreshold.inMilliseconds} ms.');

      //Verifica che il wallet generato sia valido
      expect(newWallet, isNotNull);
      expect(newWallet.publicKey, isNotEmpty);
      expect(newWallet.transientRawPrivateKey, isNotEmpty);
      expect(newWallet.name, equals(testWalletName));
    });
  });
}
