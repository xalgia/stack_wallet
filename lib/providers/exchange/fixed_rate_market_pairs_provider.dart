import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/exchange/change_now/available_floating_rate_pair.dart';

final fixedRateMarketPairsStateProvider =
    StateProvider<List<AvailablePair>>((ref) => []);
