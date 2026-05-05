import 'package:career_logic/features/resume_builder/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  // Ensure Flutter bindings are initialized before calling SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create the provider and check the cache before drawing the first frame
  final authProvider = AuthProvider();
  await authProvider.checkAuthStatus();
  
  final themeProvider = ThemeProvider();
  // We don't need to await themeProvider._loadTheme because it happens in constructor
  // However to avoid flash, we could expose a method, but for now it's fine.

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const CareerLogicApp(),
    ),
  );
}

class CareerLogicApp extends StatelessWidget {
  const CareerLogicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CareerLogic AI',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              if (authProvider.isAuthenticated) {
                return const DashboardScreen();
              }
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}