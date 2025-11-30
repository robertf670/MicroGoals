import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../core/errors/exceptions.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize database', e, stackTrace);
      throw AppDatabaseException('Failed to initialize database: ${e.toString()}', e);
    }
  }

  Future<void> _createDB(Database db, int version) async {
    try {
      // Goals table
      await db.execute('''
        CREATE TABLE goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          target_value REAL NOT NULL,
          current_value REAL NOT NULL DEFAULT 0,
          unit TEXT,
          icon_name TEXT,
          color_hex TEXT,
          due_date INTEGER,
          is_completed INTEGER NOT NULL DEFAULT 0,
          completed_at INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Goal progress history table (premium)
      await db.execute('''
        CREATE TABLE goal_progress_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          goal_id INTEGER NOT NULL,
          progress_value REAL NOT NULL,
          progress_percentage REAL NOT NULL,
          recorded_at INTEGER NOT NULL,
          FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE
        )
      ''');

      // Milestones table (premium)
      await db.execute('''
        CREATE TABLE milestones (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          goal_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          target_percentage REAL NOT NULL,
          achieved_at INTEGER,
          FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE
        )
      ''');

      // Indexes
      await db.execute('CREATE INDEX idx_goals_is_completed ON goals(is_completed)');
      await db.execute('CREATE INDEX idx_goals_due_date ON goals(due_date)');
      await db.execute('CREATE INDEX idx_goal_progress_goal_id ON goal_progress_history(goal_id)');
      await db.execute('CREATE INDEX idx_milestones_goal_id ON milestones(goal_id)');
      
      Logger.info('Database created successfully');
    } catch (e, stackTrace) {
      Logger.error('Failed to create database schema', e, stackTrace);
      throw AppDatabaseException('Failed to create database: ${e.toString()}', e);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic will go here
    Logger.info('Upgrading database from $oldVersion to $newVersion');
  }
  
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
