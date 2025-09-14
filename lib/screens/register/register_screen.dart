import 'package:fantasy_5omasi/screens/register/register_shapes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fantasy_5omasi/screens/register/register_form.dart';
import 'package:fantasy_5omasi/cubits/regestire/regestire_cubit.dart';
import 'package:fantasy_5omasi/repositories/auth_repository.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إنشاء حساب',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // الخلفية الهندسية
          Positioned.fill(
            child: CustomPaint(
              painter: RegisterBackgroundPainter(),
            ),
          ),

          // المحتوى
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: BlocProvider(
              create: (_) => RegisterCubit(context.read<AuthRepository>()),
              child: const SingleChildScrollView(
                child: RegisterForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
