//
// database_helper.dart
// Copyright (C) 2019 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//


import 'dart:io';
import 'package:flutter_tt/models/dao.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';


class DatabaseHelper {

  static final _databaseName = "flutter_tt.db";
  static final _databaseVersion = 4;
  static Database _database;

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDb();
    return _database;
  }


  _initDb() async{
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onDowngrade: _onDowngrade);
  }

  _onCreate(Database db, int version) async{
    await UserDao().initTable(db, version);
    await GroupDao().initTable(db, version);
    await SessionDao().initTable(db, version);
  }


  _onUpgrade(Database db,int oldVersion, int newVersion) async{
    await _onCreate(db, newVersion);
  }

  _onDowngrade(Database db,int oldVersion, int newVersion) async{
    await _onCreate(db, newVersion);
  }

  resetDb()async{
    await _onCreate(await database, _databaseVersion);
  }

  


  Future close() async => _database.close();
}


abstract class BaseItem{
  BaseItem();
  Map<String, dynamic> toMap();
  fromMap(Map<String, dynamic> map);
  @override
  String toString() {
    return toMap().toString();
  }
}

abstract class BaseDao<T extends BaseItem> {

  String tableName();

  Future<List> queryAll() async {
    return queryAllWith(null);
  }

  initTable(Database db, int version);

  dropTable(Database db, int version) async{
    await db.execute('DROP TABLE IF EXISTS ' + tableName());
  }

  Future<List> queryAllWith(String where,{List<dynamic> args}) async {
    Database db = await DatabaseHelper.instance.database;
    List result;
    if(where == null) {
      result = await db.rawQuery("select * FROM " + tableName());
    }else {
      result = await db.rawQuery("select * FROM " + tableName() + "  where " + where, args);
    }
    return result.map((item)=>buildItem(item)).toList();
  }


  Future<int> queryCount() async {
    Database db = await DatabaseHelper.instance.database;
    return Sqflite.firstIntValue(await db.rawQuery("select COUNT(*) FROM " + tableName()));
  }

  Future<int> save(T item)async {
    Database db = await DatabaseHelper.instance.database;
    return db.insert(tableName(), item.toMap());
  }

  T buildItem(Map<String, dynamic> map);
}


abstract class PrimaryDao<T extends BaseItem>  extends BaseDao{

  PrimaryDao();

  String primarykey(){
    return "id";
  }

  Future<int> updateOrInsert(T item) async {
    Map mapData = item.toMap();
    T result = await queryPrimarykey(mapData[primarykey()]);
    Database db = await DatabaseHelper.instance.database;
    if(result != null) {
      return await db.update(tableName(), mapData,
        where: primarykey() + ' = ?', whereArgs: [mapData[primarykey()]]);
    }
    return save(item);
  }

  Future<T> queryPrimarykey(var id) async {
    List result = await queryAllWith(primarykey() +  ' = ? limit 1',args:[id]);
    if(result.length > 0) {
      return result[0];
    }
    return null;
  }

  Future<int>  delete(var id) async{
    Database db = await DatabaseHelper.instance.database;
    return await db.delete(tableName(), where: primarykey() + ' = ?', whereArgs: [id]);
  }
}
