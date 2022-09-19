import 'dart:async';
import 'package:flutter/material.dart';
import 'package:seasonalclothesproject/extentions/list/filter.dart';
import 'package:seasonalclothesproject/services/crud/crud_exceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

class GarmentsService {
  Database? _db;

  List<DatabaseGarment> _garments = [];

  DatabaseUser? _user;

  static final GarmentsService _shared = GarmentsService._sharedInstance();
  GarmentsService._sharedInstance() {
    _garmentsStreamController =
        StreamController<List<DatabaseGarment>>.broadcast(
      onListen: () {
        _garmentsStreamController.sink.add(_garments);
      },
    );
  }
  factory GarmentsService() => _shared;

  late final StreamController<List<DatabaseGarment>> _garmentsStreamController;

  Stream<List<DatabaseGarment>> get allGarments =>
      _garmentsStreamController.stream.filter((garment) {
        final currentUser = _user;
        if (currentUser != null) {
          return garment.userId == currentUser.id;
        } else {
          throw UserShouldBeSetBeforeReadingAllGarments();
        }
      });

  Future<DatabaseUser> getOrCreateUser({
    required String email,
    bool setAsCurrentUser = true,
  }) async {
    try {
      final user = await getUser(email: email);
      if (setAsCurrentUser) {
        _user = user;
      }
      return user;
    } on CouldNotFindUser {
      final createdUser = await createUser(email: email);
      if (setAsCurrentUser) {
        _user = createdUser;
      }
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cacheGarments() async {
    final allGarments = await getAllGarments();
    _garments = allGarments.toList();
    _garmentsStreamController.add(_garments);
  }

  Future<DatabaseGarment> updateGarment({
    required DatabaseGarment garment,
    required String text,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    //make sure garment exists
    await getGarment(id: garment.id);

    //update DB
    final updatesCount = await db.update(
      garmentTable,
      {
        textColumn: text,
        isSyncedWithCloudColumn: 0,
      },
      where: 'id = ?',
      whereArgs: [garment.id],
    );

    if (updatesCount == 0) {
      throw CouldNotUpdateGarment();
    } else {
      final updatedGarment = await getGarment(id: garment.id);
      _garments.removeWhere((garment) => garment.id == updatedGarment.id);
      _garments.add(updatedGarment);
      _garmentsStreamController.add(_garments);
      return updatedGarment;
    }
  }

  Future<Iterable<DatabaseGarment>> getAllGarments() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final allGarments = await db.query(garmentTable);

    return allGarments.map((garmentRow) => DatabaseGarment.fromRow(garmentRow));
  }

  Future<DatabaseGarment> getGarment({required int id}) async {
    await _ensureDbIsOpen();
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
      _garments.removeWhere((garment) => garment.id == id);
      _garments.add(garment);
      _garmentsStreamController.add(_garments);
      return garment;
    }
  }

  Future<int> deleteAllGarments() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(garmentTable);
    _garments = [];
    _garmentsStreamController.add(_garments);
    return numberOfDeletions;
  }

  Future<void> deleteGarment({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      garmentTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteGarment();
    } else {
      _garments.removeWhere((garment) => garment.id == id);
      _garmentsStreamController.add(_garments);
    }
  }

  Future<DatabaseGarment> createGarment({required DatabaseUser owner}) async {
    await _ensureDbIsOpen();
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

    _garments.add(garment);
    _garmentsStreamController.add(_garments);

    return garment;
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

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
      //empty
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
      await _cacheGarments();
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
