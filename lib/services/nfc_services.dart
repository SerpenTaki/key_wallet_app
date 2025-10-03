import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter/foundation.dart';


class NfcServices{

  Future<bool> checkAvailability() async {
    try {
      NFCAvailability availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } on PlatformException {
      return false;
    }
  }

  Future<NFCTag?> fetchNfcData() async {
    try {
      NFCTag tag = await FlutterNfcKit.poll();
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await FlutterNfcKit.setIosAlertMessage("Avvicina il dispositivo al tag NFC...");
      }
      return tag;
    } catch (e) {
      await FlutterNfcKit.finish();
      return null;
    }
  }

}
