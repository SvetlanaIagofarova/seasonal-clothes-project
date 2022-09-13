import 'package:flutter/material.dart';

class NewGarmentView extends StatefulWidget {
  const NewGarmentView({super.key});

  @override
  State<NewGarmentView> createState() => _NewGarmentViewState();
}

class _NewGarmentViewState extends State<NewGarmentView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Garment'),
      ),
      body: const Text('Add your new garment here...'),
    );
  }
}