import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class StoredMemory {
  final int? id;
  final String keyConcept;
  final String content;
  final String locationContext;
  final String embeddingReference;
  final double confidence;
  final String updatedAt;

  StoredMemory({
    this.id,
    required this.keyConcept,
    required this.content,
    required this.locationContext,
    this.embeddingReference = '',
    this.confidence = 0.95,
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key_concept': keyConcept,
      'content': content,
      'location_context': locationContext,
      'embedding_reference': embeddingReference,
      'confidence': confidence,
      'updated_at': updatedAt,
    };
  }

  factory StoredMemory.fromMap(Map<String, dynamic> map) {
    return StoredMemory(
      id: map['id'] as int?,
      keyConcept: map['key_concept'] as String? ?? '',
      content: map['content'] as String? ?? '',
      locationContext: map['location_context'] as String? ?? '',
      embeddingReference: map['embedding_reference'] as String? ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.95,
      updatedAt: map['updated_at'] as String?,
    );
  }
}

class ExpiryRecord {
  final int? id;
  final String itemName;
  final String category;
  final String expiryDate;
  final String source;
  final double confidence;
  final String createdAt;

  ExpiryRecord({
    this.id,
    required this.itemName,
    required this.category,
    required this.expiryDate,
    this.source = 'ocr',
    this.confidence = 0.90,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_name': itemName,
      'category': category,
      'expiry_date': expiryDate,
      'source': source,
      'confidence': confidence,
      'created_at': createdAt,
    };
  }

  factory ExpiryRecord.fromMap(Map<String, dynamic> map) {
    return ExpiryRecord(
      id: map['id'] as int?,
      itemName: map['item_name'] as String? ?? '',
      category: map['category'] as String? ?? 'food',
      expiryDate: map['expiry_date'] as String? ?? '',
      source: map['source'] as String? ?? 'ocr',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.90,
      createdAt: map['created_at'] as String?,
    );
  }
}

class AppDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'omnisense_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // User Memories Table
        await db.execute('''
          CREATE TABLE user_memory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            key_concept TEXT NOT NULL,
            content TEXT NOT NULL,
            location_context TEXT NOT NULL,
            embedding_reference TEXT DEFAULT '',
            confidence REAL DEFAULT 0.95,
            updated_at TEXT NOT NULL
          )
        ''');

        // Expiries Table
        await db.execute('''
          CREATE TABLE expiries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_name TEXT NOT NULL,
            category TEXT NOT NULL,
            expiry_date TEXT NOT NULL,
            source TEXT DEFAULT 'ocr',
            confidence REAL DEFAULT 0.90,
            created_at TEXT NOT NULL
          )
        ''');

        // Observations Table for Change Detection
        await db.execute('''
          CREATE TABLE observations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            objects_json TEXT NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');

        // Seed initial sample visual memories
        await db.insert('user_memory', {
          'key_concept': 'keys',
          'content': 'Your office keys are on the study table near the laptop.',
          'location_context': 'study table',
          'confidence': 0.98,
          'updated_at': DateTime.now().toIso8601String(),
        });

        await db.insert('user_memory', {
          'key_concept': 'watch',
          'content': 'Your wrist watch is placed on the bedside nightstand.',
          'location_context': 'bedside nightstand',
          'confidence': 0.95,
          'updated_at': DateTime.now().toIso8601String(),
        });
      },
    );
  }

  // --- Memory Operations ---
  static Future<int> insertMemory(StoredMemory memory) async {
    final db = await database;
    return await db.insert('user_memory', memory.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<StoredMemory>> searchMemories(String term) async {
    final db = await database;
    final cleanTerm = term.trim().toLowerCase();

    final maps = await db.query(
      'user_memory',
      where: 'LOWER(key_concept) LIKE ? OR LOWER(content) LIKE ? OR LOWER(location_context) LIKE ?',
      whereArgs: ['%$cleanTerm%', '%$cleanTerm%', '%$cleanTerm%'],
      orderBy: 'updated_at DESC',
    );

    if (maps.isEmpty) {
      final allMaps = await db.query('user_memory', orderBy: 'updated_at DESC', limit: 5);
      return allMaps.map((m) => StoredMemory.fromMap(m)).toList();
    }

    return maps.map((m) => StoredMemory.fromMap(m)).toList();
  }

  // --- Expiry Operations ---
  static Future<int> insertExpiry(ExpiryRecord record) async {
    final db = await database;
    return await db.insert('expiries', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<ExpiryRecord>> getExpiries() async {
    final db = await database;
    final maps = await db.query('expiries', orderBy: 'expiry_date ASC');
    return maps.map((m) => ExpiryRecord.fromMap(m)).toList();
  }

  // --- Observation Operations ---
  static Future<void> insertObservation(String objectsJson) async {
    final db = await database;
    await db.insert('observations', {
      'objects_json': objectsJson,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getRecentObservations({int limit = 2}) async {
    final db = await database;
    return await db.query('observations', orderBy: 'id DESC', limit: limit);
  }

  // --- Privacy Operations ---
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('user_memory');
    await db.delete('expiries');
    await db.delete('observations');
  }
}
