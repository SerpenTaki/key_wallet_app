import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';


class NfcFetchData{
  NFCTag? _tag;

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
      _tag = tag;

      await FlutterNfcKit.setIosAlertMessage("Working on it...");

      if (tag.standard == "ISO 14443-4 (Type B)") {
        await FlutterNfcKit.transceive("00B0950000");
        await FlutterNfcKit.transceive("00A4040009A00000000386980701");
      } else if (tag.type == NFCTagType.iso18092) {
        await FlutterNfcKit.transceive("060080080100");
      } else if (tag.ndefAvailable ?? false) {
        await FlutterNfcKit.readNDEFRecords();
      } else if (tag.type == NFCTagType.webusb) {
        await FlutterNfcKit.transceive("00A4040006D27600012401");
      }
      return _tag;
    } catch (e) {
      _tag = null;
      return null;
    }
  }

}
