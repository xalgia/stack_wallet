import 'package:stackwallet/models/exchange/simpleswap/sp_currency.dart';
import 'package:stackwallet/utilities/logger.dart';

class SPExchange {
  final int timestamp;
  final String currencyFrom;
  final String currencyTo;
  final String amountFrom;
  final String amountTo;
  final String addressFrom;
  final String addressTo;
  final String extraIdFrom;
  final String extraIdTo;
  final String status;
  final String txFrom;
  final String txTo;
  final List<SPCurrency> currencies;

  SPExchange({
    required this.timestamp,
    required this.currencyFrom,
    required this.currencyTo,
    required this.amountFrom,
    required this.amountTo,
    required this.addressFrom,
    required this.addressTo,
    required this.extraIdFrom,
    required this.extraIdTo,
    required this.status,
    required this.txFrom,
    required this.txTo,
    required this.currencies,
  });

  factory SPExchange.fromJson(Map<String, dynamic> json) {
    try {
      final List<SPCurrency> currencies = [];
      for (final jsonCurrency
          in (json["currencies"] as List<Map<String, dynamic>>)) {
        currencies.add(SPCurrency.fromJson(jsonCurrency));
      }

      return SPExchange(
        timestamp: json["timestamp"] as int,
        currencyFrom: json["currency_from"] as String,
        currencyTo: json["currency_to"] as String,
        amountFrom: json["amount_from"] as String,
        amountTo: json["amount_to"] as String,
        addressFrom: json["address_from"] as String,
        addressTo: json["address_to"] as String,
        extraIdFrom: json["extra_id_from"] as String,
        extraIdTo: json["extra_id_to"] as String,
        status: json["status"] as String,
        txFrom: json["tx_from"] as String,
        txTo: json["tx_to"] as String,
        currencies: currencies,
      );
    } catch (e, s) {
      Logging.instance.log("SPExchange.fromJson failed to parse: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final map = {
      "timestamp": timestamp,
      "currency_from": currencyFrom,
      "currency_to": currencyTo,
      "amount_from": amountFrom,
      "amount_to": amountTo,
      "address_from": addressFrom,
      "address_to": addressTo,
      "extra_id_from": extraIdFrom,
      "extra_id_to": extraIdTo,
      "status": status,
      "tx_from": txFrom,
      "tx_to": txTo,
      "currencies": currencies,
    };

    return map;
  }

  SPExchange copyWith({
    int? timestamp,
    String? currencyFrom,
    String? currencyTo,
    String? amountFrom,
    String? amountTo,
    String? addressFrom,
    String? addressTo,
    String? extraIdFrom,
    String? extraIdTo,
    String? status,
    String? txFrom,
    String? txTo,
    List<SPCurrency>? currencies,
  }) {
    return SPExchange(
      timestamp: timestamp ?? this.timestamp,
      currencyFrom: currencyFrom ?? this.currencyFrom,
      currencyTo: currencyTo ?? this.currencyTo,
      amountFrom: amountFrom ?? this.amountFrom,
      amountTo: amountTo ?? this.amountTo,
      addressFrom: addressFrom ?? this.addressFrom,
      addressTo: addressTo ?? this.addressTo,
      extraIdFrom: extraIdFrom ?? this.extraIdFrom,
      extraIdTo: extraIdTo ?? this.extraIdTo,
      status: status ?? this.status,
      txFrom: txFrom ?? this.txFrom,
      txTo: txTo ?? this.txTo,
      currencies: currencies ?? this.currencies,
    );
  }

  @override
  String toString() {
    return "SPExchange: ${toJson()}";
  }
}
