import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';


class NfcFetchData{

  Future<bool> checkAvailability() async {
    try {
      var _ = await FlutterNfcKit.nfcAvailability;
    } on PlatformException {
      var _ = NFCAvailability.not_supported;
      return false;
    }
    return true;
  }

  Future<NFCTag?> fetchNfcData() async {
    try {
      NFCTag tag = await FlutterNfcKit.poll();
      await FlutterNfcKit.setIosAlertMessage("Working on it...");
      return tag;
    } catch (e) {
      return null;
    }
  }

}
