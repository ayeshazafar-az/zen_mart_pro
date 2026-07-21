import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ZenMartApp());
}

class ZenMartApp extends StatelessWidget {
  const ZenMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Builder(
        builder: (context) {
          final authProvider = Provider.of<AuthProvider>(context);
          final router = AppRouter.router(authProvider);

          return MaterialApp.router(
            title: 'Zen Mart Pro',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}