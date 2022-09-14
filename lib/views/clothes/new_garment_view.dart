import 'package:flutter/material.dart';
import 'package:seasonalclothesproject/services/auth/auth_service.dart';
import 'package:seasonalclothesproject/services/crud/clothes_service.dart';

class NewGarmentView extends StatefulWidget {
  const NewGarmentView({super.key});

  @override
  State<NewGarmentView> createState() => _NewGarmentViewState();
}

class _NewGarmentViewState extends State<NewGarmentView> {
  DatabaseGarment? _garment;
  late final ClothesSevice _clothesSevice;
  late final TextEditingController _textController;

  @override
  void initState() {
    _clothesSevice = ClothesSevice();
    _textController = TextEditingController();
    super.initState();
  }

  void _textControllerListener() async {
    final garment = _garment;
    if (garment == null) {
      return;
    }
    final text = _textController.text;
    await _clothesSevice.updateGarment(
      garment: garment,
      text: text,
    );
  }

  void _setupTextControllerListener() {
    _textController.removeListener(_textControllerListener);
    _textController.addListener(_textControllerListener);
  }

  Future<DatabaseGarment> createNewGarment() async {
    final existingGarment = _garment;
    if (existingGarment != null) {
      return existingGarment;
    }
    final currentUser = AuthService.firebase().currentUser!;
    final email = currentUser.email!;
    final owner = await _clothesSevice.getOrCreateUser(email: email);
    return _clothesSevice.createGarment(owner: owner);
  }

  void _deleteGarmentIfItIsEmpty() {
    final garment = _garment;
    if (_textController.text.isEmpty && garment != null) {
      _clothesSevice.deleteGarment(id: garment.id);
    }
  }

  void _saveGarmentIfItIsEmpty() async {
    final garment = _garment;
    final text = _textController.text;
    if (garment != null && text.isNotEmpty) {
      await _clothesSevice.updateGarment(
        garment: garment,
        text: text,
      );
    }
  }

  @override
  void dispose() {
    _deleteGarmentIfItIsEmpty();
    _saveGarmentIfItIsEmpty();
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
          future: createNewGarment(),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                _garment = snapshot.data as DatabaseGarment;
                _setupTextControllerListener();
                return TextField(
                  controller: _textController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: const InputDecoration (
                    hintText: 'Add detailes about your garment here...'
                  )
                );
              default:
                return const CircularProgressIndicator();
            }
          },
        ));
  }
}
