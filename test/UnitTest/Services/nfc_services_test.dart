import 'package:flutter/foundation.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/services/nfc_kit_wrapper.dart';
import 'package:key_wallet_app/services/nfc_services.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/services.dart';


@GenerateMocks([NfcKitWrapper, NFCTag])
import 'nfc_services_test.mocks.dart';

void main() {
  late NfcServices nfcService;
  late MockNfcKitWrapper mockNfcKitWrapper;

  setUp(() {
    mockNfcKitWrapper = MockNfcKitWrapper();
    // Iniezione del mock del nostro wrapper
    nfcService = NfcServices(nfcKitWrapper: mockNfcKitWrapper);
  });

  group('NfcServices', () {
    group('checkAvailability', () {
      test("dovrebbe restituire false quando nfcAvailability lancia un PlatformException", () async {
        when(mockNfcKitWrapper.nfcAvailability).thenThrow(PlatformException(code:"ERROR", message: "NFC Service not available"));

        final result = await nfcService.checkAvailability();
        expect(result, isFalse);
      });

      test('dovrebbe restituire true quando NFC è disponibile', () async {
        when(mockNfcKitWrapper.nfcAvailability)
            .thenAnswer((_) async => NFCAvailability.available);

        final result = await nfcService.checkAvailability();
        expect(result, isTrue);
      });

      test('dovrebbe restituire false quando NFC non è disponibile', () async {
        when(mockNfcKitWrapper.nfcAvailability)
            .thenAnswer((_) async => NFCAvailability.disabled);

        final result = await nfcService.checkAvailability();
        expect(result, isFalse);
      });
    });

    group('fetchNfcData', () {
      test('dovrebbe restituire un NFCTag quando la scansione ha successo', () async {
        final mockTag = MockNFCTag();
        when(mockNfcKitWrapper.poll()).thenAnswer((_) async => mockTag);

        final result = await nfcService.fetchNfcData();
        expect(result, equals(mockTag));
      });

      test('dovrebbe restituire null quando la scansione fallisce', () async {
        when(mockNfcKitWrapper.poll()).thenThrow(Exception('Scansione fallita'));
        when(mockNfcKitWrapper.finish()).thenAnswer((_) async => {});

        final result = await nfcService.fetchNfcData();
        expect(result, isNull);
        verify(mockNfcKitWrapper.finish()).called(1);
      });
    });

    test('dovrebbe chiamare setIosAlertMessage quando la piattaforma è iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final mockTag = MockNFCTag();
      when(mockNfcKitWrapper.setIosAlertMessage(any)).thenAnswer((_) async {});
      when(mockNfcKitWrapper.poll()).thenAnswer((_) async => mockTag);

      await nfcService.fetchNfcData();

      verify(mockNfcKitWrapper.setIosAlertMessage("Avvicina il dispositivo al tag NFC...")).called(1);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
