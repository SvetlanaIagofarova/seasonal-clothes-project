import 'package:seasonalclothesproject/constants/routes.dart';
import 'package:seasonalclothesproject/enums/menu_action.dart';
import 'package:seasonalclothesproject/services/auth/auth_service.dart';
import 'package:flutter/material.dart';


class GarmentsView extends StatefulWidget {
  const GarmentsView({Key? key}) : super(key: key);

  @override
  State<GarmentsView> createState() => _GarmentsViewState();
}

class _GarmentsViewState extends State<GarmentsView> {
  late final ClothesSevice _clothesSevice;
  String get userEmail => AuthService.firebase().currentUser!.email!;

  @override
  void initState() {
    _clothesSevice = ClothesSevice();
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
              Navigator.of(context).pushNamed(newGarmentRoute);
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
        future: _clothesSevice.getOrCreateUser(email: userEmail),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return StreamBuilder(
                stream: _clothesSevice.allClothes,
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                    case ConnectionState.active:
                      if (snapshot.hasData) {
                        final allClothes =
                            snapshot.data as List<DatabaseGarment>;
                        return ListView.builder(
                          itemCount: allClothes.length,
                          itemBuilder: (context, index) {
                            final garment = allClothes[index];
                            return ListTile(
                              title: Text(
                                garment.text,
                                maxLines: 1,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
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

Future<bool> showLogOutDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Log out'),
          )
        ],
      );
    },
  ).then((value) => value ?? false);
}
