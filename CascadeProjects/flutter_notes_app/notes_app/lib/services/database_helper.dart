import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart';
import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  bool _useHive = false;
  sql.Database? _db;
  Box? _box;

  Future<void> init() async {
    _useHive = kIsWeb;

    if (_useHive) {
      await Hive.initFlutter();
      _box = await Hive.openBox('notesBox');
      return;
    }

    final dbPath = await sql.getDatabasesPath();
    final path = join(dbPath, 'notes.db');

    _db = await sql.openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create Users table
        await db.execute('''
          CREATE TABLE users (
            email TEXT PRIMARY KEY,
            fullName TEXT NOT NULL,
            password TEXT NOT NULL
          )
        ''');

        // Create Notes table
        await db.execute('''
          CREATE TABLE notes (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            category TEXT,
            isPinned INTEGER NOT NULL
          )
        ''');
      },
    );

    // Guarantee "users" table exists (important for older DBs)
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS users (
        email TEXT PRIMARY KEY,
        fullName TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // Guarantee "notes" table exists (important for older DBs)
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        category TEXT,
        isPinned INTEGER NOT NULL
      )
    ''');
  }

  // ================= USER ACCOUNT =================

  Future<void> saveUser(String email, String fullName, String password) async {
    final userData = {
      "email": email,
      "fullName": fullName,
      "password": password,
    };

    if (_useHive) {
      await _box!.put("user_$email", userData);
      return;
    }

    await _db!.insert(
      'users',
      userData,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUser(String email) async {
    if (_useHive) {
      final data = _box!.get("user_$email");
      if (data == null) return null;
      return Map<String, dynamic>.from(data);
    }

    final result = await _db!.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  /// 🔥 Check if ANY user exists (used by main.dart / AuthGate)
  Future<Map<String, dynamic>?> getAnyUser() async {
    if (_useHive) {
      final key = _box!.keys.firstWhere(
        (k) => k.toString().startsWith("user_"),
        orElse: () => null,
      );
      if (key == null) return null;
      return Map<String, dynamic>.from(_box!.get(key));
    }

    final result = await _db!.query('users', limit: 1);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // ================= NOTES =================

  Future<List<Note>> readAllNotes() async {
    if (_useHive) {
      final notes = _box!.values
          .where((e) => e is Map && e["type"] == "note")
          .map((e) => Note.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes;
    }

    final result = await _db!.query('notes', orderBy: 'updatedAt DESC');
    return result.map((e) => Note.fromMap(e)).toList();
  }

  Future<List<Note>> readPinnedNotes() async {
    if (_useHive) {
      final notes = _box!.values
          .where((e) => e is Map && e["type"] == "note")
          .map((e) => Note.fromMap(Map<String, dynamic>.from(e)))
          .where((n) => n.isPinned)
          .toList();
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes;
    }

    final result = await _db!.query(
      'notes',
      where: 'isPinned = ?',
      whereArgs: [1],
      orderBy: 'updatedAt DESC',
    );
    return result.map((e) => Note.fromMap(e)).toList();
  }

  Future<Note> create(Note note) async {
    if (_useHive) {
      final map = note.toMap();
      map["type"] = "note";
      await _box!.put(note.id, map);
      return note;
    }
    await _db!.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
    return note;
  }

  Future<int> update(Note note) async {
    if (_useHive) {
      final map = note.toMap();
      map["type"] = "note";
      await _box!.put(note.id, map);
      return 1;
    }
    return await _db!
        .update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<int> delete(String id) async {
    if (_useHive) {
      await _box!.delete(id);
      return 1;
    }
    return await _db!.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> searchNotes(String query) async {
    if (_useHive) {
      final q = query.toLowerCase();
      final notes = _box!.values
          .where((e) => e is Map && e["type"] == "note")
          .map((e) => Note.fromMap(Map<String, dynamic>.from(e)))
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.content.toLowerCase().contains(q))
          .toList();
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes;
    }

    final result = await _db!.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updatedAt DESC',
    );
    return result.map((e) => Note.fromMap(e)).toList();
  }

  // ================= CLOSE =================

  Future close() async {
    if (_useHive) {
      await _box!.close();
      return;
    }
    await _db!.close();
  }
}
