import 'dart:async';
import 'dart:core';
import 'dart:core' as core;
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_monero/api/wallet.dart';
import 'package:cw_monero/pending_monero_transaction.dart';
import 'package:cw_monero/monero_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libmonero/core/key_service.dart';
import 'package:flutter_libmonero/core/wallet_creation_service.dart';
import 'package:flutter_libmonero/view_model/send/output.dart';
import 'package:flutter_libmonero/monero/monero.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:developer' as developer;

FlutterSecureStorage? storage;
WalletService? walletService;
SharedPreferences? prefs;
KeyService? keysStorage;
MoneroWalletBase? walletBase;
late WalletCreationService _walletCreationService;

@GenerateMocks([])
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Directory appDir = (await getApplicationDocumentsDirectory());
  if (Platform.isIOS) {
    appDir = (await getLibraryDirectory());
  }
  await Hive.close();
  Hive.init(appDir.path);

  // if (!Hive.isAdapterRegistered(Node.typeId)) {
  Hive.registerAdapter(NodeAdapter());
  // }

  // if (!Hive.isAdapterRegistered(WalletInfo.typeId)) {
  Hive.registerAdapter(WalletInfoAdapter());
  // }

  // if (!Hive.isAdapterRegistered(WalletType.)) {
  Hive.registerAdapter(WalletTypeAdapter());
  // }

  // if (!Hive.isAdapterRegistered(UnspentCoinsInfo.typeId)) {
  Hive.registerAdapter(UnspentCoinsInfoAdapter());
  // }

  monero.onStartup();
  final _walletInfoSource = await Hive.openBox<WalletInfo>(WalletInfo.boxName);
  walletService = monero.createMoneroWalletService(_walletInfoSource);
  storage = FlutterSecureStorage();
  prefs = await SharedPreferences.getInstance();
  keysStorage = KeyService(storage!);
  WalletInfo walletInfo;
  late WalletCredentials credentials;

  group("Test 1", () {
    setUp(() async {});

    test("Test 1", () async {
      print('Test 1');
    });
  });
}
