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
import 'package:flutter/foundation.dart';
import 'package:flutter_libmonero/core/key_service.dart';
import 'package:flutter_libmonero/core/wallet_creation_service.dart';
import 'package:flutter_libmonero/monero/monero.dart';
import 'package:flutter_libmonero/view_model/send/output.dart' as monero_output;
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:tuple/tuple.dart';

@GenerateMocks([PriceAPI, TransactionNotificationTracker])
void main() {
  group("1", () {
    FakeSecureStorage? secureStore;

    MoneroWallet? stagenetWallet;
    setUp(() {
      secureStore = FakeSecureStorage();

      stagenetWallet = MoneroWallet(
        walletId: "validateAddressStageNet",
        walletName: "validateAddressStageNet",
        coin: Coin.moneroStageNet,
        // tracker: tracker,
      );
    });
  });
}
