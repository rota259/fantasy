import 'package:flutter/material.dart';
import 'package:fantasy_5omasi/screens/auth/auth_form.dart';
import 'package:fantasy_5omasi/screens/auth/shapes.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // يسمح بتحريك المحتوى لما الكيبورد يفتح
      appBar: AppBar(
        title: const Text(
          'Fantasy 5omasi',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 30,
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
              painter: IconBackgroundPainter(),
            ),
          ),

          // المحتوى المتجاوب
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const AuthForm(),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "لسه معندكش حساب؟",
                        style: TextStyle(fontSize: 16),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text(
                          "سجل دلوقتي",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
