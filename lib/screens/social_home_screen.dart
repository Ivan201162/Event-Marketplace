import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialHomeScreen extends ConsumerStatefulWidget {
  const SocialHomeScreen({super.key});

  @override
  ConsumerState<SocialHomeScreen> createState() => _SocialHomeScreenState();
}

class _SocialHomeScreenState extends ConsumerState<SocialHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Социальная лента'),
      ),
      body: const Center(
        child: Text('Социальная лента'),
      ),
    );
  }
}
