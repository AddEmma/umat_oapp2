// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main/main_navigation.dart';
import 'screens/main/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/chat_service.dart';
import 'models/member.dart';
import 'screens/church_selection_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DatabaseService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
      ],
      child: MaterialApp(
        title: 'Church Ministry App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF1565C0),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.blue,
          ).copyWith(secondary: const Color(0xFF0277BD)),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1565C0),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
        home: const AppWrapper(),
        routes: {'/register': (context) => const RegisterScreen()},
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// Simplified app wrapper that handles authentication properly
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  _AppWrapperState createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for auth service to initialize
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.waitForInitialization();

    // Show splash for a shorter duration for better UX
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // Show loading while auth state or role/church data is being determined
        if (!authService.isInitialized || authService.isLoadingRole) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading Profile..."),
                ],
              ),
            ),
          );
        }

        // SYNC: Ensure DatabaseService has the correct churchId
        final dbService = Provider.of<DatabaseService>(context, listen: false);
        // Only sync if we are fully loaded to avoid incorrect null propagation
        if (dbService.churchId != authService.churchId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            dbService.setChurchId(authService.churchId);
          });
        }

        // Route to appropriate screen
        if (authService.user != null) {
          // If user is authenticated but hasn't selected/joined a church yet
          if (authService.churchId == null) {
            return const ChurchSelectionScreen();
          }
          return const MainNavigation();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

// Alternative enhanced AuthWrapper (if you need it elsewhere)
class AuthWrapper extends StatelessWidget {
  final bool showSplash;
  final bool requireLoginFlow;

  const AuthWrapper({
    super.key,
    this.showSplash = false,
    this.requireLoginFlow = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showSplash) {
      return const SplashScreen();
    }

    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // Show loading while auth state is being determined
        if (!authService.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (requireLoginFlow) {
          // Always require login flow, even if Firebase session exists
          return const LoginScreen();
        } else {
          // Standard auth check
          if (authService.user != null) {
            return const MainNavigation();
          } else {
            return const LoginScreen();
          }
        }
      },
    );
  }
}
