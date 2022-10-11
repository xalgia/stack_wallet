import 'dart:io';
import 'dart:io' show Directory;
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/services/coins/monero/monero_wallet.dart';
import 'package:stackwallet/services/price.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_libmonero/core/key_service.dart';
import 'package:flutter_libmonero/core/wallet_creation_service.dart';
import 'package:flutter_libmonero/monero/monero.dart';
import 'package:flutter_libmonero/view_model/send/output.dart' as monero_output;
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:tuple/tuple.dart';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

@GenerateMocks([])
void main() {
  group("Validate stagenet address", () {
    MoneroWallet? wallet;
    FakeSecureStorage? storage;
    WalletService? walletService;
    dynamic _walletInfoSource;

    setUp(() async {
      const name = 'validateAddressStageNet';
      const type = WalletType.moneroStageNet;
      const nettype = 2;

      wallet = MoneroWallet(
        walletId: 'validateAddressStageNet',
        walletName: 'validateAddressStageNet',
        coin: Coin.moneroStageNet,
        // tracker: tracker,
      );

      var dirPath;
      final _dirPath =
          await wallet?.pathForWalletDir(name: name, type: type); // TODO test
      if (_dirPath != null) {
        dirPath = _dirPath;
      }
      var path;
      final _path =
          await wallet?.pathForWallet(name: name, type: type); // TODO test
      if (_path != null) {
        path = _dirPath;
      }

      WalletCredentials credentials;
      credentials = monero.createMoneroNewWalletCredentials(
        name: name,
        language: 'English',
      ); // TODO test

      WalletInfo walletInfo;
      walletInfo = WalletInfo.external(
          //id: WalletBase.idFor(name, type),
          id: '${walletTypeToString(type).toLowerCase()}_$name',
          name: name,
          type: type,
          isRecovery: false,
          restoreHeight: 0,
          date: DateTime.now(),
          path: path,
          dirPath: dirPath,
          // TODO: find out what to put for address
          address: ''); // TODO test
      credentials.walletInfo = walletInfo;

      // We shouldn't be testing storage because results may vary by platform
      Directory appDir = (await getApplicationDocumentsDirectory());
      if (Platform.isIOS) {
        appDir = (await getLibraryDirectory());
      }
      await Hive.close();
      Hive.init(appDir.path);

      _walletInfoSource = await Hive.openBox<WalletInfo>(WalletInfo.boxName);
      // walletService = monero.createMoneroWalletService(DB.instance.moneroWalletInfoBox);
      walletService = monero.createMoneroWalletService(_walletInfoSource);

      WalletCreationService? _walletCreationService;
      _walletCreationService = WalletCreationService(
          /*
        secureStorage: storage,
        sharedPreferences: prefs,
        walletService: walletService,
        keyService: keysStorage,
         */
          ); // TODO test
      _walletCreationService.changeWalletType(); // TODO test

      var stagenetWallet =
          await _walletCreationService.create(credentials, nettype: nettype);

      /*
      walletBase =
          wallet as MoneroWalletBase; // Error: 'MoneroWalletBase' isn't a type.
       */
    });
  });
}
