import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

abstract class INfcService{
  Future<bool> checkAvailability();

  Future<NFCTag?> fetchNfcData();
}