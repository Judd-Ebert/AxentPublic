import 'package:Axent/data/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ignore: must_be_immutable
class NavbarWidget extends StatelessWidget {
  NavbarWidget({super.key});

  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double navbarHeight = screenHeight * 0.1; // Set navbar height to 10% of screen height

    return ValueListenableBuilder(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        return Container(
          height: navbarHeight,
          padding: EdgeInsets.only(top: navbarHeight * 0.2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withAlpha(64),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: NavigationBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            onDestinationSelected: (int index) {
              selectedPageNotifier.value = index;
            },
            indicatorColor: Theme.of(context).colorScheme.surface,
            selectedIndex: selectedPage,
            destinations: <Widget>[
              NavigationDestination(
                selectedIcon: SvgPicture.asset(
                  'assets/icons/Home.svg',
                  width: navbarHeight * 0.32, // Scale icon size relative to navbar height
                  height: navbarHeight * 0.32,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
                icon: SvgPicture.asset(
                  'assets/icons/Home.svg',
                  width: navbarHeight * 0.32,
                  height: navbarHeight * 0.32,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.secondary,
                    BlendMode.srcIn,
                  ),
                ),
                label: '',
              ),
              NavigationDestination(
                selectedIcon: SvgPicture.asset(
                  'assets/icons/Heart.svg',
                  width: navbarHeight * 0.32,
                  height: navbarHeight * 0.32,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
                icon: SvgPicture.asset(
                  'assets/icons/Heart.svg',
                  width: navbarHeight * 0.32,
                  height: navbarHeight * 0.32,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.secondary,
                    BlendMode.srcIn,
                  ),
                ),
                label: '',
              ),
              NavigationDestination(
                selectedIcon: SvgPicture.asset(
                  'assets/icons/Settings1.svg',
                  width: navbarHeight * 0.32,
                  height: navbarHeight * 0.32,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
                icon: SvgPicture.asset(
                  'assets/icons/Settings1.svg',
                  width: navbarHeight * 0.32,
                  height: navbarHeight * 0.32,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.secondary,
                    BlendMode.srcIn,
                  ),
                ),
                label: '',
              ),
            ],
          ),
        );
      },
    );
  }

  Size get preferredSize => Size.fromHeight(100);
}
