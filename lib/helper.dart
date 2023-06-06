import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'todo.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            eventName TEXT,
            eventDate TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertEvent(String eventName, String eventDate) async {
    final db = await database;
    await db.insert(
      'events',
      {
        'eventName': eventName,
        'eventDate': eventDate,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    final db = await database;
    return await db.query('events');
  }

  Future<void> updateEvent(int id, String eventName, String eventDate) async {
    final db = await database;
    await db.update(
      'events',
      {
        'eventName': eventName,
        'eventDate': eventDate,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteEvent(int id) async {
    final db = await database;
    await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
