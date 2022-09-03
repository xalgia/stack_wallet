import 'package:decimal/decimal.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
import 'package:stackwallet/services/change_now/change_now.dart';

class IncompleteExchangeModel {
  final String sendTicker;
  final String receiveTicker;

  final String rateInfo;

  final Decimal sendAmount;
  final Decimal receiveAmount;

  final ExchangeRateType rateType;

  String? recipientAddress;
  String? refundAddress;

  String? rateId;

  ExchangeTransaction? trade;

  final CNEstimateType type;

  IncompleteExchangeModel({
    required this.sendTicker,
    required this.receiveTicker,
    required this.rateInfo,
    required this.sendAmount,
    required this.receiveAmount,
    required this.rateType,
    required this.type,
    this.rateId,
  });
}
