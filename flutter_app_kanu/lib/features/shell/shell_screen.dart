import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/messages_controller.dart';

/// Coquille principale avec barre de navigation basse à 5 onglets.
class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int unread = ref.watch(
      messagesControllerProvider.select((MessagesState s) => s.unreadCount),
    );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.manage_search_rounded),
            label: 'Recherche',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Accords',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.forum_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.forum_rounded),
            ),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
