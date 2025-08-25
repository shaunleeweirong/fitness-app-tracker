import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/exercise.dart';

class ExerciseDatabase {
  static const String _databaseName = 'exercise_cache.db';
  static const int _databaseVersion = 1;
  
  static const String _exercisesTable = 'exercises';
  static const String _metadataTable = 'metadata';
  
  Database? _database;
  
  // Singleton pattern
  static final ExerciseDatabase _instance = ExerciseDatabase._internal();
  factory ExerciseDatabase() => _instance;
  ExerciseDatabase._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Exercises table
    await db.execute('''
      CREATE TABLE $_exercisesTable (
        exerciseId TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        imageUrl TEXT,
        equipments TEXT,
        bodyParts TEXT,
        exerciseType TEXT,
        targetMuscles TEXT,
        secondaryMuscles TEXT,
        videoUrl TEXT,
        keywords TEXT,
        overview TEXT,
        instructions TEXT,
        exerciseTips TEXT,
        variations TEXT,
        relatedExerciseIds TEXT,
        cachedAt INTEGER NOT NULL,
        bodyPartFilter TEXT
      )
    ''');

    // Metadata table for cache management
    await db.execute('''
      CREATE TABLE $_metadataTable (
        key TEXT PRIMARY KEY,
        value TEXT,
        cachedAt INTEGER NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_bodyParts ON $_exercisesTable(bodyPartFilter)');
    await db.execute('CREATE INDEX idx_name ON $_exercisesTable(name)');
    await db.execute('CREATE INDEX idx_cachedAt ON $_exercisesTable(cachedAt)');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades in future versions
    if (oldVersion < 2) {
      // Add upgrade logic for version 2
    }
  }

  /// Cache exercises with expiration time (24 hours)
  Future<void> cacheExercises(List<Exercise> exercises, {String? bodyPartFilter}) async {
    final db = await database;
    final batch = db.batch();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    for (final exercise in exercises) {
      final exerciseData = {
        'exerciseId': exercise.exerciseId,
        'name': exercise.name,
        'imageUrl': exercise.imageUrl,
        'equipments': jsonEncode(exercise.equipments),
        'bodyParts': jsonEncode(exercise.bodyParts),
        'exerciseType': exercise.exerciseType,
        'targetMuscles': jsonEncode(exercise.targetMuscles),
        'secondaryMuscles': jsonEncode(exercise.secondaryMuscles),
        'videoUrl': exercise.videoUrl,
        'keywords': exercise.keywords != null ? jsonEncode(exercise.keywords!) : null,
        'overview': exercise.overview,
        'instructions': jsonEncode(exercise.instructions),
        'exerciseTips': exercise.exerciseTips != null ? jsonEncode(exercise.exerciseTips!) : null,
        'variations': exercise.variations != null ? jsonEncode(exercise.variations!) : null,
        'relatedExerciseIds': exercise.relatedExerciseIds != null ? jsonEncode(exercise.relatedExerciseIds!) : null,
        'cachedAt': currentTime,
        'bodyPartFilter': bodyPartFilter ?? 'all',
      };
      
      batch.insert(
        _exercisesTable,
        exerciseData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  /// Get cached exercises
  Future<List<Exercise>> getCachedExercises({
    String? bodyPartFilter,
    int? limit,
    String? searchQuery,
  }) async {
    final db = await database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final oneDayAgo = currentTime - (24 * 60 * 60 * 1000); // 24 hours ago
    
    String whereClause = 'cachedAt > ?';
    List<dynamic> whereArgs = [oneDayAgo];
    
    if (bodyPartFilter != null && bodyPartFilter != 'all') {
      whereClause += ' AND bodyPartFilter = ?';
      whereArgs.add(bodyPartFilter);
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += ' AND (name LIKE ? OR bodyParts LIKE ? OR equipments LIKE ?)';
      final searchPattern = '%$searchQuery%';
      whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
    }
    
    final maps = await db.query(
      _exercisesTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
      limit: limit,
    );
    
    return maps.map(_mapToExercise).toList();
  }

  /// Get a specific exercise from cache
  Future<Exercise?> getCachedExerciseById(String exerciseId) async {
    final db = await database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final oneDayAgo = currentTime - (24 * 60 * 60 * 1000);
    
    final maps = await db.query(
      _exercisesTable,
      where: 'exerciseId = ? AND cachedAt > ?',
      whereArgs: [exerciseId, oneDayAgo],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return _mapToExercise(maps.first);
  }

  /// Cache metadata (body parts, equipment types, etc.)
  Future<void> cacheMetadata(String key, List<String> values) async {
    final db = await database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert(
      _metadataTable,
      {
        'key': key,
        'value': jsonEncode(values),
        'cachedAt': currentTime,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get cached metadata
  Future<List<String>?> getCachedMetadata(String key) async {
    final db = await database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final oneDayAgo = currentTime - (24 * 60 * 60 * 1000);
    
    final maps = await db.query(
      _metadataTable,
      where: 'key = ? AND cachedAt > ?',
      whereArgs: [key, oneDayAgo],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    
    final jsonString = maps.first['value'] as String;
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.cast<String>();
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    final db = await database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final oneDayAgo = currentTime - (24 * 60 * 60 * 1000);
    
    await db.delete(_exercisesTable, where: 'cachedAt <= ?', whereArgs: [oneDayAgo]);
    await db.delete(_metadataTable, where: 'cachedAt <= ?', whereArgs: [oneDayAgo]);
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    final db = await database;
    await db.delete(_exercisesTable);
    await db.delete(_metadataTable);
  }

  /// Get cache statistics
  Future<Map<String, int>> getCacheStats() async {
    final db = await database;
    
    final exerciseCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_exercisesTable')
    ) ?? 0;
    
    final metadataCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_metadataTable')
    ) ?? 0;
    
    return {
      'exercises': exerciseCount,
      'metadata': metadataCount,
    };
  }

  /// Convert database map to Exercise object
  Exercise _mapToExercise(Map<String, dynamic> map) {
    return Exercise(
      exerciseId: map['exerciseId'] as String,
      name: map['name'] as String,
      imageUrl: map['imageUrl'] as String? ?? '',
      equipments: _decodeJsonList(map['equipments']),
      bodyParts: _decodeJsonList(map['bodyParts']),
      exerciseType: map['exerciseType'] as String?,
      targetMuscles: _decodeJsonList(map['targetMuscles']),
      secondaryMuscles: _decodeJsonList(map['secondaryMuscles']),
      videoUrl: map['videoUrl'] as String?,
      keywords: _decodeJsonListNullable(map['keywords']),
      overview: map['overview'] as String?,
      instructions: _decodeJsonList(map['instructions']),
      exerciseTips: _decodeJsonListNullable(map['exerciseTips']),
      variations: _decodeJsonListNullable(map['variations']),
      relatedExerciseIds: _decodeJsonListNullable(map['relatedExerciseIds']),
    );
  }

  List<String> _decodeJsonList(dynamic jsonString) {
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString as String);
      return jsonList.cast<String>();
    } catch (e) {
      return [];
    }
  }

  List<String>? _decodeJsonListNullable(dynamic jsonString) {
    if (jsonString == null) return null;
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString as String);
      return jsonList.cast<String>();
    } catch (e) {
      return null;
    }
  }

  /// Close the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}