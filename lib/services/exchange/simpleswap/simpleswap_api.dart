import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stackwallet/external_api_keys.dart';
import 'package:stackwallet/models/exchange/simpleswap/simpleswap_response.dart';
import 'package:stackwallet/models/exchange/simpleswap/sp_currency.dart';
import 'package:stackwallet/models/exchange/simpleswap/sp_exchange.dart';
import 'package:stackwallet/models/exchange/simpleswap/sp_range.dart';
import 'package:stackwallet/utilities/logger.dart';

class SimpleSwapAPI {
  static const String scheme = "https";
  static const String authority = "api.simpleswap.io";
  static const String apiVersion = "/v1";

  SimpleSwapAPI._();
  static final SimpleSwapAPI _instance = SimpleSwapAPI._();
  static SimpleSwapAPI get instance => _instance;

  /// set this to override using standard http client. Useful for testing
  http.Client? client;

  Uri _buildUri(String path, Map<String, String>? params) {
    return Uri.https(authority, apiVersion + path, params);
  }

  Future<dynamic> _makeGetRequest(Uri uri) async {
    final client = this.client ?? http.Client();
    try {
      final response = await client.get(
        uri,
      );

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
    Map<String, dynamic> body,
  ) async {
    final client = this.client ?? http.Client();
    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        return parsed;
      }

      throw Exception("response: ${response.body}");
    } catch (e, s) {
      Logging.instance
          .log("_makeRequest($uri) threw: $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<SimpleSwapResponse<SPExchange>> createNewExchange({
    required bool isFixedRate,
    required String currencyFrom,
    required String currencyTo,
    required String addressTo,
    required String userRefundAddress,
    required String userRefundExtraId,
    required String amount,
    String? extraIdTo,
    String? apiKey,
  }) async {
    Map<String, String> body = {
      "fixed": isFixedRate.toString(),
      "currency_from": currencyFrom,
      "currency_to": currencyTo,
      "addressTo": addressTo,
      "userRefundAddress": userRefundAddress,
      "userRefundExtraId": userRefundExtraId,
      "amount": amount,
    };

    final uri =
        _buildUri("/create_exchange", {"api_key": apiKey ?? kSimpleSwapApiKey});

    try {
      final jsonObject = await _makePostRequest(uri, body);
      print("================================");
      print(jsonObject);
      print("================================");

      final spExchange =
          SPExchange.fromJson(Map<String, dynamic>.from(jsonObject as Map));
      return SimpleSwapResponse(value: spExchange, exception: null);
    } catch (e, s) {
      Logging.instance.log("getAvailableCurrencies exception: $e\n$s",
          level: LogLevel.Error);
      return SimpleSwapResponse(
        exception: SimpleSwapException(
          e.toString(),
          SimpleSwapExceptionType.generic,
        ),
        value: null,
      );
    }
  }

  Future<SimpleSwapResponse<List<SPCurrency>>> getAllCurrencies({
    String? apiKey,
  }) async {
    final uri = _buildUri(
        "/get_all_currencies", {"api_key": apiKey ?? kSimpleSwapApiKey});

    try {
      final jsonArray = await _makeGetRequest(uri);

      return await compute(_parseAvailableCurrenciesJson, jsonArray as List);
    } catch (e, s) {
      Logging.instance.log("getAvailableCurrencies exception: $e\n$s",
          level: LogLevel.Error);
      return SimpleSwapResponse(
        exception: SimpleSwapException(
          e.toString(),
          SimpleSwapExceptionType.generic,
        ),
      );
    }
  }

  SimpleSwapResponse<List<SPCurrency>> _parseAvailableCurrenciesJson(
      List<dynamic> jsonArray) {
    try {
      List<SPCurrency> currencies = [];

      for (final json in jsonArray) {
        try {
          currencies
              .add(SPCurrency.fromJson(Map<String, dynamic>.from(json as Map)));
        } catch (_) {
          return SimpleSwapResponse(
              exception: SimpleSwapException("Failed to serialize $json",
                  SimpleSwapExceptionType.serializeResponseError));
        }
      }

      return SimpleSwapResponse(value: currencies);
    } catch (e, s) {
      Logging.instance.log("_parseAvailableCurrenciesJson exception: $e\n$s",
          level: LogLevel.Error);
      return SimpleSwapResponse(
        exception: SimpleSwapException(
          e.toString(),
          SimpleSwapExceptionType.generic,
        ),
      );
    }
  }

  Future<SimpleSwapResponse<SPCurrency>> getCurrency({
    required String symbol,
    String? apiKey,
  }) async {
    final uri = _buildUri(
      "/get_currency",
      {
        "api_key": apiKey ?? kSimpleSwapApiKey,
        "symbol": symbol,
      },
    );

    try {
      final jsonObject = await _makeGetRequest(uri);

      return SimpleSwapResponse(
          value: SPCurrency.fromJson(
              Map<String, dynamic>.from(jsonObject as Map)));
    } catch (e, s) {
      Logging.instance
          .log("getCurrency exception: $e\n$s", level: LogLevel.Error);
      return SimpleSwapResponse(
        exception: SimpleSwapException(
          e.toString(),
          SimpleSwapExceptionType.generic,
        ),
      );
    }
  }

