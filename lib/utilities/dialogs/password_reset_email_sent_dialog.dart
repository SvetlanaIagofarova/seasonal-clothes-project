import 'package:flutter/material.dart';
import 'package:seasonalclothesproject/extentions/buildcontext/loc.dart';
import 'package:seasonalclothesproject/utilities/dialogs/generic_dialog.dart';

Future<void> showPasswordResetSentDialog(BuildContext context) {
  return showGenericDialog(
    context: context,
    title: context.loc.password_reset,
    content:
        context.loc.password_reset_dialog_prompt,
    optionsBuilder: () => {
      context.loc.ok: null,
    },
  );
}
