import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class LanguageOptionSettings extends ConsumerStatefulWidget {
  const LanguageOptionSettings({Key? key}) : super(key: key);

  static const String routeName = "/settingsMenuLanguage";

  @override
  ConsumerState<LanguageOptionSettings> createState() =>
      _LanguageOptionSettings();
}

class _LanguageOptionSettings extends ConsumerState<LanguageOptionSettings> {
  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            right: 30,
          ),
          child: RoundedWhiteContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  Assets.svg.circleLanguage,
                  width: 48,
                  height: 48,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Language",
                              style: STextStyles.desktopTextSmall(context),
                            ),
                            TextSpan(
                              text:
                                  "\n\nSelect the language of your wallet. We use your system language by default.",
                              style: STextStyles.desktopTextExtraExtraSmall(
                                  context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(
                        10,
                      ),
                      child: ChangeLanguageButton(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ChangeLanguageButton extends ConsumerWidget {
  const ChangeLanguageButton({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 200,
      height: 48,
      child: TextButton(
        style: Theme.of(context)
            .extension<StackColors>()!
            .getPrimaryEnabledButtonColor(context),
        onPressed: () {},
        child: Text(
          "Change language",
          style: STextStyles.button(context),
        ),
      ),
    );
  }
}
