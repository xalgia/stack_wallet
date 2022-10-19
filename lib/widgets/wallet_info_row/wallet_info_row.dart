import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/wallet_info_row/sub_widgets/wallet_info_row_balance_future.dart';
import 'package:stackwallet/widgets/wallet_info_row/sub_widgets/wallet_info_row_coin_icon.dart';

class WalletInfoRow extends ConsumerWidget {
  const WalletInfoRow({
    Key? key,
    required this.walletId,
    this.onPressed,
  }) : super(key: key);

  final String walletId;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(ref
        .watch(walletsChangeNotifierProvider.notifier)
        .getManagerProvider(walletId));

    if (Util.isDesktop) {
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          color: Colors.transparent,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    WalletInfoCoinIcon(coin: manager.coin),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      manager.walletName,
                      style: STextStyles.desktopTextExtraSmall(context).copyWith(
                        color:
                            Theme.of(context).extension<StackColors>()!.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: WalletInfoRowBalanceFuture(
                  walletId: walletId,
                ),
              ),
              Expanded(
                flex: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SvgPicture.asset(
                      Assets.svg.chevronRight,
                      width: 20,
                      height: 20,
                      color: Theme.of(context)
                          .extension<StackColors>()!
                          .textSubtitle1,
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      );
    } else {
      return Row(
        children: [
          WalletInfoCoinIcon(coin: manager.coin),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  manager.walletName,
                  style: STextStyles.titleBold12(context),
                ),
                const SizedBox(
                  height: 2,
                ),
                WalletInfoRowBalanceFuture(walletId: walletId),
              ],
            ),
          ),
        ],
      );
    }
  }
}
