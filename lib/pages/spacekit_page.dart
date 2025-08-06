/*
import 'dart:js' as js;
import 'package:flutter/material.dart';

class SpacekitPage extends StatelessWidget {
  const SpacekitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Orbit Viewer")),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text("SpaceKit Orbit Example"),
          const SizedBox(height: 20),
          SizedBox(
            height: 400,
            child: HtmlElementView(viewType: 'spacekit-container'),
          ),
          ElevatedButton(
            onPressed: () {
              js.context.callMethod('loadSpaceKitOrbit');
            },
            child: const Text("Load Orbit"),
          ),
        ],
      ),
    );
  }
}
*/
