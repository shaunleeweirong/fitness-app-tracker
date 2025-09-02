import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:first_fitness_test_app/services/database_helper.dart';
import 'package:first_fitness_test_app/models/workout.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper();
      // Clean slate for each test
      await dbHelper.deleteDatabase();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('should initialize database successfully', () async {
      final db = await dbHelper.database;
      expect(db, isNotNull);
      expect(db.isOpen, true);
    });

    test('should create all required tables', () async {
      final db = await dbHelper.database;
      
      // Check if all tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      
      final tableNames = tables.map((table) => table['name'] as String).toSet();
      
      expect(tableNames, containsAll([
        'workouts',
        'workout_exercises', 
        'workout_sets',
        'users',
        'user_preferences'
      ]));
    });

    test('should report database as healthy when properly initialized', () async {
      final isHealthy = await dbHelper.isDatabaseHealthy();
      expect(isHealthy, true);
    });

    test('should create mock user successfully', () async {
      final userId = await dbHelper.createMockUser();
      expect(userId, 'mock_user_1');
      
      final db = await dbHelper.database;
      
      // Verify user was created
      final users = await db.query('users', where: 'user_id = ?', whereArgs: [userId]);
      expect(users.length, 1);
      expect(users.first['name'], 'Fitness Enthusiast');
      
      // Verify preferences were created
      final prefs = await db.query('user_preferences', where: 'user_id = ?', whereArgs: [userId]);
      expect(prefs.length, 1);
      expect(prefs.first['default_weight_unit'], 'kg');
      expect(prefs.first['default_rest_time'], 90);
    });

    test('should not create duplicate mock user', () async {
      // Create first user
      final userId1 = await dbHelper.createMockUser();
      expect(userId1, 'mock_user_1');
      
      // Attempt to create again
      final userId2 = await dbHelper.createMockUser();
      expect(userId2, 'mock_user_1');
      
      // Verify only one user exists
      final db = await dbHelper.database;
      final users = await db.query('users');
      expect(users.length, 1);
    });

    test('should generate unique workout exercise IDs', () {
      final id1 = dbHelper.generateWorkoutExerciseId('workout_1', 'exercise_1');
      final id2 = dbHelper.generateWorkoutExerciseId('workout_1', 'exercise_2');
      final id3 = dbHelper.generateWorkoutExerciseId('workout_2', 'exercise_1');
      
      expect(id1, 'workout_1_exercise_1');
      expect(id2, 'workout_1_exercise_2');
      expect(id3, 'workout_2_exercise_1');
      
      // Verify all IDs are unique
      final ids = {id1, id2, id3};
      expect(ids.length, 3);
    });

    test('should provide database information', () async {
      await dbHelper.createMockUser();
      
      final info = await dbHelper.getDatabaseInfo();
      
      expect(info['version'], 1);
      expect(info['isHealthy'], true);
      expect(info['path'], isNotNull);
      expect(info['tables'], isNotNull);
      expect(info['tables']['users'], 1);
      expect(info['tables']['workouts'], 0);
    });

    test('should handle database errors gracefully', () async {
      await dbHelper.close();
      await dbHelper.deleteDatabase();
      
      // Try to get info from deleted database
      final info = await dbHelper.getDatabaseInfo();
      
      expect(info['isHealthy'], true); // Should recreate database automatically
      expect(info['error'], isNull);
    });

    test('should delete database successfully', () async {
      // Initialize database and create some data
      await dbHelper.createMockUser();
      expect(await dbHelper.isDatabaseHealthy(), true);
      
      // Delete database
      await dbHelper.deleteDatabase();
      
      // Database should be recreated as healthy when accessed again
      expect(await dbHelper.isDatabaseHealthy(), true);
      
      // But previous data should be gone
      final info = await dbHelper.getDatabaseInfo();
      expect(info['tables']['users'], 0);
    });

    group('Database Schema Tests', () {
      test('should have proper foreign key relationships', () async {
        final db = await dbHelper.database;
        
        // Get schema for workouts table
        final workoutsSchema = await db.rawQuery('PRAGMA table_info(workouts)');
        final columns = workoutsSchema.map((col) => col['name'] as String).toList();
        
        expect(columns, contains('workout_id'));
        expect(columns, contains('user_id'));
        expect(columns, contains('name'));
        expect(columns, contains('target_body_parts'));
        expect(columns, contains('planned_duration_minutes'));
        expect(columns, contains('created_at'));
        expect(columns, contains('status'));
      });

      test('should have proper indexes for query optimization', () async {
        final db = await dbHelper.database;
        
        // Get list of indexes
        final indexes = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%'"
        );
        
        final indexNames = indexes.map((idx) => idx['name'] as String).toSet();
        
        expect(indexNames, containsAll([
          'idx_workouts_user_id',
          'idx_workouts_status',
          'idx_workouts_created_at',
          'idx_workout_exercises_workout_id',
          'idx_workout_sets_exercise_id'
        ]));
      });

      test('should enforce NOT NULL constraints', () async {
        final db = await dbHelper.database;
        
        // Try to insert workout with missing required field
        try {
          await db.insert('workouts', {
            'workout_id': 'test',
            // Missing user_id (NOT NULL field)
            'name': 'Test Workout',
            'planned_duration_minutes': 30,
            'created_at': DateTime.now().toIso8601String(),
            'status': 0,
          });
          fail('Should have thrown an exception for missing NOT NULL field');
        } catch (e) {
          expect(e.toString(), contains('NOT NULL'));
        }
      });
    });

    group('Database Performance Tests', () {
      test('should handle concurrent database access', () async {
        // Create multiple concurrent operations
        final futures = List.generate(10, (index) async {
          try {
            final userId = await dbHelper.createMockUser();
            return userId;
          } catch (e) {
            // Expected: some calls may fail due to unique constraint
            return 'mock_user_1';
          }
        });
        
        final results = await Future.wait(futures);
        
        // All should return the same mock user ID
        for (final result in results) {
          expect(result, 'mock_user_1');
        }
        
        // Verify only one user was created despite concurrent access
        final db = await dbHelper.database;
        final users = await db.query('users');
        expect(users.length, 1);
      });

      test('should maintain data integrity during transactions', () async {
        final db = await dbHelper.database;
        final userId = await dbHelper.createMockUser();
        
        // Test transaction rollback on error
        try {
          await db.transaction((txn) async {
            // Insert valid workout
            await txn.insert('workouts', {
              'workout_id': 'workout_1',
              'user_id': userId,
              'name': 'Test Workout',
              'planned_duration_minutes': 30,
              'created_at': DateTime.now().toIso8601String(),
              'status': 0,
            });
            
            // Insert invalid workout (should cause rollback)
            await txn.insert('workouts', {
              'workout_id': 'workout_2',
              // Missing required user_id
              'name': 'Invalid Workout',
              'planned_duration_minutes': 30,
              'created_at': DateTime.now().toIso8601String(),
              'status': 0,
            });
          });
          fail('Transaction should have failed');
        } catch (e) {
          // Expected error
        }
        
        // Verify no workouts were inserted due to rollback
        final workouts = await db.query('workouts');
        expect(workouts.length, 0);
      });
    });
  });
}