  /// returns a map where the key currency symbol is a valid pair with any of
  /// the symbols in its value list
  Future<SimpleSwapResponse<Map<String, List<String>>>> getAllPairs({
    required bool isFixedRate,
    String? apiKey,
  }) async {
    final uri = _buildUri(
      "/get_all_pairs",
      {
        "api_key": apiKey ?? kSimpleSwapApiKey,
        "fixed": isFixedRate.toString(),
      },
    );

    try {
      final jsonObject = await _makeGetRequest(uri);
      final Map<String, List<String>> result = {};

      for (final entry in (jsonObject as Map).entries) {
        result[entry.key as String] = List<String>.from(entry.value as List);
      }

      return SimpleSwapResponse(value: result);
    } catch (e, s) {
      Logging.instance
          .log("getAllPairs exception: $e\n$s", level: LogLevel.Error);
      return SimpleSwapResponse(
        exception: SimpleSwapException(
          e.toString(),
          SimpleSwapExceptionType.generic,
        ),
      );
    }
  }

  /// returns the estimated amount as a string
  Future<SimpleSwapResponse<String>> getEstimated({
    required bool isFixedRate,
    required String currencyFrom,
    required String currencyTo,
    required String amount,
    String? apiKey,
  }) async {
    final uri = _buildUri(
      "/get_estimated",
      {
        "api_key": apiKey ?? kSimpleSwapApiKey,
        "fixed": isFixedRate.toString(),
        "currency_from": currencyFrom,
        "currency_to": currencyTo,
        "amount": amount,
      },
    );

    try {
      final jsonObject = await _makeGetRequest(uri);

      return SimpleSwapResponse(value: jsonObject as String);
    } catch (e, s) {
      Logging.instance
          .log("getEstimated exception: $e\n$s", level: LogLevel.Error);
      return SimpleSwapResponse(
        exception: SimpleSwapException(
          e.toString(),
          SimpleSwapExceptionType.generic,
        ),
      );
    }
  }

  // currently only returns 3 btc markets so.... ?
  // Future<SimpleSwapResponse<String>> getFullFixedRateMarketInfo({
  //   required String symbol,
  //   String? apiKey,
  // }) async {
  //   final uri = _buildUri(
  //     "/get_market_info",
  //     {
  //       "api_key": apiKey ?? kSimpleSwapApiKey,
  //       "symbol": symbol,
  //     },
  //   );
  //
  //   try {
  //     final jsonObject = await _makeGetRequest(uri);
  //
  //     print("===============================");
  //     for (final e in jsonObject as List) {
  //       print(e);
  //     }
  //     print("===============================");
  //
  //     return SimpleSwapResponse(value: jsonObject as String);
  //   } catch (e, s) {
  //     Logging.instance.log("getFullFixedRateMarketInfo exception: $e\n$s",
  //         level: LogLevel.Error);
  //     return SimpleSwapResponse(
  //       exception: SimpleSwapException(
  //         e.toString(),
  //         SimpleSwapExceptionType.generic,
  //       ),
  //     );
  //   }
  // }

  /// returns the exchange for the given id
  Future<SimpleSwapResponse<SPExchange>> getExchange({
    required String exchangeId,
    String? apiKey,
  }) async {
    final uri = _buildUri(
      "/get_estimated",
      {
        "api_key": apiKey ?? kSimpleSwapApiKey,
        "id": exchangeId,
      },
    );

    try {
      final jsonObject = await _makeGetRequest(uri);

      return SimpleSwapResponse(
          value: SPExchange.fromJson(
              Map<String, dynamic>.from(jsonObject as Map)));
    } catch (e, s) {
      Logging.instance
          .log("getExchange exception: $e\n$s", level: LogLevel.Error);
      return SimpleSwapResponse(
        exception: SimpleSwapException(
          e.toString(),
          SimpleSwapExceptionType.generic,
        ),
      );
    }
  }

  /// returns the minimal exchange amount
  Future<SimpleSwapResponse<SPRange>> getRange({
    required bool isFixedRate,
    required String currencyFrom,
    required String currencyTo,
    String? apiKey,
  }) async {
    final uri = _buildUri(
      "/get_ranges",
      {
        "api_key": apiKey ?? kSimpleSwapApiKey,
        "fixed": isFixedRate.toString(),
        "currency_from": currencyFrom,
        "currency_to": currencyTo,
      },
    );

    try {
      final jsonObject = await _makeGetRequest(uri);

      return SimpleSwapResponse(
          value:
              SPRange.fromJson(Map<String, dynamic>.from(jsonObject as Map)));
    } catch (e, s) {
      Logging.instance.log("getRange exception: $e\n$s", level: LogLevel.Error);
      return SimpleSwapResponse(
        exception: SimpleSwapException(
          e.toString(),
          SimpleSwapExceptionType.generic,
        ),
      );
    }
  }
}
