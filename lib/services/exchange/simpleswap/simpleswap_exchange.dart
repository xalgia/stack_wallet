import 'package:decimal/decimal.dart';
import 'package:stackwallet/services/exchange/exchange.dart';
import 'package:stackwallet/services/exchange/exchange_response.dart';
import 'package:stackwallet/services/exchange/simpleswap/simpleswap_api.dart';

class SimpleSwapExchange extends Exchange {
  //

  Future<ExchangeResponse<ExchangeValue>> createExchange({
    required bool isFixedRate,
    required Decimal amount,
    required String currencyFrom,
    required String currencyTo,
    required String addressTo,
    String? extraIdTo,
    required String userRefundAddress,
    required String userRefundExtraId,
  }) async {
    final result = SimpleSwapAPI.instance.createNewExchange(
      isFixedRate: isFixedRate,
      currencyFrom: currencyFrom,
      currencyTo: currencyTo,
      addressTo: addressTo,
      userRefundAddress: userRefundAddress,
      userRefundExtraId: userRefundExtraId,
      amount: amount.toString(),
    );

    return ExchangeResponse();
  }
}
