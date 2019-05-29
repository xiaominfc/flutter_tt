import 'package:sqflite/sqlite_api.dart';

import './database_helper.dart';


class UserEntry extends BaseItem {

  String name;
  String avatar;
  int id;
  UserEntry({this.id,this.name,this.avatar});

  @override
  Map<String, dynamic> toMap() {
    return {'id':id, 'name':name, 'avatar':avatar};
  }
  @override
  fromMap(Map<String, dynamic> map){
    this.id = map['id'];
    this.name = map['name'];
    this.avatar = map['avatar'];
    return this;
  }


  @override
  String toString() {
    return toMap().toString();
  }
  
}

class UserDao extends PrimaryDao<UserEntry> {
  // static UserDao _instance;
  // static UserDao instance(){
  //   if(_instance == null) {
  //     _instance = new UserDao._internal();
  //   }
  //   return _instance;
  // }
  // UserDao._internal();
  // factory UserDao() => instance();

  @override
  String tableName() {
    return 'user';
  }

  @override
  buildItem(Map<String, dynamic> map) {
    return UserEntry().fromMap(map);
  }

  @override
  initTable(Database db, int version) async{
    dropTable(db, version);
    await db.execute('CREATE TABLE user (id INTEGER PRIMARY KEY, name TEXT, avatar TEXT)');
  }
}


class GroupEntry extends BaseItem {

  int id;
  String name;
  String avatar;
  int version;
  int shieldStatus;

  GroupEntry({this.id,this.name,this.avatar,this.version,this.shieldStatus});

  @override
  Map<String, dynamic> toMap() {
    return {'id':id,'name':name, 'avatar':avatar, 'version':version, 'shieldStatus':shieldStatus};
  }

  @override
  fromMap(Map<String, dynamic> map) {
    id=map['id'];
    name = map['name'];
    avatar = map['avatar'];
    version = map['version'];
    shieldStatus = map['shieldStatus'];
    return this;
  }
}

class GroupDao extends PrimaryDao<GroupEntry> {

  @override
  BaseItem buildItem(Map<String, dynamic> map) {
    return GroupEntry().fromMap(map);
  }

  @override
  initTable(Database db, int version) async{
    dropTable(db, version);
    await db.execute('CREATE TABLE imgroup (id INTEGER PRIMARY KEY, name TEXT, avatar TEXT, version INTEGER, shieldStatus INTEGER)');
  }

  @override
  String tableName() {
    return "imgroup";
  }
}


class IMMsgType {
  static int MSG_TYPE_SINGLE_TEXT = 1;
  static int MSG_TYPE_SINGLE_AUDIO = 2;
  static int MSG_TYPE_GROUP_TEXT = 17;
  static int MSG_TYPE_GROUP_AUDIO = 18;
}



class IMMsgSendStatus {
  static int Sending = 1;
  static int Ok = 2;
  static int Failed = 0;
}

class MessageEntry extends BaseItem {
  int fromId;
  int sessionId;
  int msgId;
  String msgText;
  int time;
  List msgData;
  int msgType;

  int sendStatus = IMMsgSendStatus.Ok;

  MessageEntry({this.msgId,this.fromId,this.msgData,this.sessionId,this.time,this.msgType});

  @override
  fromMap(Map<String, dynamic> map) {
    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    return {'fromId':fromId, 'msgId':msgId, 'msgText':msgText, 'time':time,'sessionId':sessionId,'msgType':msgType};
  }
}

class IMSeesionType {
  static int Person=1;
  static int Group=2;
}

class SessionEntry extends BaseItem {

  int sessionId;
  String lastMsg;
  String sessionName;
  String avatar;
  int sessionType;

  @override
  Map<String, dynamic> toMap() {
    
    return {'sessionId':sessionId, 'sessionName':sessionName, 'lastMsg':lastMsg, 'avatar':avatar, 'sessionType':sessionType};
  }

  @override
  fromMap(Map<String, dynamic> map) {
    // TODO: implement fromMap
    return this;
  }


}

