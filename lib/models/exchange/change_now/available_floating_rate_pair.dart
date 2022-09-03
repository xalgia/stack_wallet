import 'package:flutter/material.dart';
import 'package:stackwallet/services/change_now/change_now.dart';

class AvailablePair {
  final String fromCurrency;
  final String toCurrency;
  final String fromNetwork;
  final String toNetwork;
  final List<CNFlowType> flow;

  AvailablePair({
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromNetwork,
    required this.toNetwork,
    required this.flow,
  });

  bool get isFixedRate => flow.contains(CNFlowType.fixedRate);

  bool get isStandardRate => flow.contains(CNFlowType.standard);

  factory AvailablePair.fromJson(Map<String, dynamic> json) {
    try {
      List<CNFlowType> flows = [];
      if (json["flow"][CNFlowType.standard.value] == true) {
        flows.add(CNFlowType.standard);
      }
      if (json["flow"][CNFlowType.fixedRate.value] == true) {
        flows.add(CNFlowType.fixedRate);
      }

      return AvailablePair(
        fromCurrency: json["fromCurrency"] as String,
        toCurrency: json["toCurrency"] as String,
        fromNetwork: json["fromNetwork"] as String,
        toNetwork: json["toNetwork"] as String,
        flow: flows,
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final map = {
      "fromCurrency": fromCurrency,
      "toCurrency": toCurrency,
      "fromNetwork": fromNetwork,
      "toNetwork": toNetwork,
      "flow": {
        CNFlowType.standard.value: flow.contains(CNFlowType.standard),
        CNFlowType.fixedRate.value: flow.contains(CNFlowType.fixedRate),
      },
    };

    return map;
  }

  AvailablePair copyWith({
    String? fromCurrency,
    String? toCurrency,
    String? fromNetwork,
    String? toNetwork,
    List<CNFlowType>? flow,
  }) {
    return AvailablePair(
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      fromNetwork: fromNetwork ?? this.fromNetwork,
      toNetwork: toNetwork ?? this.toNetwork,
      flow: flow ?? this.flow,
    );
  }

  @override
  bool operator ==(other) {
    return other is AvailablePair &&
        fromCurrency == other.fromCurrency &&
        toCurrency == other.toCurrency &&
        fromNetwork == other.fromNetwork &&
        toNetwork == other.toNetwork &&
        flow.length == other.flow.length &&
        flow.every((element) => other.flow.contains(element));
  }

  @override
  int get hashCode => hashValues(fromCurrency, toCurrency);

  @override
  String toString() {
    return "AvailablePair: ${toJson()}";
  }
}
