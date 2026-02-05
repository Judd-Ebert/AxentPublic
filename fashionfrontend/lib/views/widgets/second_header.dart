import 'package:flutter/material.dart';
import 'custom_search_bar.dart';

class SecondHeader extends StatelessWidget {
  final VoidCallback? onUndo;
  final VoidCallback? onFilter;
  const SecondHeader({super.key, this.onUndo, this.onFilter});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Undo button
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withAlpha(64),
                    spreadRadius: 2,
                    blurStyle: BlurStyle.outer,
                    blurRadius: 10,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: IconButton(
                iconSize: 24,
                icon: Icon(
                  Icons.undo_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () async {
                  try {
                    if (onUndo != null) {
                      onUndo!();
                    }
                  } catch (e) {
                    // Error during undo
                  }
                },
                style: ButtonStyle(
                  side: WidgetStateProperty.all(
                    BorderSide(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            // Search bar
            SizedBox(
              height: 48,
              width: MediaQuery.of(context).size.width * .6,
              child: CustomSearchBar(),
            ),
            // Filter button
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withAlpha(64),
                    spreadRadius: 2,
                    blurStyle: BlurStyle.outer,
                    blurRadius: 10,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: IconButton(
                iconSize: 24,
                icon: Icon(
                  Icons.filter_alt_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () async {
                  try {
                    if (onFilter != null) {
                      onFilter!();
                    }
                  } catch (e) {
                    // Error during filter
                  }
                },
                style: ButtonStyle(
                  side: WidgetStateProperty.all(
                    BorderSide(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
