import 'dart:async';

import 'package:flutter/material.dart';
import 'package:seasonalclothesproject/services/crud/crud_exceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

class ClothesSevice {
  Database? _db;

  List<DatabaseClothes> _clothes = [];

  static final ClothesSevice _shared = ClothesSevice._sharedInstance();
  ClothesSevice._sharedInstance();
  factory ClothesSevice() => _shared;

  final _clothesStreamController =
      StreamController<List<DatabaseClothes>>.broadcast();

  Stream<List<DatabaseClothes>> get allClothes =>
      _clothesStreamController.stream;

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
      //empty
    }
  }

  Future<DatabaseUser> getOrCreateUser({required String email}) async {
    try {
      final user = await getUser(email: email);
      return user;
    } on CouldNotFindUser {
      final createdUser = await createUser(email: email);
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cachClothes() async {
    final allClothes = await getAllClothes();
    _clothes = allClothes.toList();
    _clothesStreamController.add(_clothes);
  }

  Future<DatabaseClothes> updateClothes({
    required DatabaseClothes clothes,
    required String text,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    //make sure clothes exists
    await getClothes(id: clothes.id);

    //update DB
    final updatesCount = await db.update(clothesTable, {
      textColumn: text,
      isSyncedWithCloudColumn: 0,
    });

    if (updatesCount == 0) {
      throw CouldNotUpdateClothes();
    } else {
      final updatedClothes = await getClothes(id: clothes.id);
      _clothes.removeWhere((clothes) => clothes.id == updatedClothes.id);
      _clothes.add(updatedClothes);
      _clothesStreamController.add(_clothes);
      return updatedClothes;
    }
  }

  Future<Iterable<DatabaseClothes>> getAllClothes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final allClothes = await db.query(clothesTable);

    return allClothes.map((clothesRow) => DatabaseClothes.fromRow(clothesRow));
  }

  Future<DatabaseClothes> getClothes({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final allClothes = await db.query(
      clothesTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (allClothes.isEmpty) {
      throw CouldNotFindClothes();
    } else {
      final clothes = DatabaseClothes.fromRow(allClothes.first);
      _clothes.removeWhere((clothes) => clothes.id == id);
      _clothes.add(clothes);
      _clothesStreamController.add(_clothes);
      return clothes;
    }
  }

  Future<int> deleteAllClothes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(clothesTable);
    _clothes = [];
    _clothesStreamController.add(_clothes);
    return numberOfDeletions;
  }

  Future<void> deleteClothes({required String id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteClothes();
    } else {
      final countBefore = _clothes.length;
      _clothes.removeWhere((clothes) => clothes.id == id);
      if (_clothes.length != countBefore) {
        _clothesStreamController.add(_clothes);
      }
    }
  }

  Future<DatabaseClothes> createClothes({required DatabaseUser owner}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    //make sure owner exists in the database with the correct id
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw CouldNotFindUser();
    }

    const text = '';
    //create clothes
    final clothesId = await db.insert(clothesTable, {
      userIdColumn: owner.id,
      textColumn: text,
      isSyncedWithCloudColumn: 1,
    });

    final clothes = DatabaseClothes(
      id: clothesId,
      userId: owner.id,
      text: text,
      isSyncedWithCloud: true,
    );

    _clothes.add(clothes);
    _clothesStreamController.add(_clothes);

    return clothes;
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isEmpty) {
      throw CouldNotFindUser();
    } else {
      return DatabaseUser.fromRow(results.first);
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExists();
    }

    final userId = await db.insert(userTable, {
      emailColumn: email.toLowerCase(),
    });

    return DatabaseUser(
      id: userId,
      email: email,
    );
  }

  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;
      // create user table
      await db.execute(createUserTable);
      // create clothes table
      await db.execute(createClothesTable);
      await _cachClothes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;

  const DatabaseUser({
    required this.id,
    required this.email,
  });

  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'Person, ID = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseClothes {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  DatabaseClothes(
      {required this.id,
      required this.userId,
      required this.text,
      required this.isSyncedWithCloud});

  DatabaseClothes.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[emailColumn] as int,
        text = map[textColumn] as String,
        isSyncedWithCloud =
            (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Clothes, ID = $id, userId = $userId, isSyncedWithCloud = $isSyncedWithCloud, text = $text';

  @override
  bool operator ==(covariant DatabaseClothes other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'clothes.db';
const clothesTable = 'clothes';
const userTable = 'user';
const idColumn = 'id';
const emailColumn = 'email';
const userIdColumn = 'user_id';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';
const createUserTable = '''CREATE TABLE IF NOT EXISTS "user" (
	    "id"	INTEGER NOT NULL,
	    "email"	TEXT NOT NULL UNIQUE,
	    PRIMARY KEY("id" AUTOINCREMENT)
    );''';
const createClothesTable = '''CREATE TABLE IF NOT EXISTS "clothes" (
      "id"	INTEGER NOT NULL,
      "user_id"	INTEGER NOT NULL,
      "text"	TEXT,
      "is_synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY("user_id") REFERENCES "user"("id"),
      PRIMARY KEY("id" AUTOINCREMENT)
    );''';
