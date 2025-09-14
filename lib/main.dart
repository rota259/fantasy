import 'package:fantasy_5omasi/fantasy_hub_manager.dart';
import 'package:fantasy_5omasi/fantasy_hub_user.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fantasy_5omasi/repositories/auth_repository.dart';
import 'package:fantasy_5omasi/cubits/auth/auth_cubit.dart';
import 'package:fantasy_5omasi/cubits/regestire/regestire_cubit.dart';
import 'package:fantasy_5omasi/screens/auth/auth_screen.dart';
import 'package:fantasy_5omasi/screens/register/register_screen.dart';
import 'package:fantasy_5omasi/screens/manager/home/home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final authRepo = AuthRepository();

  runApp(Fantasy5omasiApp(
    initialRoute: '/auth', // ← دايمًا يروح على صفحة تسجيل الدخول
    authRepository: authRepo,
  ));
}

class Fantasy5omasiApp extends StatelessWidget {
  final String initialRoute;
  final AuthRepository authRepository;

  const Fantasy5omasiApp({
    super.key,
    required this.initialRoute,
    required this.authRepository,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: authRepository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit(authRepository)),
          BlocProvider(create: (_) => RegisterCubit(authRepository)),
        ],
        child: MaterialApp(
          title: 'Fantasy 5omasi',
          debugShowCheckedModeBanner: false,
          initialRoute: initialRoute,
          routes: {
            '/auth': (_) => const AuthScreen(),
            '/register': (_) => const RegisterScreen(),
            '/home': (_) => const HomeScreen(),
            '/userHub': (_) => const FantasyHubUser(),
            '/managerHub': (_) => const FantasyHubManager(),
          },
        ),
      ),
    );
  }
}
