import 'package:flutter/material.dart';
import 'package:Axent/views/pages/search_page.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to dedicated search page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SearchPage(),
          ),
        );
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25), // Rounded rectangle
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withAlpha(64),
              spreadRadius: 2,
              blurStyle: BlurStyle.outer,
              blurRadius: 10,
              offset: const Offset(0, 0),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.secondaryContainer,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Find your fashion...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurface,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
