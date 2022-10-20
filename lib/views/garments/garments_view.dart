import 'package:flutter_bloc/flutter_bloc.dart' show ReadContext;
import 'package:seasonalclothesproject/constants/routes.dart';
import 'package:seasonalclothesproject/enums/menu_action.dart';
import 'package:seasonalclothesproject/extentions/buildcontext/loc.dart';
import 'package:seasonalclothesproject/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:seasonalclothesproject/services/auth/bloc/auth_bloc.dart';
import 'package:seasonalclothesproject/services/auth/bloc/auth_event.dart';
import 'package:seasonalclothesproject/services/cloud/cloud_garment.dart';
import 'package:seasonalclothesproject/services/cloud/firebase_cloud_storage.dart';
import 'package:seasonalclothesproject/utilities/dialogs/logout_dialog.dart';
import 'package:seasonalclothesproject/views/garments/garments_list_view.dart';

extension Count<T extends Iterable> on Stream<T> {
  Stream<int> get getLength => map((event) => event.length);
}

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
        title: StreamBuilder(
          stream: _garmentsService.allGarments(ownerUserId: userId).getLength,
          builder: (context, AsyncSnapshot<int> snapshot) {
            if(snapshot.hasData){
              final garmentCount = snapshot.data ?? 0;
              final text = context.loc.garments_title(garmentCount);
              return Text(text);
            } else {
              return const Text('');
            }
          }
        ),
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
                    if (!mounted) return;
                    context.read<AuthBloc>().add(
                          const AuthEventLogOut(),
                        );
                  }
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem<MenuAction>(
                  value: MenuAction.logout,
                  child: Text(context.loc.logout_button),
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
