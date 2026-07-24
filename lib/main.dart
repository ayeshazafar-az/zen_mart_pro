import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set up Firebase Messaging background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request permission for iOS/Web and initialize token
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();
  messaging.getToken().then((token) {
    debugPrint('FCM Token: $token');
  });

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
  late final ThemeProvider _themeProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _themeProvider = ThemeProvider();
    // The router is instantiated once and injected with the authProvider
    _router = AppRouter.router(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    // MultiProvider prepares the app for Cart, Orders, and Product providers later.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Zen Mart Pro',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor:
                    const Color(0xFF0D47A1), // Professional, clean aesthetic
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor:
                    const Color(0xFF0D47A1), // Professional, clean aesthetic
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
