import 'package:flutter/material.dart';
import 'presentation/routes/app_router.dart';

void main() {
  runApp(const Autolink());
}

class Autolink extends StatelessWidget {
  const Autolink({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autolink',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/splash',
      debugShowCheckedModeBanner: false,
    );
  }
}
