import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/post_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/story_provider.dart';
import 'package:go_router/go_router.dart';
import 'navigation/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<AuthProvider, PostProvider>(
          create: (context) => PostProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => PostProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (context) => ChatProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => ChatProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, StoryProvider>(
          create: (context) => StoryProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => StoryProvider(auth),
        ),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, child) {
          // Initialize router only once or when authProvider changes if needed
          // refreshListenable: authProvider handles internal state changes
          _router ??= AppRouter.createRouter(authProvider);
          
          return MaterialApp.router(
            title: 'Lettuce',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(false),
            darkTheme: AppTheme.getTheme(true),
            themeMode: themeProvider.themeMode,
            routerConfig: _router!,
            builder: (context, child) {
              // Handle overall loading state if needed
              if (authProvider.loading) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return child!;
            },
          );
        },
      ),
    );
  }
}
