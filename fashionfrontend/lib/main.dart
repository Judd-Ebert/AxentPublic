import 'package:Axent/app_colors.dart';
import 'package:Axent/providers/filters_provider.dart';
import 'package:Axent/providers/liked_products_provider.dart';
import 'package:Axent/providers/wardrobes_provider.dart';
import 'package:Axent/providers/theme_provider.dart';
import 'package:Axent/providers/notification_provider.dart';
import 'package:Axent/providers/usage_data_provider.dart';
import 'package:Axent/views/pages/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:Axent/models/card_queue_model.dart';
import 'package:Axent/providers/search_provider.dart';
import 'package:Axent/firebase_options.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  // Pass all uncaught asynchronous errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize filters provider
  final filtersProvider = FiltersProvider();
  await filtersProvider.loadFilters();

  // Initialize liked products provider
  final likedProductsProvider = LikedProductsProvider();

  // Initialize wardrobes provider and load data
  final wardrobesProvider = WardrobesProvider();
  await wardrobesProvider.initialize();

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.loadThemePreference();

  // Initialize notification provider
  final notificationProvider = NotificationProvider();
  await notificationProvider.loadNotificationPreferences();

  // Initialize usage data provider
  final usageDataProvider = UsageDataProvider();
  await usageDataProvider.loadUsageData();

  runApp(
    
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CardQueueModel()),
        ChangeNotifierProvider(create: (_) => PreviousProductModel()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider.value(value: filtersProvider),
        ChangeNotifierProvider.value(value: likedProductsProvider),
        ChangeNotifierProvider.value(value: wardrobesProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: notificationProvider),
        ChangeNotifierProvider.value(value: usageDataProvider),
      ],
      child: const MainPage(),
    ),
  );
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final lightScheme = AppColors.lightScheme;
        final darkScheme = AppColors.darkScheme;
        
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Fashion App',
          theme: ThemeData(
            fontFamily: 'Inter',
            colorScheme: lightScheme,
            useMaterial3: true,
            navigationBarTheme: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return TextStyle(
                      fontSize: 12,
                      color: lightScheme.surface,
                      fontWeight: FontWeight.bold,
                    );
                  }
                  return TextStyle(
                    fontSize: 12,
                    color: lightScheme.surface,
                  );
                },
              ),
            ),
            iconTheme: IconThemeData(),
          ),
          darkTheme: ThemeData(
            fontFamily: 'Inter',
            colorScheme: darkScheme,
            useMaterial3: true,
            navigationBarTheme: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return TextStyle(
                      fontSize: 12,
                      color: darkScheme.surface,
                      fontWeight: FontWeight.bold,
                    );
                  }
                  return TextStyle(
                    fontSize: 12,
                    color: darkScheme.surface,
                  );
                },
              ),
            ),
            iconTheme: IconThemeData(),
          ),
          themeMode: themeProvider.themeMode,
          themeAnimationDuration: Duration.zero, // No error with switching themes on heart wardrobes page
          home: AuthWrapper(),
        );
      },
    );
  }
}
