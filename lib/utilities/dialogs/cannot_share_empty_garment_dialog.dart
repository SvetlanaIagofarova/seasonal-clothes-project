import 'package:flutter/material.dart';
import 'package:seasonalclothesproject/utilities/dialogs/generic_dialog.dart';

Future<void> showCannotShareEmptyGarmentDialog(BuildContext context) {
  return showGenericDialog<void>(
    context: context,
    title: 'Sharing',
    content: 'You cannot share an empty garment :(',
    optionsBuilder: () => {
      'OK': null,
    },
  );
}
