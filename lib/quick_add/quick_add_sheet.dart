import 'package:flutter/material.dart';
import 'package:neows_app/quick_add/quick_add_action.dart';

class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({
    super.key,
    required this.onPick

  });
final Future<void> Function(QuickAddAction) onPick;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.casino),
            title: const Text('Random Asteroid'),
            onTap: () async {Navigator.pop(context); await onPick(QuickAddAction.addRandom);
         //   onTap: () {Navigator.pop(context); addRandom();
            },
          ),
          ListTile(
            leading: const Icon(Icons.today),
            title: const Text('Asteroids Today'),
            onTap: () async {Navigator.pop(context); await onPick(QuickAddAction.todayAll);
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber),
            title: const Text('All Hazardous Asteroids\n (Experimental max 100)'),
            onTap: () async {Navigator.pop(context); await onPick(QuickAddAction.addAllHazardous);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_box_outlined),
            title: const Text('All Asteroids\n (Experimental max 100)'),
            onTap: () async {Navigator.pop(context);  await onPick(QuickAddAction.addAllAsteroids);
            },
          ),
        ],
      ),
    );
  }
}
