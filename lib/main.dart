import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ZenMartApp());
}

class ZenMartApp extends StatefulWidget {
  const ZenMartApp({super.key});

  @override
  State<ZenMartApp> createState() => _ZenMartAppState();
}

class _ZenMartAppState extends State<ZenMartApp> {
  // Initialize these late so they are only created once when the app starts.
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    // The router is instantiated once and injected with the authProvider
    _router = AppRouter.router(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    // MultiProvider prepares the app for Cart, Orders, and Product providers later.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
      ],
      child: MaterialApp.router(
        title: 'Zen Mart Pro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D47A1), // Professional, clean aesthetic
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}