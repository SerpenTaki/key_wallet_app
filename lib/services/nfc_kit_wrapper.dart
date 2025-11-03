// coverage:ignore-file
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

/// Questa classe "avvolge" i metodi statici di FlutterNfcKit
/// e li espone come metodi di ISTANZA, rendendoli mockabili.
class NfcKitWrapper {
  Future<NFCAvailability> get nfcAvailability => FlutterNfcKit.nfcAvailability;

  Future<NFCTag> poll() => FlutterNfcKit.poll();

  Future<void> finish() => FlutterNfcKit.finish();

  Future<void> setIosAlertMessage(String message) => FlutterNfcKit.setIosAlertMessage(message);
}
