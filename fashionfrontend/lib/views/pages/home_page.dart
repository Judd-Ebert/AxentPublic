import 'package:Axent/providers/search_provider.dart';
import 'package:Axent/views/widgets/second_header.dart';
import 'package:Axent/views/widgets/swipeable_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SwipeableCardController {
  VoidCallback? undo;
  VoidCallback? filter;
}

class HomePage extends StatelessWidget {
  static final GlobalKey<SwipeableCardState> _swipeableCardKey = GlobalKey();
  static final _cardController = SwipeableCardController();

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: PageStorageKey('home'),
      body: Column(
        children: [
          SecondHeader(
            onUndo: () {
              _cardController.undo?.call();
            },
            onFilter: () {
              _cardController.filter?.call();
            },
          ),
          Expanded(
            child: Consumer<SearchProvider>(
              builder: (context, searchProvider, child) {
                return Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: SwipeableCard(
                    key: _swipeableCardKey,
                    controller: _cardController,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}