import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/custom_text_button.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    Key? key,
    this.width,
    this.height,
    this.label,
    this.icon,
    this.onPressed,
    this.enabled = true,
    this.desktopMed = false,
  }) : super(key: key);

  final double? width;
  final double? height;
  final String? label;
  final VoidCallback? onPressed;
  final bool enabled;
  final Widget? icon;
  final bool desktopMed;

  TextStyle getStyle(bool isDesktop, BuildContext context) {
    if (isDesktop) {
      if (desktopMed) {
        return STextStyles.desktopTextExtraSmall(context).copyWith(
          color: enabled
              ? Theme.of(context).extension<StackColors>()!.buttonTextPrimary
              : Theme.of(context)
                  .extension<StackColors>()!
                  .buttonTextPrimaryDisabled,
        );
      } else {
        return enabled
            ? STextStyles.desktopButtonEnabled(context)
            : STextStyles.desktopButtonDisabled(context);
      }
    } else {
      return STextStyles.button(context).copyWith(
        color: enabled
            ? Theme.of(context).extension<StackColors>()!.buttonTextPrimary
            : Theme.of(context)
                .extension<StackColors>()!
                .buttonTextPrimaryDisabled,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;

    return CustomTextButtonBase(
      height: desktopMed ? 56 : height,
      width: width,
      textButton: TextButton(
        onPressed: enabled ? onPressed : null,
        style: enabled
            ? Theme.of(context)
                .extension<StackColors>()!
                .getPrimaryEnabledButtonColor(context)
            : Theme.of(context)
                .extension<StackColors>()!
                .getPrimaryDisabledButtonColor(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) icon!,
            if (icon != null && label != null)
              const SizedBox(
                width: 10,
              ),
            if (label != null)
              Text(
                label!,
                style: getStyle(isDesktop, context),
              ),
          ],
        ),
      ),
    );
  }
}
