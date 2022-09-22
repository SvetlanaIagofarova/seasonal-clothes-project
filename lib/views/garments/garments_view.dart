import 'package:seasonalclothesproject/constants/routes.dart';
import 'package:seasonalclothesproject/enums/menu_action.dart';
import 'package:seasonalclothesproject/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:seasonalclothesproject/services/cloud/cloud_garment.dart';
import 'package:seasonalclothesproject/services/cloud/firebase_cloud_storage.dart';
import 'package:seasonalclothesproject/utilities/dialogs/logout_dialog.dart';
import 'package:seasonalclothesproject/views/garments/garments_list_view.dart';

class GarmentsView extends StatefulWidget {
  const GarmentsView({Key? key}) : super(key: key);

  @override
  State<GarmentsView> createState() => _GarmentsViewState();
}

class _GarmentsViewState extends State<GarmentsView> {
  late final FirebaseCloudStorage _garmentsService;
  String get userId => AuthService.firebase().currentUser!.id;

  @override
  void initState() {
    _garmentsService = FirebaseCloudStorage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Clothes'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(createOrUpdateGarmentRoute);
            },
            icon: const Icon(Icons.add),
          ),
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogOut = await showLogOutDialog(context);
                  if (shouldLogOut) {
                    await AuthService.firebase().logOut();
                    if (!mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      loginRoute,
                      (_) => false,
                    );
                  }
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<MenuAction>(
                  value: MenuAction.logout,
                  child: Text('Log out'),
                )
              ];
            },
          )
        ],
      ),
      body: StreamBuilder(
        stream: _garmentsService.allGarments(ownerUserId: userId),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
            case ConnectionState.active:
              if (snapshot.hasData) {
                final allGarments = snapshot.data as Iterable<CloudGarment>;
                return GarmentsListView(
                  garments: allGarments,
                  onDeleteGarment: (garment) async {
                    await _garmentsService.deleteGarment(
                        documentId: garment.documentId);
                  },
                  onTap: (garment) {
                    Navigator.of(context).pushNamed(
                      createOrUpdateGarmentRoute,
                      arguments: garment,
                    );
                  },
                );
              } else {
                return const CircularProgressIndicator();
              }
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
