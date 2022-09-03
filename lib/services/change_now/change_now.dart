import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stackwallet/external_api_keys.dart';
import 'package:stackwallet/models/exchange/change_now/available_floating_rate_pair.dart';
import 'package:stackwallet/models/exchange/change_now/change_now_response.dart';
import 'package:stackwallet/models/exchange/change_now/currency.dart';
import 'package:stackwallet/models/exchange/change_now/estimated_exchange_amount.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction_status.dart';
import 'package:stackwallet/utilities/logger.dart';

enum CNEstimateType { direct, reverse }

enum CNFlowType implements Comparable<CNFlowType> {
  standard("standard"),
  fixedRate("fixed-rate");

  const CNFlowType(this.value);

  final String value;

  @override
  int compareTo(CNFlowType other) => value.compareTo(other.value);
}

class ChangeNow {
  static const String scheme = "https";
  static const String authority = "api.changenow.io";
  static const String apiVersion = "/v2";

  ChangeNow._();
  static final ChangeNow _instance = ChangeNow._();
  static ChangeNow get instance => _instance;

  /// set this to override using standard http client. Useful for testing
  http.Client? client;

  Uri _buildUri(String path, Map<String, dynamic>? params) {
    return Uri.https(authority, apiVersion + path, params);
  }

  Future<dynamic> _makeGetRequest(Uri uri, String apiKey) async {
    final client = this.client ?? http.Client();
    try {
      final response = await client.get(
        uri,
        headers: {
          // 'Content-Type': 'application/json',
          'x-changenow-api-key': apiKey,
        },
      );

      print("================");
      print(uri);
      print(response.body);
      print("================");

      final parsed = jsonDecode(response.body);

      return parsed;
    } catch (e, s) {
      Logging.instance
          .log("_makeRequest($uri) threw: $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<dynamic> _makePostRequest(
    Uri uri,
    Map<String, String> body,
    String apiKey,
  ) async {
    final client = this.client ?? http.Client();
    try {
      final response = await client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-changenow-api-key': apiKey,
        },
        body: jsonEncode(body),
      );

      final parsed = jsonDecode(response.body);

      return parsed;
    } catch (e, s) {
      Logging.instance
          .log("_makeRequest($uri) threw: $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  /// This API endpoint returns the list of available currencies.
  ///
  /// Set [active] to true to return only active currencies.
  /// Set [fixedRate] to true to return only currencies available on a fixed-rate flow.
  Future<ChangeNowResponse<List<Currency>>> getAvailableCurrencies({
    required CNFlowType flow,
    bool? active,
    String? apiKey,
  }) async {
    Map<String, dynamic>? params = {};

    params["flow"] = flow.value;

    if (active != null) {
      params.addAll({"active": active.toString()});
    }

    final uri = _buildUri("/exchange/currencies", params);

    try {
      // json array is expected here
      final jsonArray = await _makeGetRequest(uri, apiKey ?? kChangeNowApiKey);

      try {
        final result = await compute(
            _parseAvailableCurrenciesJson, jsonArray as List<dynamic>);
        return result;
      } catch (e, s) {
        Logging.instance.log("getAvailableCurrencies exception: $e\n$s",
            level: LogLevel.Error);
        return ChangeNowResponse(
          exception: ChangeNowException(
            "Error: $jsonArray",
            ChangeNowExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log("getAvailableCurrencies exception: $e\n$s",
          level: LogLevel.Error);
      return ChangeNowResponse(
        exception: ChangeNowException(
          e.toString(),
          ChangeNowExceptionType.generic,
        ),
      );
    }
  }

  ChangeNowResponse<List<Currency>> _parseAvailableCurrenciesJson(
      List<dynamic> jsonArray) {
    try {
      List<Currency> currencies = [];

      for (final json in jsonArray) {
        try {
          currencies
              .add(Currency.fromJson(Map<String, dynamic>.from(json as Map)));
        } catch (_) {
          return ChangeNowResponse(
              exception: ChangeNowException("Failed to serialize $json",
                  ChangeNowExceptionType.serializeResponseError));
        }
      }

      return ChangeNowResponse(value: currencies);
    } catch (_) {
      rethrow;
    }
  }
  //
  // /// This API endpoint returns the array of markets available for the specified currency be default.
  // /// The availability of a particular pair is determined by the 'isAvailable' field.
  // ///
  // /// Required [ticker] to fetch paired currencies for.
  // /// Set [fixedRate] to true to return only currencies available on a fixed-rate flow.
  // Future<ChangeNowResponse<List<Currency>>> getPairedCurrencies({
  //   required String ticker,
  //   bool? fixedRate,
  // }) async {
  //   Map<String, dynamic>? params;
  //
  //   if (fixedRate != null) {
  //     params = {};
  //     params.addAll({"fixedRate": fixedRate.toString()});
  //   }
  //
  //   final uri = _buildUri("/currencies-to/$ticker", params);
  //
  //   try {
  //     // json array is expected here
  //     final jsonArray = (await _makeGetRequest(uri)) as List;
  //
  //     List<Currency> currencies = [];
  //     try {
  //       for (final json in jsonArray) {
  //         try {
  //           currencies
  //               .add(Currency.fromJson(Map<String, dynamic>.from(json as Map)));
  //         } catch (_) {
  //           return ChangeNowResponse(
  //             exception: ChangeNowException(
  //               "Failed to serialize $json",
  //               ChangeNowExceptionType.serializeResponseError,
  //             ),
  //           );
  //         }
  //       }
  //     } catch (e, s) {
  //       Logging.instance.log("getPairedCurrencies exception: $e\n$s",
  //           level: LogLevel.Error);
  //       return ChangeNowResponse(
  //           exception: ChangeNowException("Error: $jsonArray",
  //               ChangeNowExceptionType.serializeResponseError));
  //     }
  //     return ChangeNowResponse(value: currencies);
  //   } catch (e, s) {
  //     Logging.instance
  //         .log("getPairedCurrencies exception: $e\n$s", level: LogLevel.Error);
  //     return ChangeNowResponse(
  //       exception: ChangeNowException(
  //         e.toString(),
  //         ChangeNowExceptionType.generic,
  //       ),
  //     );
  //   }
  // }

  /// The API endpoint returns minimal payment amount required to make
  /// an exchange of [fromTicker] to [toTicker].
  /// If you try to exchange less, the transaction will most likely fail.
  Future<ChangeNowResponse<Decimal>> getMinimalExchangeAmount({
    required String fromTicker,
    required String toTicker,
    String? fromNetwork,
    String? toNetwork,
    CNFlowType flow = CNFlowType.standard,
    String? apiKey,
  }) async {
    Map<String, dynamic>? params = {
      "fromCurrency": fromTicker,
      "toCurrency": toTicker,
      "flow": flow.value,
    };

    if (fromNetwork != null) {
      params["fromNetwork"] = fromNetwork;
    }

    if (toNetwork != null) {
      params["toNetwork"] = toNetwork;
    }

    final uri = _buildUri("/exchange/min-amount", params);

    try {
      // simple json object is expected here
      final json = await _makeGetRequest(uri, apiKey ?? kChangeNowApiKey);

      try {
        final value = Decimal.parse(json["minAmount"].toString());
        return ChangeNowResponse(value: value);
      } catch (_) {
        return ChangeNowResponse(
          exception: ChangeNowException(
            "Failed to serialize $json",
            ChangeNowExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log("getMinimalExchangeAmount exception: $e\n$s",
          level: LogLevel.Error);
      return ChangeNowResponse(
        exception: ChangeNowException(
          e.toString(),
          ChangeNowExceptionType.generic,
        ),
      );
    }
  }

  /// This API endpoint returns estimated exchange amount for the exchange and
  /// some additional fields. Accepts to and from currencies, currencies'
  /// networks, exchange flow, and RateID.
  Future<ChangeNowResponse<EstimatedExchangeAmount>>
      getEstimatedExchangeAmount({
    required String fromTicker,
    required String toTicker,
    required CNEstimateType fromOrTo,
    required Decimal amount,
    String? fromNetwork,
    String? toNetwork,
    CNFlowType flow = CNFlowType.standard,
    String? apiKey,
  }) async {
    Map<String, dynamic>? params = {
      "fromCurrency": fromTicker,
      "toCurrency": toTicker,
      "flow": flow.value,
      "type": fromOrTo.name,
    };

    switch (fromOrTo) {
      case CNEstimateType.direct:
        params["fromAmount"] = amount.toString();
        break;
      case CNEstimateType.reverse:
        params["toAmount"] = amount.toString();
        break;
    }

    if (fromNetwork != null) {
      params["fromNetwork"] = fromNetwork;
    }

    if (toNetwork != null) {
      params["toNetwork"] = toNetwork;
    }

    if (flow == CNFlowType.fixedRate) {
      params["useRateId"] = true;
    }

    final uri = _buildUri("/exchange/estimated-amount", params);

    try {
      // simple json object is expected here
      final json = await _makeGetRequest(uri, apiKey ?? kChangeNowApiKey);

      try {
        final value = EstimatedExchangeAmount.fromJson(
            Map<String, dynamic>.from(json as Map));
        return ChangeNowResponse(value: value);
      } catch (_) {
        return ChangeNowResponse(
          exception: ChangeNowException(
            "Failed to serialize $json",
            ChangeNowExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log("getEstimatedExchangeAmount exception: $e\n$s",
          level: LogLevel.Error);
      return ChangeNowResponse(
        exception: ChangeNowException(
          e.toString(),
          ChangeNowExceptionType.generic,
        ),
      );
    }
  }
  //
  // /// This API endpoint returns the list of all the pairs available on a
  // /// fixed-rate flow. Some currencies get enabled or disabled from time to
  // /// time and the market info gets updates, so make sure to refresh the list
  // /// occasionally. One time per minute is sufficient.
  // Future<ChangeNowResponse<List<FixedRateMarket>>>
  //     getAvailableFixedRateMarkets({
  //   String? apiKey,
  // }) async {
  //   final uri = _buildUri(
  //       "/market-info/fixed-rate/${apiKey ?? kChangeNowApiKey}", null);
  //
  //   try {
  //     // json array is expected here
  //     final jsonArray = await _makeGetRequest(uri);
  //
  //     try {
  //       final result =
  //           await compute(_parseFixedRateMarketsJson, jsonArray as List);
  //       return result;
  //     } catch (e, s) {
  //       Logging.instance.log("getAvailableFixedRateMarkets exception: $e\n$s",
  //           level: LogLevel.Error);
  //       return ChangeNowResponse(
  //         exception: ChangeNowException(
  //           "Error: $jsonArray",
  //           ChangeNowExceptionType.serializeResponseError,
  //         ),
  //       );
  //     }
  //   } catch (e, s) {
  //     Logging.instance.log("getAvailableFixedRateMarkets exception: $e\n$s",
  //         level: LogLevel.Error);
  //     return ChangeNowResponse(
  //       exception: ChangeNowException(
  //         e.toString(),
  //         ChangeNowExceptionType.generic,
  //       ),
  //     );
  //   }
  // }
  //
  // ChangeNowResponse<List<FixedRateMarket>> _parseFixedRateMarketsJson(
  //     List<dynamic> jsonArray) {
  //   try {
  //     List<FixedRateMarket> markets = [];
  //     for (final json in jsonArray) {
  //       try {
  //         markets.add(
  //             FixedRateMarket.fromJson(Map<String, dynamic>.from(json as Map)));
  //       } catch (_) {
  //         return ChangeNowResponse(
  //             exception: ChangeNowException("Failed to serialize $json",
  //                 ChangeNowExceptionType.serializeResponseError));
  //       }
  //     }
  //     return ChangeNowResponse(value: markets);
  //   } catch (_) {
  //     rethrow;
  //   }
  // }

  /// The API endpoint creates a transaction, generates an address for
  /// sending funds and returns transaction attributes.
  Future<ChangeNowResponse<ExchangeTransaction>> createExchangeTransaction({
    required String fromTicker,
    required String fromNetwork,
    required String toTicker,
    required String toNetwork,
    required String receivingAddress,
    required Decimal amount,
    required CNEstimateType fromOrTo,
    required CNFlowType flow,
    String rateId = "",
    String extraId = "",
    String userId = "",
    String contactEmail = "",
    String refundAddress = "",
    String refundExtraId = "",
    String? apiKey,
  }) async {
    final Map<String, String> map = {
      "fromCurrency": fromTicker,
      "fromNetwork": fromNetwork,
      "toCurrency": toTicker,
      "toNetwork": toNetwork,
      "address": receivingAddress,
      "extraId": extraId,
      "userId": userId,
      "contactEmail": contactEmail,
      "refundAddress": refundAddress,
      "refundExtraId": refundExtraId,
      "payload": "",
      "flow": flow.value,
      "type": fromOrTo.name,
      "rateId": rateId,
    };

    switch (fromOrTo) {
      case CNEstimateType.direct:
        map["fromAmount"] = amount.toString();
        map["toAmount"] = "";
        break;
      case CNEstimateType.reverse:
        map["fromAmount"] = "";
        map["toAmount"] = amount.toString();
        break;
    }

    final uri = _buildUri("/exchange", null);

    try {
      // simple json object is expected here
      final json = await _makePostRequest(uri, map, apiKey ?? kChangeNowApiKey);

      // pass in date to prevent using default 1970 date
      json["date"] = DateTime.now().toString();

      try {
        final value = ExchangeTransaction.fromJson(
            Map<String, dynamic>.from(json as Map));
        return ChangeNowResponse(value: value);
      } catch (_) {
        return ChangeNowResponse(
          exception: ChangeNowException(
            "Failed to serialize $json",
            ChangeNowExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance.log(
          "createStandardExchangeTransaction exception: $e\n$s",
          level: LogLevel.Error);
      return ChangeNowResponse(
        exception: ChangeNowException(
          e.toString(),
          ChangeNowExceptionType.generic,
        ),
      );
    }
  }

  Future<ChangeNowResponse<ExchangeTransactionStatus>> getTransactionStatus({
    required String id,
    String? apiKey,
  }) async {
    final uri = _buildUri("/exchange/by-id", {"id": id});

    try {
      // simple json object is expected here
      final json = await _makeGetRequest(uri, apiKey ?? kChangeNowApiKey);

      try {
        final value = ExchangeTransactionStatus.fromJson(
            Map<String, dynamic>.from(json as Map));
        return ChangeNowResponse(value: value);
      } catch (_) {
        return ChangeNowResponse(
          exception: ChangeNowException(
            "Failed to serialize $json",
            ChangeNowExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance
          .log("getTransactionStatus exception: $e\n$s", level: LogLevel.Error);
      return ChangeNowResponse(
        exception: ChangeNowException(
          e.toString(),
          ChangeNowExceptionType.generic,
        ),
      );
    }
  }

  Future<ChangeNowResponse<List<AvailablePair>>> getAvailablePairs({
    String? fromTicker,
    String? toTicker,
    String? fromNetwork,
    String? toNetwork,
    CNFlowType? flow,
    String? apiKey,
  }) async {
    Map<String, dynamic> params = {};

    if (fromTicker != null) {
      params["fromCurrency"] = fromTicker;
    }

    if (toTicker != null) {
      params["toCurrency"] = toTicker;
    }

    if (fromNetwork != null) {
      params["fromNetwork"] = fromNetwork;
    }

    if (toNetwork != null) {
      params["toNetwork"] = toNetwork;
    }

    if (flow != null) {
      params["flow"] = flow.value;
    }

    final uri = _buildUri("/exchange/available-pairs", params);

    try {
      // json array is expected here
      final jsonArray = await _makeGetRequest(uri, apiKey ?? kChangeNowApiKey);

      try {
        final result =
            await compute(_parseAvailablePairsJson, jsonArray as List);
        return result;
      } catch (e, s) {
        Logging.instance
            .log("getAvailablePairs exception: $e\n$s", level: LogLevel.Error);
        return ChangeNowResponse(
          exception: ChangeNowException(
            "Error: $jsonArray",
            ChangeNowExceptionType.serializeResponseError,
          ),
        );
      }
    } catch (e, s) {
      Logging.instance
          .log("getAvailablePairs exception: $e\n$s", level: LogLevel.Error);
      return ChangeNowResponse(
        exception: ChangeNowException(
          e.toString(),
          ChangeNowExceptionType.generic,
        ),
      );
    }
  }

  ChangeNowResponse<List<AvailablePair>> _parseAvailablePairsJson(
      List<dynamic> jsonArray) {
    try {
      List<AvailablePair> pairs = [];
      for (final json in jsonArray) {
        try {
          final pair =
              AvailablePair.fromJson(Map<String, dynamic>.from(json as Map));
          pairs.add(pair);
          // final List<String> stringPair = (json as String).split("_");
          // pairs.add(AvailablePair(
          //     from: stringPair[0], toTicker: stringPair[1]));
        } catch (_) {
          return ChangeNowResponse(
              exception: ChangeNowException("Failed to serialize $json",
                  ChangeNowExceptionType.serializeResponseError));
        }
      }
      return ChangeNowResponse(value: pairs);
    } catch (_) {
      rethrow;
    }
  }
}
