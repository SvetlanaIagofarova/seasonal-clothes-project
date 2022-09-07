import 'package:cambridgeeglishdictionaryfree/constants/routes.dart';
import 'package:cambridgeeglishdictionaryfree/services/auth/auth_service.dart';
import 'package:cambridgeeglishdictionaryfree/views/dictionary_view.dart';
import 'package:cambridgeeglishdictionaryfree/views/login_view.dart';
import 'package:cambridgeeglishdictionaryfree/views/register_view.dart';
import 'package:cambridgeeglishdictionaryfree/views/verify_email_view.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
        dictionaryRoute:(context) => const DictionaryView(),
        verifyEmailRoute:(context) => const VerifyEmailView(),
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService.firebase().initialize(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            final user = AuthService.firebase().currentUser;
            if (user != null) {
              if (user.isEmailVerified) {
                return const DictionaryView();
              } else {
                return const VerifyEmailView();
              }
            } else {
              return const LoginView();
            }
          default:
            return const CircularProgressIndicator();
        }
      },
    );
  }
}