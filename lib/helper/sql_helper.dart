import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {
  static Future<void> createTables(sql.Database database) async {
    await database.execute("""CREATE TABLE todotrainer(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        title TEXT,
        description TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        startDate Text,
        endDate Text
      )
      """);
    await database.execute("""
    CREATE TABLE archives(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      title TEXT,
      description TEXT,
      createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      startDate TEXT,
      endDate TEXT
    )
  """);
  }


  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'trainer.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
    );
  }

  // Create new
  static Future<int> createItem(String title, String? descrption,
      String? startDate, String endDate) async {
    final db = await SQLHelper.db();

    final data = {
      'title': title,
      'description': descrption,
      'startDate': startDate,
      'endDate': endDate
    };
    final id = await db.insert('todotrainer', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  // Read all items (journals)
  static Future<List<Map<String, dynamic>>> getItems() async {
    final db = await SQLHelper.db();
    return db.query('todotrainer', orderBy: "id");
  }

  // Read a single item by id
  // The app doesn't use this method but I put here in case you want to see it
  static Future<List<Map<String, dynamic>>> getItem(int id) async {
    final db = await SQLHelper.db();
    return db.query('todotrainer', where: "id = ?", whereArgs: [id], limit: 1);
  }

  // Update an item by id
  static Future<int> updateItem(int id, String title, String? descrption,
      String? startDate, String endDate) async {
    final db = await SQLHelper.db();

    final data = {
      'title': title,
      'description': descrption,
      'createdAt': DateTime.now().toString(),
      'startDate': startDate,
      'endDate': endDate
    };

    final result =
    await db.update('todotrainer', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  // Delete
  static Future<void> deleteItem(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("todotrainer", where: "id = ?", whereArgs: [id] );
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }


// Move an item to archives
  static Future<int> moveToArchives(int id) async {
    final db = await SQLHelper.db();
    final data = await getItem(id);
    if (data.isNotEmpty) {
      final item = data.first;
      final archivedItem = {
        'title': item['title'],
        'description': item['description'],
        'createdAt': item['createdAt'],
        'startDate': item['startDate'],
        'endDate': item['endDate']
      };
      final result = await db.insert('archives', archivedItem);
      if (result != null) {
        await deleteItem(id);
        return result;
      }
    }
    return -1; // Indicates an error
  }


}