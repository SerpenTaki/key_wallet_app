import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:key_wallet_app/services/i_nfc_service.dart';
import 'package:key_wallet_app/services/nfc_kit_wrapper.dart';

class NfcServices implements INfcService {
  final NfcKitWrapper _nfcKitWrapper;

  NfcServices({NfcKitWrapper? nfcKitWrapper}) : _nfcKitWrapper = nfcKitWrapper ?? NfcKitWrapper();

  @override
  Future<bool> checkAvailability() async {
    try {
      NFCAvailability availability = await _nfcKitWrapper.nfcAvailability;
      return availability == NFCAvailability.available;
    }
    on PlatformException {
      return false;
    }
  }

  @override
  Future<NFCTag?> fetchNfcData() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _nfcKitWrapper.setIosAlertMessage("Avvicina il dispositivo al tag NFC...");
      }
      NFCTag tag = await _nfcKitWrapper.poll();
      return tag;
    } catch (e) {
      await _nfcKitWrapper.finish();
      return null;
    }
  }
}
