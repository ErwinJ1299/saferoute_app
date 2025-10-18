import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/hazard.dart';

class HazardDatabase {
  static final HazardDatabase instance = HazardDatabase._init();
  static Database? _database;

  HazardDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hazards.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE hazards (
        id $idType,
        type $textType,
        latitude $realType,
        longitude $realType,
        severity $textType,
        description $textType,
        timestamp $textType,
        expiryTime $textType,
        upvotes $intType,
        downvotes $intType
      )
    ''');
  }

  // Create a new hazard
  Future<Hazard> create(Hazard hazard) async {
    final db = await instance.database;
    await db.insert('hazards', hazard.toJson());
    return hazard;
  }

  // Read a single hazard by ID
  Future<Hazard?> readHazard(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'hazards',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Hazard.fromJson(maps.first);
    } else {
      return null;
    }
  }

  // Read all hazards
  Future<List<Hazard>> readAllHazards() async {
    final db = await instance.database;
    const orderBy = 'timestamp DESC';
    final result = await db.query('hazards', orderBy: orderBy);
    return result.map((json) => Hazard.fromJson(json)).toList();
  }

  // Read all valid (not expired) hazards
  Future<List<Hazard>> readValidHazards() async {
    final allHazards = await readAllHazards();
    return allHazards.where((hazard) => hazard.isValid()).toList();
  }

  // Update a hazard (for upvotes/downvotes)
  Future<int> update(Hazard hazard) async {
    final db = await instance.database;
    return db.update(
      'hazards',
      hazard.toJson(),
      where: 'id = ?',
      whereArgs: [hazard.id],
    );
  }

  // Delete a hazard
  Future<int> delete(String id) async {
    final db = await instance.database;
    return await db.delete(
      'hazards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all expired hazards
  Future<int> deleteExpiredHazards() async {
    final allHazards = await readAllHazards();
    int deleteCount = 0;
    
    for (var hazard in allHazards) {
      if (!hazard.isValid()) {
        await delete(hazard.id);
        deleteCount++;
      }
    }
    
    return deleteCount;
  }

  // Delete all hazards
  Future<int> deleteAll() async {
    final db = await instance.database;
    return await db.delete('hazards');
  }

  // Close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
