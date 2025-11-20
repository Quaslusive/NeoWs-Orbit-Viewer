import 'dart:async';
import 'package:flutter/material.dart';
import 'package:neows_app/neows/asteroid_repository.dart';
import 'package:neows_app/neows/neo_models.dart';
import 'package:neows_app/canvas/orbit_3d_canvas.dart';

typedef AddItemFn = void Function(Orbit3DItem item);
typedef SetBusyFn = void Function(bool busy);

enum AddResult { added, duplicate }

class AsteroidController {
  AsteroidController({
    required this.repo,
    required this.addItem,
    required this.setBusy,
    required this.ids,
    this.onNotice,
  });

  final AsteroidRepository repo;
  final AddItemFn addItem;
  final SetBusyFn setBusy;

  final void Function(String msg)? onNotice;

  final Set<String> ids;

  void _notify(String msg) {
    if (onNotice != null) {
      onNotice!(msg);
    } else {
      debugPrint('NOTICE: $msg');
    }
  }

  Future<AddResult> addNeoLite(NeoLite n) async {
    if (!ids.add(n.id)) {
      _notify('Already added: ${n.name}');
      return AddResult.duplicate;
    }
    final el = await repo.getOrbit(n.id);
    final color = n.isHazardous ? Colors.redAccent : Colors.cyanAccent;
    addItem(Orbit3DItem(neo: n, el: el, color: color));
    _notify('Added ${n.name}');
    return AddResult.added;
  }

  Future<int> addMany(List<NeoLite> list, {int chunk = 10}) async {
    var added = 0;
    for (int i = 0; i < list.length; i += chunk) {
      final part =
          list.sublist(i, (i + chunk > list.length) ? list.length : i + chunk);
      final results = await Future.wait(part.map(addNeoLite));
      added += results.where((r) => r == AddResult.added).length;
    }
    return added;
  }

  Future<void> addRandom() async {
    setBusy(true);
    try {
      final pool = await repo.fetchPoolForRandom();
      if (pool.isEmpty) return _notify('No asteroids available.');
      await addNeoLite(repo.pickRandom(pool));
    } finally {
      setBusy(false);
    }
  }

  Future<void> addTodayAll() async {
    setBusy(true);
    try {
      final list = await repo.fetchToday();
      await addMany(list);
      _notify('Added ${list.length} asteroids for today.');
    } finally {
      setBusy(false);
    }
  }

  Future<void> addAllHazardous({int max = 100}) async {
    setBusy(true);
    try {
      final list = await repo.fetchAllHazardous(max: max);
      if (list.isEmpty) return _notify('No hazardous asteroids found.');
      await addMany(list);
      _notify('Added ${list.length} hazardous asteroids.');
    } finally {
      setBusy(false);
    }
  }

  Future<void> addAllKnown({int max = 100}) async {
    setBusy(true);
    try {
      final list = await repo.fetchAllKnown(max: max);
      if (list.isEmpty) return _notify('No asteroids found.');
      await addMany(list);
      _notify('Added ${list.length} asteroids.');
    } finally {
      setBusy(false);
    }
  }
}
