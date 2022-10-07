import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seasonalclothesproject/constants/routes.dart';
import 'package:seasonalclothesproject/helpers/loading/loading_screen.dart';
import 'package:seasonalclothesproject/services/auth/bloc/auth_bloc.dart';
import 'package:seasonalclothesproject/services/auth/bloc/auth_event.dart';
import 'package:seasonalclothesproject/services/auth/bloc/auth_state.dart';
import 'package:seasonalclothesproject/services/auth/firebase_auth_provider.dart';
import 'package:seasonalclothesproject/views/forgot_password_view.dart';
import 'package:seasonalclothesproject/views/garments/garments_view.dart';
import 'package:seasonalclothesproject/views/garments/create_update_garment_view.dart';
import 'package:seasonalclothesproject/views/login_view.dart';
import 'package:seasonalclothesproject/views/register_view.dart';
import 'package:seasonalclothesproject/views/verify_email_view.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(FirebaseAuthProvider()),
        child: const HomePage(),
      ),
      routes: {
        createOrUpdateGarmentRoute: (context) =>
            const CreateUpdateGarmentView(),
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.read<AuthBloc>().add(const AuthEventInitialize());
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isLoading) {
          LoadingScreen().show(
            context: context,
            text: state.loadingText ?? 'Please, wait a moment',
          );
        } else {
          LoadingScreen().hide();
        }
      },
      builder: (context, state) {
        if (state is AuthStateLoggedIn) {
          return const GarmentsView();
        } else if (state is AuthStateNeedsVerification) {
          return const VerifyEmailView();
        } else if (state is AuthStateLoggedOut) {
          return const LoginView();
        } else if (state is AuthStateForgotPassword) {
          return const ForgotPasswordView();
        } else if (state is AuthStateRegistering) {
          return const RegisterView();
        } else {
          return const Scaffold(
            body: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
