enum QuickAddAction {
  addRandom,
  todayAll,
  addAllHazardous,
  addAllAsteroids
}

typedef QuickAddHandler = Future<void> Function(QuickAddAction);
