
import 'package:flutter/material.dart';
import 'package:neows_app/widget/orbitDiagram2D.dart'; // <-- your actual orbit widget

class OrbitThumb extends StatelessWidget {
  final double? a;
  final double? e;
  final double height;
  final bool isLoading;

  const OrbitThumb({
    super.key,
    required this.a,
    required this.e,
    this.height = 110,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasOrbit = (a != null && a! > 0 && e != null && e! > 0);
    return SizedBox(
      height: height,
      child: hasOrbit
          ? OrbitDiagram2D(a: a!, e: e!) // rename props if yours differ
          : Center(
        child: Text(
          isLoading ? 'Loading orbit…' : 'No orbit data',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
