import 'package:flutter/material.dart';
import 'package:seasonalclothesproject/extentions/buildcontext/loc.dart';
import 'package:seasonalclothesproject/utilities/dialogs/generic_dialog.dart';

Future<void> showCannotShareEmptyGarmentDialog(BuildContext context) {
  return showGenericDialog<void>(
    context: context,
    title: context.loc.sharing,
    content: context.loc.cannot_share_empty_garment_prompt,
    optionsBuilder: () => {
      context.loc.ok: null,
    },
  );
}
