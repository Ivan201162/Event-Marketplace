import 'package:flutter/material.dart';
import 'idea_search_widget.dart';

/// Экран поиска идей мероприятий
class IdeaSearchScreen extends StatelessWidget {
  const IdeaSearchScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Поиск идей'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const IdeaSearchWidget(),
      );
}
