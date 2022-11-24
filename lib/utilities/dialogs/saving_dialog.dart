import 'package:flutter/material.dart';
import 'package:seasonalclothesproject/extentions/buildcontext/loc.dart';
import 'package:seasonalclothesproject/utilities/dialogs/generic_dialog.dart';

Future<bool> showSavingDialog(BuildContext context) {
  return showGenericDialog<bool>(
    context: context,
    title: 'Are you sure?',
    content: 'All unsaved changes would be lost',
    optionsBuilder: () => {
      context.loc.cancel: false,
      context.loc.yes: true,
    },
  ).then(
    (value) => value ?? false,
  );
}
