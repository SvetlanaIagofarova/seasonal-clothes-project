import 'package:seasonalclothesproject/constants/routes.dart';
import 'package:seasonalclothesproject/enums/menu_action.dart';
import 'package:seasonalclothesproject/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:seasonalclothesproject/services/crud/garments_service.dart';
import 'package:seasonalclothesproject/utilities/dialogs/logout_dialog.dart';
import 'package:seasonalclothesproject/views/garments/garments_list_view.dart';

class GarmentsView extends StatefulWidget {
  const GarmentsView({Key? key}) : super(key: key);

  @override
  State<GarmentsView> createState() => _GarmentsViewState();
}

class _GarmentsViewState extends State<GarmentsView> {
  late final GarmentsService _garmentsService;
  String get userEmail => AuthService.firebase().currentUser!.email!;

  @override
  void initState() {
    _garmentsService = GarmentsService();
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
      body: FutureBuilder(
        future: _garmentsService.getOrCreateUser(email: userEmail),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return StreamBuilder(
                stream: _garmentsService.allGarments,
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                    case ConnectionState.active:
                      if (snapshot.hasData) {
                        final allGarments =
                            snapshot.data as List<DatabaseGarment>;
                        return GarmentsListView(
                          garments: allGarments,
                          onDeleteGarment: (garment) async {
                            await _garmentsService.deleteGarment(
                                id: garment.id);
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
              );
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
