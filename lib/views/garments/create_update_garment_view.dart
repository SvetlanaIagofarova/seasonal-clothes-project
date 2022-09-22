import 'package:flutter/material.dart';
import 'package:seasonalclothesproject/services/auth/auth_service.dart';
import 'package:seasonalclothesproject/utilities/generics/get_arguments.dart';
import 'package:seasonalclothesproject/services/cloud/cloud_garment.dart';
import 'package:seasonalclothesproject/services/cloud/firebase_cloud_storage.dart';

class CreateUpdateGarmentView extends StatefulWidget {
  const CreateUpdateGarmentView({super.key});

  @override
  State<CreateUpdateGarmentView> createState() =>
      _CreateUpdateGarmentViewState();
}

class _CreateUpdateGarmentViewState extends State<CreateUpdateGarmentView> {
  CloudGarment? _garment;
  late final FirebaseCloudStorage _garmentsService;
  late final TextEditingController _textController;

  @override
  void initState() {
    _garmentsService = FirebaseCloudStorage();
    _textController = TextEditingController();
    super.initState();
  }

  void _textControllerListener() async {
    final garment = _garment;
    if (garment == null) {
      return;
    }
    final text = _textController.text;
    await _garmentsService.updateGarment(
      documentId: garment.documentId,
      text: text,
    );
  }

  void _setupTextControllerListener() {
    _textController.removeListener(_textControllerListener);
    _textController.addListener(_textControllerListener);
  }

  Future<CloudGarment> createOrGetExistingGarment(BuildContext context) async {
    final widgetGarment = context.getArgument<CloudGarment>();

    if (widgetGarment != null) {
      _garment = widgetGarment;
      _textController.text = widgetGarment.text;
      return widgetGarment;
    }

    final existingGarment = _garment;
    if (existingGarment != null) {
      return existingGarment;
    }
    final currentUser = AuthService.firebase().currentUser!;
    final userId = currentUser.id;
    final newGarment =
        await _garmentsService.createNewGarment(ownerUserId: userId);
    _garment = newGarment;
    return newGarment;
  }

  void _deleteGarmentIfItIsEmpty() {
    final garment = _garment;
    if (_textController.text.isEmpty && garment != null) {
      _garmentsService.deleteGarment(documentId: garment.documentId);
    }
  }

  void _saveGarmentIfItIsNotEmpty() async {
    final garment = _garment;
    final text = _textController.text;
    if (garment != null && text.isNotEmpty) {
      await _garmentsService.updateGarment(
        documentId: garment.documentId,
        text: text,
      );
    }
  }

  @override
  void dispose() {
    _deleteGarmentIfItIsEmpty();
    _saveGarmentIfItIsNotEmpty();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('New Garment'),
        ),
        body: FutureBuilder(
          future: createOrGetExistingGarment(context),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                _setupTextControllerListener();
                return TextField(
                  controller: _textController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: const InputDecoration(
                      hintText: 'Add detailes about your garment here...'),
                );
              default:
                return const CircularProgressIndicator();
            }
          },
        ));
  }
}
