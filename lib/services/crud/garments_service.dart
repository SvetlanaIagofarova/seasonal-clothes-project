import 'package:flutter/material.dart';
import 'package:seasonalclothesproject/services/crud/crud_exceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

class GarmentsService {
  Database? _db;

  Future<DatabaseGarment> updateGarment({
    required DatabaseGarment garment,
    required String text,
  }) async {
    final db = _getDatabaseOrThrow();

    //make sure clothes exists
    await getGarment(id: garment.id);

    //update DB
    final updatesCount = await db.update(garmentTable, {
      textColumn: text,
      isSyncedWithCloudColumn: 0,
    });

    if (updatesCount == 0) {
      throw CouldNotUpdateGarment();
    } else {
      return await getGarment(id: garment.id);
    }
  }

  Future<Iterable<DatabaseGarment>> getAllGarments() async {
    final db = _getDatabaseOrThrow();
    final allGarments = await db.query(garmentTable);

    return allGarments.map((garmentRow) => DatabaseGarment.fromRow(garmentRow));
  }

  Future<DatabaseGarment> getGarment({required int id}) async {
    final db = _getDatabaseOrThrow();
    final garments = await db.query(
      garmentTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (garments.isEmpty) {
      throw CouldNotFindGarment();
    } else {
      final garment = DatabaseGarment.fromRow(garments.first);
      return garment;
    }
  }

  Future<int> deleteAllGarments() async {
    final db = _getDatabaseOrThrow();
    return await db.delete(garmentTable);
  }

  Future<void> deleteGarment({required int id}) async {
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      garmentTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteGarment();
    }
  }

  Future<DatabaseGarment> createGarment({required DatabaseUser owner}) async {
    final db = _getDatabaseOrThrow();

    //make sure owner exists in the database with the correct id
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw CouldNotFindUser();
    }

    const text = '';
    //create the  garment
    final garmentId = await db.insert(garmentTable, {
      userIdColumn: owner.id,
      textColumn: text,
      isSyncedWithCloudColumn: 1,
    });

    final garment = DatabaseGarment(
      id: garmentId,
      userId: owner.id,
      text: text,
      isSyncedWithCloud: true,
    );

    return garment;
  }

  Future<DatabaseUser> getUser({required String email}) async {
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
      // create the user table
      await db.execute(createUserTable);
      // create garment table
      await db.execute(createGarmentTable);
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

class DatabaseGarment {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  DatabaseGarment({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DatabaseGarment.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        isSyncedWithCloud =
            (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Garment, ID = $id, userId = $userId, isSyncedWithCloud = $isSyncedWithCloud, text = $text';

  @override
  bool operator ==(covariant DatabaseGarment other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'clothes.db';
const garmentTable = 'garment';
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
const createGarmentTable = '''CREATE TABLE IF NOT EXISTS "garment" (
	"id"	INTEGER NOT NULL,
	"user_id"	INTEGER NOT NULL,
	"text"	TEXT,
	"is_synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
	FOREIGN KEY("user_id") REFERENCES "user"("id"),
	PRIMARY KEY("id" AUTOINCREMENT)
);''';