import 'package:drift/drift.dart';

class Asteroids extends Table {
  TextColumn get id => text()();                         // csv[0]
  TextColumn get name => text().withDefault(const Constant(''))();       // csv[4]
  TextColumn get fullName => text().named('full_name').withDefault(const Constant(''))(); // csv[2]
  RealColumn get diameter => real().withDefault(const Constant(0.0))();  // km csv[15]
  RealColumn get albedo => real().withDefault(const Constant(0.0))();    // csv[17]
  TextColumn get neo => text().withDefault(const Constant(''))();        // csv[6]
  TextColumn get pha => text().withDefault(const Constant('N'))();       // csv[7]
  RealColumn get rotationPeriod => real().named('rotation_period').withDefault(const Constant(0.0))(); // csv[18]
  TextColumn get classType => text().named('class_type').withDefault(const Constant(''))(); // csv[60]
  IntColumn  get orbitId => integer().named('orbit_id').withDefault(const Constant(0))();   // csv[27]
  RealColumn get moid => real().withDefault(const Constant(0.0))();       // au csv[45]
  RealColumn get a => real().withDefault(const Constant(0.0))();          // csv[33]
  RealColumn get e => real().withDefault(const Constant(0.0))();          // csv[32]

  // Indexes to speed up search/filter/sorting
  @override
  Set<Index> get indexes => {
    Index('idx_name', [name]),
    Index('idx_full_name', [fullName]),
    Index('idx_class', [classType]),
    Index('idx_moid', [moid]),
  };

  @override
  Set<Column> get primaryKey => {id};
}
