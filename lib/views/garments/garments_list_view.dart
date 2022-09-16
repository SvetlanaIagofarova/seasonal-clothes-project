import 'package:flutter/material.dart';
import 'package:seasonalclothesproject/services/crud/garments_service.dart';
import 'package:seasonalclothesproject/utilities/dialogs/delete_dialog.dart';

typedef DeleteGarmentCallBack = void Function(DatabaseGarment garment);

class GarmentsListView extends StatelessWidget {
  final List<DatabaseGarment> garments;
  final DeleteGarmentCallBack onDeleteGarment;

  const GarmentsListView({
    super.key,
    required this.garments,
    required this.onDeleteGarment,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: garments.length,
      itemBuilder: (context, index) {
        final garment = garments[index];
        return ListTile(
          title: Text(
            garment.text,
            maxLines: 1,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            onPressed: () async {
              final shouldDelete = await showDeleteDialog(context);
              if (shouldDelete) {
                onDeleteGarment(garment);
              }
            },
            icon: const Icon(Icons.delete),
          ),
        );
      },
    );
  }
}
