import 'package:decimal/decimal.dart';
import 'package:stackwallet/utilities/logger.dart';

class SPRange {
  final Decimal? min;
  final Decimal? max;

  SPRange({this.min, this.max});

  factory SPRange.fromJson(Map<String, dynamic> json) {
    try {
      return SPRange(
        min: Decimal.tryParse(json["min"] as String? ?? ""),
        max: Decimal.tryParse(json["max"] as String? ?? ""),
      );
    } catch (e, s) {
      Logging.instance.log("SPExchange.fromJson failed to parse: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final map = {
      "min": min?.toString(),
      "max": max?.toString(),
    };

    return map;
  }

  SPRange copyWith({
    Decimal? min,
    Decimal? max,
  }) {
    return SPRange(
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }

  @override
  String toString() {
    return "SPRange: ${toJson()}";
  }
}
