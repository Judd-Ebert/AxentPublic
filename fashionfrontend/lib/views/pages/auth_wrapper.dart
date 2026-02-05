import 'package:Axent/data/notifiers.dart';
import 'package:Axent/views/pages/heart_page.dart';
import 'package:Axent/views/pages/home_page.dart';
import 'package:Axent/views/pages/settings_page.dart';
import 'package:Axent/views/pages/welcome_page.dart';
import 'package:Axent/views/widgets/navbar_widget.dart';
import 'package:Axent/providers/usage_data_provider.dart';
import 'package:Axent/models/card_queue_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? user;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    // Initialize pages once in initState
    pages = const [
      HomePage(key: PageStorageKey('home')),
      HeartPage(key: PageStorageKey('heart')),
      SettingsPage(key: PageStorageKey('settings')),
    ];
  }

  void _clearCardStackForNewUser() {
    // Clear the card stack and previous swipes to get fresh recommendations
    final cardQueueModel = Provider.of<CardQueueModel>(context, listen: false);
    final previousProductModel = Provider.of<PreviousProductModel>(context, listen: false);
    
    cardQueueModel.resetQueue();
    previousProductModel.clear();
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            final currentUser = FirebaseAuth.instance.currentUser!;
            
            // Check if this is a new user login (different from the previous user)
            if (user?.uid != currentUser.uid) {
              // Clear card stack for new user to get fresh recommendations
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _clearCardStackForNewUser();
              });
            }
            
            user = currentUser;
            
            // Record daily activity when user is authenticated
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final usageDataProvider = Provider.of<UsageDataProvider>(context, listen: false);
              usageDataProvider.recordDailyActivity();
            });

            final gradient = LinearGradient(
              colors: [
                Color.fromARGB(255, 4, 62, 104),
                Color.fromARGB(255, 8, 123, 206)
              ],
            );
            return Scaffold(
              appBar: AppBar(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  toolbarHeight: 40,
                  automaticallyImplyLeading: false,
                  centerTitle: false,
                  title: RichText(
                    text: TextSpan(
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Color.fromARGB(255, 4, 62, 104)),
                      children: [
                        TextSpan(text: 'Hi, '),
                        TextSpan(
                          text: user!.displayName ?? 'User',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            foreground: Paint()
                              ..shader = gradient.createShader(
                                  const Rect.fromLTWH(0, 0, 200, 70)),
                          ),
                        ),
                        TextSpan(text: " 👋")
                      ],
                    ),
                  )),
              body: ValueListenableBuilder(
                  valueListenable: selectedPageNotifier,
                  builder: (context, selectedPage, child) {
                    return IndexedStack(
                      index: selectedPage,
                      children: pages,
                    );
                  }),
              bottomNavigationBar: NavbarWidget(),
            );
          }
          return WelcomePage();
        });
  }
}
