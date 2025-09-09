import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/workout.dart';
import 'default_template_seeder_service.dart';

/// SQLite database helper for workout tracking app
/// Manages database initialization, table creation, and versioning
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _databaseName = 'fitness_tracker.db';
  static const int _databaseVersion = 2;

  // Table names
  static const String tableWorkouts = 'workouts';
  static const String tableWorkoutExercises = 'workout_exercises';
  static const String tableWorkoutSets = 'workout_sets';
  static const String tableUsers = 'users';
  static const String tableUserPreferences = 'user_preferences';
  
  // Template table names
  static const String tableWorkoutTemplates = 'workout_templates';
  static const String tableTemplateExercises = 'template_exercises';

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

  /// Create all database tables
  Future<void> _createTables(Database db, int version) async {
    // Create workouts table
    await db.execute('''
      CREATE TABLE $tableWorkouts (
        workout_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        target_body_parts TEXT,
        planned_duration_minutes INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        started_at TEXT,
        completed_at TEXT,
        status INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (user_id)
      )
    ''');

    // Create workout_exercises table
    await db.execute('''
      CREATE TABLE $tableWorkoutExercises (
        workout_exercise_id TEXT PRIMARY KEY,
        workout_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        body_parts TEXT,
        notes TEXT,
        order_index INTEGER NOT NULL,
        FOREIGN KEY (workout_id) REFERENCES $tableWorkouts (workout_id) ON DELETE CASCADE
      )
    ''');

    // Create workout_sets table
    await db.execute('''
      CREATE TABLE $tableWorkoutSets (
        set_id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_exercise_id TEXT NOT NULL,
        weight REAL NOT NULL,
        reps INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        notes TEXT,
        rest_time_seconds INTEGER,
        FOREIGN KEY (workout_exercise_id) REFERENCES $tableWorkoutExercises (workout_exercise_id) ON DELETE CASCADE
      )
    ''');

    // Create users table
    await db.execute('''
      CREATE TABLE $tableUsers (
        user_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_active_at TEXT NOT NULL,
        body_part_xp TEXT
      )
    ''');

    // Create user_preferences table
    await db.execute('''
      CREATE TABLE $tableUserPreferences (
        user_id TEXT PRIMARY KEY,
        default_weight_unit TEXT NOT NULL DEFAULT 'kg',
        default_rest_time INTEGER NOT NULL DEFAULT 90,
        favorite_body_parts TEXT,
        sound_enabled INTEGER NOT NULL DEFAULT 1,
        vibration_enabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (user_id) ON DELETE CASCADE
      )
    ''');

    // Create workout templates table
    await db.execute('''
      CREATE TABLE $tableWorkoutTemplates (
        template_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        target_body_parts TEXT,
        estimated_duration_minutes INTEGER,
        difficulty_level INTEGER DEFAULT 1,
        category TEXT DEFAULT 'Custom',
        is_favorite INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_used_at TEXT,
        usage_count INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES $tableUsers (user_id) ON DELETE CASCADE
      )
    ''');

    // Create template exercises table
    await db.execute('''
      CREATE TABLE $tableTemplateExercises (
        template_exercise_id TEXT PRIMARY KEY,
        template_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        exercise_name TEXT NOT NULL,
        body_parts TEXT,
        order_index INTEGER NOT NULL,
        suggested_sets INTEGER DEFAULT 3,
        suggested_reps_min INTEGER DEFAULT 8,
        suggested_reps_max INTEGER DEFAULT 12,
        suggested_weight REAL,
        rest_time_seconds INTEGER DEFAULT 90,
        notes TEXT,
        FOREIGN KEY (template_id) REFERENCES $tableWorkoutTemplates (template_id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await _createIndexes(db);
  }

  /// Create database indexes for optimized queries
  Future<void> _createIndexes(Database db) async {
    // Workout indexes
    await db.execute('CREATE INDEX idx_workouts_user_id ON $tableWorkouts (user_id)');
    await db.execute('CREATE INDEX idx_workouts_status ON $tableWorkouts (status)');
    await db.execute('CREATE INDEX idx_workouts_created_at ON $tableWorkouts (created_at)');
    
    // Exercise indexes
    await db.execute('CREATE INDEX idx_workout_exercises_workout_id ON $tableWorkoutExercises (workout_id)');
    await db.execute('CREATE INDEX idx_workout_exercises_order ON $tableWorkoutExercises (workout_id, order_index)');
    
    // Sets indexes
    await db.execute('CREATE INDEX idx_workout_sets_exercise_id ON $tableWorkoutSets (workout_exercise_id)');
    await db.execute('CREATE INDEX idx_workout_sets_set_number ON $tableWorkoutSets (workout_exercise_id, set_number)');
    
    // Template indexes
    await db.execute('CREATE INDEX idx_workout_templates_user_id ON $tableWorkoutTemplates (user_id)');
    await db.execute('CREATE INDEX idx_workout_templates_category ON $tableWorkoutTemplates (category)');
    await db.execute('CREATE INDEX idx_workout_templates_favorite ON $tableWorkoutTemplates (is_favorite)');
    await db.execute('CREATE INDEX idx_workout_templates_usage ON $tableWorkoutTemplates (usage_count DESC)');
    
    // Template exercise indexes
    await db.execute('CREATE INDEX idx_template_exercises_template_id ON $tableTemplateExercises (template_id)');
    await db.execute('CREATE INDEX idx_template_exercises_order ON $tableTemplateExercises (template_id, order_index)');
  }

  /// Handle database upgrades for future versions
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Add workout template tables in version 2
      await db.execute('''
        CREATE TABLE $tableWorkoutTemplates (
          template_id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          target_body_parts TEXT,
          estimated_duration_minutes INTEGER,
          difficulty_level INTEGER DEFAULT 1,
          category TEXT DEFAULT 'Custom',
          is_favorite INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          last_used_at TEXT,
          usage_count INTEGER DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES $tableUsers (user_id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE $tableTemplateExercises (
          template_exercise_id TEXT PRIMARY KEY,
          template_id TEXT NOT NULL,
          exercise_id TEXT NOT NULL,
          exercise_name TEXT NOT NULL,
          body_parts TEXT,
          order_index INTEGER NOT NULL,
          suggested_sets INTEGER DEFAULT 3,
          suggested_reps_min INTEGER DEFAULT 8,
          suggested_reps_max INTEGER DEFAULT 12,
          suggested_weight REAL,
          rest_time_seconds INTEGER DEFAULT 90,
          notes TEXT,
          FOREIGN KEY (template_id) REFERENCES $tableWorkoutTemplates (template_id) ON DELETE CASCADE
        )
      ''');

      // Create template indexes
      await db.execute('CREATE INDEX idx_workout_templates_user_id ON $tableWorkoutTemplates (user_id)');
      await db.execute('CREATE INDEX idx_workout_templates_category ON $tableWorkoutTemplates (category)');
      await db.execute('CREATE INDEX idx_workout_templates_favorite ON $tableWorkoutTemplates (is_favorite)');
      await db.execute('CREATE INDEX idx_workout_templates_usage ON $tableWorkoutTemplates (usage_count DESC)');
      await db.execute('CREATE INDEX idx_template_exercises_template_id ON $tableTemplateExercises (template_id)');
      await db.execute('CREATE INDEX idx_template_exercises_order ON $tableTemplateExercises (template_id, order_index)');
    }
  }

  /// Close the database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Delete the entire database (for testing/reset purposes)
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  /// Check if database tables exist and are properly structured
  Future<bool> isDatabaseHealthy() async {
    try {
      final db = await database;
      
      // Check if all required tables exist
      final tables = [tableWorkouts, tableWorkoutExercises, tableWorkoutSets, tableUsers, tableUserPreferences];
      
      for (final table in tables) {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [table]
        );
        
        if (result.isEmpty) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get database information for debugging
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final db = await database;
      final version = await db.getVersion();
      final path = db.path;
      
      // Get table counts
      final workoutsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableWorkouts')) ?? 0;
      final exercisesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableWorkoutExercises')) ?? 0;
      final setsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableWorkoutSets')) ?? 0;
      final usersCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableUsers')) ?? 0;
      
      return {
        'version': version,
        'path': path,
        'isHealthy': await isDatabaseHealthy(),
        'tables': {
          'workouts': workoutsCount,
          'exercises': exercisesCount,
          'sets': setsCount,
          'users': usersCount,
        }
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'isHealthy': false,
      };
    }
  }

  /// Create a mock user for single-user MVP experience and seed default templates
  Future<String> createMockUser() async {
    final db = await database;
    const mockUserId = 'mock_user_1';
    
    // Check if mock user already exists
    final existing = await db.query(
      tableUsers,
      where: 'user_id = ?',
      whereArgs: [mockUserId],
    );
    
    if (existing.isNotEmpty) {
      // User exists, but check if we need to seed templates
      await _seedDefaultTemplatesIfNeeded();
      return mockUserId;
    }
    
    // Create mock user
    final user = User(
      userId: mockUserId,
      name: 'Fitness Enthusiast',
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
      preferences: UserPreferences.defaultPreferences(),
    );
    
    await db.insert(tableUsers, user.toMap());
    await db.insert(tableUserPreferences, user.preferences.toMap(mockUserId));
    
    // Seed default templates after creating user
    await _seedDefaultTemplatesIfNeeded();
    
    return mockUserId;
  }
  
  /// Seed default templates if they haven't been created yet
  Future<void> _seedDefaultTemplatesIfNeeded() async {
    try {
      final seeder = DefaultTemplateSeederService();
      await seeder.seedDefaultTemplatesIfNeeded();
      // Don't close seeder - it uses shared database connection
    } catch (e) {
      // Log error but don't fail user creation
      print('Failed to seed default templates: $e');
    }
  }

  /// Generate unique workout exercise ID
  String generateWorkoutExerciseId(String workoutId, String exerciseId) {
    final generatedId = '${workoutId}_$exerciseId';
    debugPrint('🔑 GENERATING workout_exercise_id:');
    debugPrint('   Input workoutId: $workoutId');
    debugPrint('   Input exerciseId: $exerciseId');  
    debugPrint('   Generated ID: $generatedId');
    return generatedId;
  }

  /// Generate unique workout template ID
  String generateWorkoutTemplateId() {
    return 'template_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate unique template exercise ID
  String generateTemplateExerciseId(String templateId, String exerciseId) {
    return '${templateId}_$exerciseId';
  }
}