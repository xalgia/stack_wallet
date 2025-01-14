import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/models/models.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/tx_icon.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/dialogs/cancelling_transaction_progress_dialog.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/edit_note_view.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/providers/global/address_book_service_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/epiccash/epiccash_wallet.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/block_explorers.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/icon_widgets/copy_icon.dart';
import 'package:stackwallet/widgets/icon_widgets/pencil_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionDetailsView extends ConsumerStatefulWidget {
  const TransactionDetailsView({
    Key? key,
    required this.transaction,
    required this.walletId,
    required this.coin,
  }) : super(key: key);

  static const String routeName = "/transactionDetails";

  final Transaction transaction;
  final String walletId;
  final Coin coin;

  @override
  ConsumerState<TransactionDetailsView> createState() =>
      _TransactionDetailsViewState();
}

class _TransactionDetailsViewState
    extends ConsumerState<TransactionDetailsView> {
  late final bool isDesktop;
  late Transaction _transaction;
  late final String walletId;

  late final Coin coin;
  late final Decimal amount;
  late final Decimal fee;
  late final String amountPrefix;

  bool showFeePending = false;

  @override
  void initState() {
    isDesktop = Util.isDesktop;
    _transaction = widget.transaction;
    walletId = widget.walletId;

    coin = widget.coin;
    amount = Format.satoshisToAmount(_transaction.amount);
    fee = Format.satoshisToAmount(_transaction.fees);

    if ((coin == Coin.firo || coin == Coin.firoTestNet) &&
        _transaction.subType == "mint") {
      amountPrefix = "";
    } else {
      amountPrefix = _transaction.txType.toLowerCase() == "sent" ? "-" : "+";
    }

    // if (coin == Coin.firo || coin == Coin.firoTestNet) {
    //   showFeePending = true;
    // } else {
    //   showFeePending = false;
    // }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String whatIsIt(String type) {
    if (coin == Coin.firo || coin == Coin.firoTestNet) {
      if (_transaction.subType == "mint") {
        if (_transaction.confirmedStatus) {
          return "Minted";
        } else {
          return "Minting";
        }
      }
    }

    if (type == "Received") {
      // if (_transaction.isMinting) {
      //   return "Minting";
      // } else
      if (_transaction.confirmedStatus) {
        return "Received";
      } else {
        return "Receiving";
      }
    } else if (type == "Sent") {
      if (_transaction.confirmedStatus) {
        return "Sent";
      } else {
        return "Sending";
      }
    } else {
      return type;
    }
  }

  Future<String> fetchContactNameFor(String address) async {
    if (address.isEmpty) {
      return address;
    }
    try {
      final contacts = ref.read(addressBookServiceProvider).contacts.where(
          (element) => element.addresses
              .where((element) => element.address == address)
              .isNotEmpty);
      if (contacts.isNotEmpty) {
        return contacts.first.name;
      } else {
        return address;
      }
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Warning);
      return address;
    }
  }

  String _note = "";

  Future<bool> showExplorerWarning(String explorer) async {
    final bool? shouldContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StackDialog(
        title: "Attention",
        message:
            "You are about to view this transaction in a block explorer. The explorer may log your IP address and link it to the transaction. Only proceed if you trust $explorer.",
        icon: Row(
          children: [
            Consumer(builder: (_, ref, __) {
              return Checkbox(
                value: ref.watch(prefsChangeNotifierProvider
                    .select((value) => value.hideBlockExplorerWarning)),
                onChanged: (value) {
                  if (value is bool) {
                    ref
                        .read(prefsChangeNotifierProvider)
                        .hideBlockExplorerWarning = value;
                    setState(() {});
                  }
                },
              );
            }),
            Text(
              "Never show again",
              style: STextStyles.smallMed14(context),
            )
          ],
        ),
        leftButton: TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text(
            "Cancel",
            style: STextStyles.button(context).copyWith(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .accentColorDark),
          ),
        ),
        rightButton: TextButton(
          style: Theme.of(context)
              .extension<StackColors>()!
              .getPrimaryEnabledButtonColor(context),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text(
            "Continue",
            style: STextStyles.button(context),
          ),
        ),
      ),
    );
    return shouldContinue ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDesktop
          ? Colors.transparent
          : Theme.of(context).extension<StackColors>()!.background,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor:
                  Theme.of(context).extension<StackColors>()!.background,
              leading: AppBarBackButton(
                onPressed: () async {
                  // if (FocusScope.of(context).hasFocus) {
                  //   FocusScope.of(context).unfocus();
                  //   await Future<void>.delayed(Duration(milliseconds: 50));
                  // }
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                "Transaction details",
                style: STextStyles.navBarTitle(context),
              ),
            ),
      body: Padding(
        padding: isDesktop
            ? const EdgeInsets.only(left: 32)
            : const EdgeInsets.all(12),
        child: Column(
          children: [
            if (isDesktop)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Transaction details",
                    style: STextStyles.desktopH3(context),
                  ),
                  const DesktopDialogCloseButton(),
                ],
              ),
            Expanded(
              child: Padding(
                padding: isDesktop
                    ? const EdgeInsets.only(
                        right: 32,
                        bottom: 32,
                      )
                    : const EdgeInsets.all(0),
                child: ConditionalParent(
                  condition: isDesktop,
                  builder: (child) {
                    return RoundedWhiteContainer(
                      borderColor: isDesktop
                          ? Theme.of(context)
                              .extension<StackColors>()!
                              .background
                          : null,
                      padding: const EdgeInsets.all(0),
                      child: child,
                    );
                  },
                  child: SingleChildScrollView(
                    primary: isDesktop ? false : null,
                    child: Padding(
                      padding: isDesktop
                          ? const EdgeInsets.all(0)
                          : const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RoundedWhiteContainer(
                            padding: isDesktop
                                ? const EdgeInsets.all(0)
                                : const EdgeInsets.all(12),
                            child: Container(
                              decoration: isDesktop
                                  ? BoxDecoration(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .background,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(
                                          Constants.size.circularBorderRadius,
                                        ),
                                      ),
                                    )
                                  : null,
                              child: Padding(
                                padding: isDesktop
                                    ? const EdgeInsets.all(12)
                                    : const EdgeInsets.all(0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (isDesktop)
                                      Row(
                                        children: [
                                          TxIcon(
                                            transaction: _transaction,
                                          ),
                                          const SizedBox(
                                            width: 16,
                                          ),
                                          SelectableText(
                                            _transaction.isCancelled
                                                ? "Cancelled"
                                                : whatIsIt(_transaction.txType),
                                            style:
                                                STextStyles.desktopTextMedium(
                                                    context),
                                          ),
                                        ],
                                      ),
                                    Column(
                                      crossAxisAlignment: isDesktop
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        SelectableText(
                                          "$amountPrefix${Format.localizedStringAsFixed(
                                            value: coin == Coin.monero
                                                ? (amount / 10000.toDecimal())
                                                    .toDecimal()
                                                : coin == Coin.wownero
                                                    ? (amount /
                                                            1000.toDecimal())
                                                        .toDecimal()
                                                    : amount,
                                            locale: ref.watch(
                                              localeServiceChangeNotifierProvider
                                                  .select(
                                                      (value) => value.locale),
                                            ),
                                            decimalPlaces:
                                                Constants.decimalPlaces,
                                          )} ${coin.ticker}",
                                          style: isDesktop
                                              ? STextStyles
                                                      .desktopTextExtraExtraSmall(
                                                          context)
                                                  .copyWith(
                                                  color: Theme.of(context)
                                                      .extension<StackColors>()!
                                                      .textDark,
                                                )
                                              : STextStyles.titleBold12(
                                                  context),
                                        ),
                                        const SizedBox(
                                          height: 2,
                                        ),
                                        if (ref.watch(
                                            prefsChangeNotifierProvider.select(
                                                (value) =>
                                                    value.externalCalls)))
                                          SelectableText(
                                            "$amountPrefix${Format.localizedStringAsFixed(value: (coin == Coin.monero ? (amount / 10000.toDecimal()).toDecimal() : coin == Coin.wownero ? (amount / 1000.toDecimal()).toDecimal() : amount) * ref.watch(priceAnd24hChangeNotifierProvider.select((value) => value.getPrice(coin).item1)), locale: ref.watch(
                                                  localeServiceChangeNotifierProvider
                                                      .select((value) =>
                                                          value.locale),
                                                ), decimalPlaces: 2)} ${ref.watch(
                                              prefsChangeNotifierProvider
                                                  .select(
                                                (value) => value.currency,
                                              ),
                                            )}",
                                            style: isDesktop
                                                ? STextStyles
                                                    .desktopTextExtraExtraSmall(
                                                        context)
                                                : STextStyles.itemSubtitle(
                                                    context),
                                          ),
                                      ],
                                    ),
                                    if (!isDesktop)
                                      TxIcon(
                                        transaction: _transaction,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          isDesktop
                              ? const _Divider()
                              : const SizedBox(
                                  height: 12,
                                ),
                          RoundedWhiteContainer(
                            padding: isDesktop
                                ? const EdgeInsets.all(16)
                                : const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Status",
                                  style: isDesktop
                                      ? STextStyles.desktopTextExtraExtraSmall(
                                          context)
                                      : STextStyles.itemSubtitle(context),
                                ),
                                // Flexible(
                                //   child: FittedBox(
                                //     fit: BoxFit.scaleDown,
                                //     child:
                                SelectableText(
                                  _transaction.isCancelled
                                      ? "Cancelled"
                                      : whatIsIt(_transaction.txType),
                                  style: isDesktop
                                      ? STextStyles.desktopTextExtraExtraSmall(
                                              context)
                                          .copyWith(
                                          color: _transaction.txType == "Sent"
                                              ? Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .accentColorOrange
                                              : Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .accentColorGreen,
                                        )
                                      : STextStyles.itemSubtitle12(context),
                                ),
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                          if (!((coin == Coin.monero || coin == Coin.wownero) &&
                                  _transaction.txType.toLowerCase() ==
                                      "sent") &&
                              !((coin == Coin.firo ||
                                      coin == Coin.firoTestNet) &&
                                  _transaction.subType == "mint"))
                            isDesktop
                                ? const _Divider()
                                : const SizedBox(
                                    height: 12,
                                  ),
                          if (!((coin == Coin.monero || coin == Coin.wownero) &&
                                  _transaction.txType.toLowerCase() ==
                                      "sent") &&
                              !((coin == Coin.firo ||
                                      coin == Coin.firoTestNet) &&
                                  _transaction.subType == "mint"))
                            RoundedWhiteContainer(
                              padding: isDesktop
                                  ? const EdgeInsets.all(16)
                                  : const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _transaction.txType.toLowerCase() ==
                                                  "sent"
                                              ? "Sent to"
                                              : "Receiving address",
                                          style: isDesktop
                                              ? STextStyles
                                                  .desktopTextExtraExtraSmall(
                                                      context)
                                              : STextStyles.itemSubtitle(
                                                  context),
                                        ),
                                        const SizedBox(
                                          height: 8,
                                        ),
                                        _transaction.txType.toLowerCase() ==
                                                "received"
                                            ? FutureBuilder(
                                                future: fetchContactNameFor(
                                                    _transaction.address),
                                                builder: (builderContext,
                                                    AsyncSnapshot<String>
                                                        snapshot) {
                                                  String addressOrContactName =
                                                      _transaction.address;
                                                  if (snapshot.connectionState ==
                                                          ConnectionState
                                                              .done &&
                                                      snapshot.hasData) {
                                                    addressOrContactName =
                                                        snapshot.data!;
                                                  }
                                                  return SelectableText(
                                                    addressOrContactName,
                                                    style: isDesktop
                                                        ? STextStyles
                                                                .desktopTextExtraExtraSmall(
                                                                    context)
                                                            .copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .extension<
                                                                    StackColors>()!
                                                                .textDark,
                                                          )
                                                        : STextStyles
                                                            .itemSubtitle12(
                                                                context),
                                                  );
                                                },
                                              )
                                            : SelectableText(
                                                _transaction.address,
                                                style: isDesktop
                                                    ? STextStyles
                                                            .desktopTextExtraExtraSmall(
                                                                context)
                                                        .copyWith(
                                                        color: Theme.of(context)
                                                            .extension<
                                                                StackColors>()!
                                                            .textDark,
                                                      )
                                                    : STextStyles
                                                        .itemSubtitle12(
                                                            context),
                                              ),
                                      ],
                                    ),
                                  ),
                                  if (isDesktop)
                                    IconCopyButton(
                                      data: _transaction.address,
                                    ),
                                ],
                              ),
                            ),
                          isDesktop
                              ? const _Divider()
                              : const SizedBox(
                                  height: 12,
                                ),

                          RoundedWhiteContainer(
                            padding: isDesktop
                                ? const EdgeInsets.all(16)
                                : const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Note",
                                      style: isDesktop
                                          ? STextStyles
                                              .desktopTextExtraExtraSmall(
                                                  context)
                                          : STextStyles.itemSubtitle(context),
                                    ),
                                    isDesktop
                                        ? IconPencilButton(
                                            onPressed: () {
                                              showDialog<void>(
                                                context: context,
                                                builder: (context) {
                                                  return DesktopDialog(
                                                    maxWidth: 580,
                                                    maxHeight: 360,
                                                    child: EditNoteView(
                                                      txid: _transaction.txid,
                                                      walletId: walletId,
                                                      note: _note,
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          )
                                        : GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).pushNamed(
                                                EditNoteView.routeName,
                                                arguments: Tuple3(
                                                  _transaction.txid,
                                                  walletId,
                                                  _note,
                                                ),
                                              );
                                            },
                                            child: Row(
                                              children: [
                                                SvgPicture.asset(
                                                  Assets.svg.pencil,
                                                  width: 10,
                                                  height: 10,
                                                  color: Theme.of(context)
                                                      .extension<StackColors>()!
                                                      .infoItemIcons,
                                                ),
                                                const SizedBox(
                                                  width: 4,
                                                ),
                                                Text(
                                                  "Edit",
                                                  style: STextStyles.link2(
                                                      context),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                FutureBuilder(
                                  future: ref.watch(
                                      notesServiceChangeNotifierProvider(
                                              walletId)
                                          .select((value) => value.getNoteFor(
                                              txid: _transaction.txid))),
                                  builder: (builderContext,
                                      AsyncSnapshot<String> snapshot) {
                                    if (snapshot.connectionState ==
                                            ConnectionState.done &&
                                        snapshot.hasData) {
                                      _note = snapshot.data ?? "";
                                    }
                                    return SelectableText(
                                      _note,
                                      style: isDesktop
                                          ? STextStyles
                                                  .desktopTextExtraExtraSmall(
                                                      context)
                                              .copyWith(
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .textDark,
                                            )
                                          : STextStyles.itemSubtitle12(context),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          isDesktop
                              ? const _Divider()
                              : const SizedBox(
                                  height: 12,
                                ),
                          RoundedWhiteContainer(
                            padding: isDesktop
                                ? const EdgeInsets.all(16)
                                : const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Date",
                                      style: isDesktop
                                          ? STextStyles
                                              .desktopTextExtraExtraSmall(
                                                  context)
                                          : STextStyles.itemSubtitle(context),
                                    ),
                                    if (isDesktop)
                                      const SizedBox(
                                        height: 2,
                                      ),
                                    if (isDesktop)
                                      SelectableText(
                                        Format.extractDateFrom(
                                          _transaction.timestamp,
                                        ),
                                        style: isDesktop
                                            ? STextStyles
                                                    .desktopTextExtraExtraSmall(
                                                        context)
                                                .copyWith(
                                                color: Theme.of(context)
                                                    .extension<StackColors>()!
                                                    .textDark,
                                              )
                                            : STextStyles.itemSubtitle12(
                                                context),
                                      ),
                                  ],
                                ),
                                if (!isDesktop)
                                  SelectableText(
                                    Format.extractDateFrom(
                                      _transaction.timestamp,
                                    ),
                                    style: isDesktop
                                        ? STextStyles
                                                .desktopTextExtraExtraSmall(
                                                    context)
                                            .copyWith(
                                            color: Theme.of(context)
                                                .extension<StackColors>()!
                                                .textDark,
                                          )
                                        : STextStyles.itemSubtitle12(context),
                                  ),
                                if (isDesktop)
                                  IconCopyButton(
                                    data: Format.extractDateFrom(
                                      _transaction.timestamp,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          isDesktop
                              ? const _Divider()
                              : const SizedBox(
                                  height: 12,
                                ),
                          RoundedWhiteContainer(
                            padding: isDesktop
                                ? const EdgeInsets.all(16)
                                : const EdgeInsets.all(12),
                            child: Builder(builder: (context) {
                              final feeString = showFeePending
                                  ? _transaction.confirmedStatus
                                      ? Format.localizedStringAsFixed(
                                          value: coin == Coin.monero
                                              ? (fee / 10000.toDecimal())
                                                  .toDecimal()
                                              : coin == Coin.wownero
                                                  ? (fee / 1000.toDecimal())
                                                      .toDecimal()
                                                  : fee,
                                          locale: ref.watch(
                                              localeServiceChangeNotifierProvider
                                                  .select(
                                                      (value) => value.locale)),
                                          decimalPlaces:
                                              Constants.decimalPlaces)
                                      : "Pending"
                                  : Format.localizedStringAsFixed(
                                      value: coin == Coin.monero
                                          ? (fee / 10000.toDecimal())
                                              .toDecimal()
                                          : coin == Coin.wownero
                                              ? (fee / 1000.toDecimal())
                                                  .toDecimal()
                                              : fee,
                                      locale: ref.watch(
                                          localeServiceChangeNotifierProvider
                                              .select((value) => value.locale)),
                                      decimalPlaces: Constants.decimalPlaces);

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Transaction fee",
                                        style: isDesktop
                                            ? STextStyles
                                                .desktopTextExtraExtraSmall(
                                                    context)
                                            : STextStyles.itemSubtitle(context),
                                      ),
                                      if (isDesktop)
                                        const SizedBox(
                                          height: 2,
                                        ),
                                      if (isDesktop)
                                        SelectableText(
                                          feeString,
                                          style: isDesktop
                                              ? STextStyles
                                                      .desktopTextExtraExtraSmall(
                                                          context)
                                                  .copyWith(
                                                  color: Theme.of(context)
                                                      .extension<StackColors>()!
                                                      .textDark,
                                                )
                                              : STextStyles.itemSubtitle12(
                                                  context),
                                        ),
                                    ],
                                  ),
                                  if (!isDesktop)
                                    SelectableText(
                                      feeString,
                                      style: isDesktop
                                          ? STextStyles
                                                  .desktopTextExtraExtraSmall(
                                                      context)
                                              .copyWith(
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .textDark,
                                            )
                                          : STextStyles.itemSubtitle12(context),
                                    ),
                                  if (isDesktop) IconCopyButton(data: feeString)
                                ],
                              );
                            }),
                          ),
                          isDesktop
                              ? const _Divider()
                              : const SizedBox(
                                  height: 12,
                                ),
                          RoundedWhiteContainer(
                            padding: isDesktop
                                ? const EdgeInsets.all(16)
                                : const EdgeInsets.all(12),
                            child: Builder(builder: (context) {
                              final height = widget.coin != Coin.epicCash &&
                                      _transaction.confirmedStatus
                                  ? "${_transaction.height == 0 ? "Unknown" : _transaction.height}"
                                  : _transaction.confirmations > 0
                                      ? "${_transaction.height}"
                                      : "Pending";

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Block height",
                                        style: isDesktop
                                            ? STextStyles
                                                .desktopTextExtraExtraSmall(
                                                    context)
                                            : STextStyles.itemSubtitle(context),
                                      ),
                                      if (isDesktop)
                                        const SizedBox(
                                          height: 2,
                                        ),
                                      if (isDesktop)
                                        SelectableText(
                                          height,
                                          style: isDesktop
                                              ? STextStyles
                                                      .desktopTextExtraExtraSmall(
                                                          context)
                                                  .copyWith(
                                                  color: Theme.of(context)
                                                      .extension<StackColors>()!
                                                      .textDark,
                                                )
                                              : STextStyles.itemSubtitle12(
                                                  context),
                                        ),
                                    ],
                                  ),
                                  if (!isDesktop)
                                    SelectableText(
                                      height,
                                      style: isDesktop
                                          ? STextStyles
                                                  .desktopTextExtraExtraSmall(
                                                      context)
                                              .copyWith(
                                              color: Theme.of(context)
                                                  .extension<StackColors>()!
                                                  .textDark,
                                            )
                                          : STextStyles.itemSubtitle12(context),
                                    ),
                                  if (isDesktop) IconCopyButton(data: height),
                                ],
                              );
                            }),
                          ),
                          isDesktop
                              ? const _Divider()
                              : const SizedBox(
                                  height: 12,
                                ),
                          RoundedWhiteContainer(
                            padding: isDesktop
                                ? const EdgeInsets.all(16)
                                : const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Transaction ID",
                                        style: isDesktop
                                            ? STextStyles
                                                .desktopTextExtraExtraSmall(
                                                    context)
                                            : STextStyles.itemSubtitle(context),
                                      ),
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      // Flexible(
                                      //   child: FittedBox(
                                      //     fit: BoxFit.scaleDown,
                                      //     child:
                                      SelectableText(
                                        _transaction.txid,
                                        style: isDesktop
                                            ? STextStyles
                                                    .desktopTextExtraExtraSmall(
                                                        context)
                                                .copyWith(
                                                color: Theme.of(context)
                                                    .extension<StackColors>()!
                                                    .textDark,
                                              )
                                            : STextStyles.itemSubtitle12(
                                                context),
                                      ),
                                      if (coin != Coin.epicCash)
                                        const SizedBox(
                                          height: 8,
                                        ),
                                      if (coin != Coin.epicCash)
                                        BlueTextButton(
                                          text: "Open in block explorer",
                                          onTap: () async {
                                            final uri =
                                                getBlockExplorerTransactionUrlFor(
                                              coin: coin,
                                              txid: _transaction.txid,
                                            );

                                            if (ref
                                                    .read(
                                                        prefsChangeNotifierProvider)
                                                    .hideBlockExplorerWarning ==
                                                false) {
                                              final shouldContinue =
                                                  await showExplorerWarning(
                                                      "${uri.scheme}://${uri.host}");

                                              if (!shouldContinue) {
                                                return;
                                              }
                                            }

                                            // ref
                                            //     .read(
                                            //         shouldShowLockscreenOnResumeStateProvider
                                            //             .state)
                                            //     .state = false;
                                            try {
                                              await launchUrl(
                                                uri,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            } catch (_) {
                                              unawaited(showDialog<void>(
                                                context: context,
                                                builder: (_) => StackOkDialog(
                                                  title:
                                                      "Could not open in block explorer",
                                                  message:
                                                      "Failed to open \"${uri.toString()}\"",
                                                ),
                                              ));
                                            } finally {
                                              // Future<void>.delayed(
                                              //   const Duration(seconds: 1),
                                              //   () => ref
                                              //       .read(
                                              //           shouldShowLockscreenOnResumeStateProvider
                                              //               .state)
                                              //       .state = true,
                                              // );
                                            }
                                          },
                                        ),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                                if (isDesktop)
                                  const SizedBox(
                                    width: 12,
                                  ),
                                if (isDesktop)
                                  IconCopyButton(
                                    data: _transaction.txid,
                                  ),
                              ],
                            ),
                          ),
                          // if ((coin == Coin.firoTestNet || coin == Coin.firo) &&
                          //     _transaction.subType == "mint")
                          //   const SizedBox(
                          //     height: 12,
                          //   ),
                          // if ((coin == Coin.firoTestNet || coin == Coin.firo) &&
                          //     _transaction.subType == "mint")
                          //   RoundedWhiteContainer(
                          //     child: Column(
                          //       crossAxisAlignment: CrossAxisAlignment.start,
                          //       children: [
                          //         Row(
                          //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //           children: [
                          //             Text(
                          //               "Mint Transaction ID",
                          //               style: STextStyles.itemSubtitle(context),
                          //             ),
                          //           ],
                          //         ),
                          //         const SizedBox(
                          //           height: 8,
                          //         ),
                          //         // Flexible(
                          //         //   child: FittedBox(
                          //         //     fit: BoxFit.scaleDown,
                          //         //     child:
                          //         SelectableText(
                          //           _transaction.otherData ?? "Unknown",
                          //           style: STextStyles.itemSubtitle12(context),
                          //         ),
                          //         //   ),
                          //         // ),
                          //         const SizedBox(
                          //           height: 8,
                          //         ),
                          //         BlueTextButton(
                          //           text: "Open in block explorer",
                          //           onTap: () async {
                          //             final uri = getBlockExplorerTransactionUrlFor(
                          //               coin: coin,
                          //               txid: _transaction.otherData ?? "Unknown",
                          //             );
                          //             // ref
                          //             //     .read(
                          //             //         shouldShowLockscreenOnResumeStateProvider
                          //             //             .state)
                          //             //     .state = false;
                          //             try {
                          //               await launchUrl(
                          //                 uri,
                          //                 mode: LaunchMode.externalApplication,
                          //               );
                          //             } catch (_) {
                          //               unawaited(showDialog<void>(
                          //                 context: context,
                          //                 builder: (_) => StackOkDialog(
                          //                   title: "Could not open in block explorer",
                          //                   message:
                          //                       "Failed to open \"${uri.toString()}\"",
                          //                 ),
                          //               ));
                          //             } finally {
                          //               // Future<void>.delayed(
                          //               //   const Duration(seconds: 1),
                          //               //   () => ref
                          //               //       .read(
                          //               //           shouldShowLockscreenOnResumeStateProvider
                          //               //               .state)
                          //               //       .state = true,
                          //               // );
                          //             }
                          //           },
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          if (coin == Coin.epicCash)
                            isDesktop
                                ? const _Divider()
                                : const SizedBox(
                                    height: 12,
                                  ),
                          if (coin == Coin.epicCash)
                            RoundedWhiteContainer(
                              padding: isDesktop
                                  ? const EdgeInsets.all(16)
                                  : const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Slate ID",
                                        style: isDesktop
                                            ? STextStyles
                                                .desktopTextExtraExtraSmall(
                                                    context)
                                            : STextStyles.itemSubtitle(context),
                                      ),
                                      // Flexible(
                                      //   child: FittedBox(
                                      //     fit: BoxFit.scaleDown,
                                      //     child:
                                      SelectableText(
                                        _transaction.slateId ?? "Unknown",
                                        style: isDesktop
                                            ? STextStyles
                                                    .desktopTextExtraExtraSmall(
                                                        context)
                                                .copyWith(
                                                color: Theme.of(context)
                                                    .extension<StackColors>()!
                                                    .textDark,
                                              )
                                            : STextStyles.itemSubtitle12(
                                                context),
                                      ),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                  if (isDesktop)
                                    const SizedBox(
                                      width: 12,
                                    ),
                                  if (isDesktop)
                                    IconCopyButton(
                                      data: _transaction.slateId ?? "Unknown",
                                    ),
                                ],
                              ),
                            ),
                          if (!isDesktop)
                            const SizedBox(
                              height: 12,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: (coin == Coin.epicCash &&
              _transaction.confirmedStatus == false &&
              _transaction.isCancelled == false &&
              _transaction.txType == "Sent")
          ? SizedBox(
              width: MediaQuery.of(context).size.width - 32,
              child: TextButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    Theme.of(context).extension<StackColors>()!.textError,
                  ),
                ),
                onPressed: () async {
                  final Manager manager = ref
                      .read(walletsChangeNotifierProvider)
                      .getManager(walletId);

                  if (manager.wallet is EpicCashWallet) {
                    final String? id = _transaction.slateId;
                    if (id == null) {
                      unawaited(showFloatingFlushBar(
                        type: FlushBarType.warning,
                        message: "Could not find Epic transaction ID",
                        context: context,
                      ));
                      return;
                    }

                    unawaited(showDialog<dynamic>(
                      barrierDismissible: false,
                      context: context,
                      builder: (_) =>
                          const CancellingTransactionProgressDialog(),
                    ));

                    final result = await (manager.wallet as EpicCashWallet)
                        .cancelPendingTransactionAndPost(id);
                    if (mounted) {
                      // pop progress dialog
                      Navigator.of(context).pop();

                      if (result.isEmpty) {
                        await showDialog<dynamic>(
                          context: context,
                          builder: (_) => StackOkDialog(
                            title: "Transaction cancelled",
                            onOkPressed: (_) {
                              manager.refresh();
                              Navigator.of(context).popUntil(
                                  ModalRoute.withName(WalletView.routeName));
                            },
                          ),
                        );
                      } else {
                        await showDialog<dynamic>(
                          context: context,
                          builder: (_) => StackOkDialog(
                            title: "Failed to cancel transaction",
                            message: result,
                          ),
                        );
                      }
                    }
                  } else {
                    unawaited(showFloatingFlushBar(
                      type: FlushBarType.warning,
                      message: "ERROR: Wallet type is not Epic Cash",
                      context: context,
                    ));
                    return;
                  }
                },
                child: Text(
                  "Cancel Transaction",
                  style: STextStyles.button(context),
                ),
              ),
            )
          : null,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Theme.of(context).extension<StackColors>()!.background,
    );
  }
}

class IconCopyButton extends StatelessWidget {
  const IconCopyButton({
    Key? key,
    required this.data,
  }) : super(key: key);

  final String data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      width: 26,
      child: RawMaterialButton(
        fillColor:
            Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
        elevation: 0,
        hoverElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: data));
          unawaited(
            showFloatingFlushBar(
              type: FlushBarType.info,
              message: "Copied to clipboard",
              context: context,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: CopyIcon(
            width: 16,
            height: 16,
            color: Theme.of(context).extension<StackColors>()!.textDark,
          ),
        ),
      ),
    );
  }
}

class IconPencilButton extends StatelessWidget {
  const IconPencilButton({
    Key? key,
    this.onPressed,
  }) : super(key: key);

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      width: 26,
      child: RawMaterialButton(
        fillColor:
            Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
        elevation: 0,
        hoverElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        onPressed: () => onPressed?.call(),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: PencilIcon(
            width: 16,
            height: 16,
            color: Theme.of(context).extension<StackColors>()!.textDark,
          ),
        ),
      ),
    );
  }
}
