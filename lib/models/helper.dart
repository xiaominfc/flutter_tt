//
// helper.dart
// Copyright (C) 2019 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//

import 'package:flutter_tt/models/dao.dart';
import 'package:flutter_tt/models/database_helper.dart';
import '../teamtalk_dart_lib/src/client.dart';
import '../teamtalk_dart_lib/src/security.dart';
import '../teamtalk_dart_lib/pb/IM.BaseDefine.pb.dart';
import '../teamtalk_dart_lib/pb/IM.Message.pb.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:event_bus/event_bus.dart';


class NewMsgEvent{
  MessageEntry msg;
  NewMsgEvent(this.msg);
}

class IMHelper {
  TTSecurity security = TTSecurity.DefaultSecurity();
  static IMHelper _instance;
  EventBus eventBus = EventBus(sync:true);

  static IMHelper defaultInstance() {
    if (_instance == null) {
      _instance = IMHelper._internal();
    }
    return _instance;
  }

  factory IMHelper() {
    return defaultInstance();
  }

  IMHelper._internal();
  UserDao userDao = UserDao();
  GroupDao groupDao = GroupDao();
  Map<int, UserEntry> userMap = new Map();
  Map<int, GroupEntry> groupMap = new Map();
  var imClient = new IMClient();

  UserEntry loginUserEntry;

  isSelfId(int id) {
    return id == imClient.userID();
  }

  loadLocalFriends({update = true}) async {
    List users = await userDao.queryAll();
    if (update) {
      userMap.clear();
      users.forEach((user) {
        userMap[user.id] = user;
      });
    }

    return users;
  }

  loadLocalGroups({update = true}) async {
    List groups = await groupDao.queryAll();
    print(groups);
    if (update) {
      groupMap.clear();
      groups.forEach((group) {
        groupMap[group.id] = group;
      });
    }
    return groups;
  }

  initData() async {
    const LASTUSERIDKEY = "lastUserId";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int lastUserId = prefs.getInt(LASTUSERIDKEY);
    if(lastUserId == null || lastUserId != imClient.userID()) {
      await DatabaseHelper.instance.resetDb();
      prefs.setInt(LASTUSERIDKEY, imClient.userID());
      prefs.setInt('users_lastUpdateTime', 0);
    }

    UserInfo loginUserInfo = imClient.loginUserInfo();

    loginUserEntry = UserEntry(id: loginUserInfo.userId,avatar: loginUserInfo.avatarUrl,name: loginUserInfo.userNickName, signInfo: loginUserInfo.signInfo);

    imClient.registerNewMsgHandler((result){
      MessageEntry messageEntry = new MessageEntry(msgId: result.msgId,fromId: result.fromUserId,sessionId: result.fromUserId,msgData: result.msgData,msgType: result.msgType.value,time: result.createTime);
      if(result.msgType == MsgType.MSG_TYPE_GROUP_AUDIO || result.msgType == MsgType.MSG_TYPE_GROUP_TEXT) {
        messageEntry.sessionId = result.toSessionId;
      }
      messageEntry.msgText = decodeMsgData(result.msgData, messageEntry.msgType);
      eventBus.fire(NewMsgEvent(messageEntry));
      
    });
    await loadLocalFriends();
    await loadFriendsFromServer();
    await loadAllGroupsFromServer();
    return 1;
  }

  loginOut() async{
    return imClient.loginOut();
  }

  loadFriendsFromServer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var lastUpdateTime = prefs.getInt('users_lastUpdateTime');
    lastUpdateTime = lastUpdateTime != null ? lastUpdateTime : 0;
    var result = await imClient.requestContacts(lastUpdateTime);
    if (result != null && result.userList.length > 0) {
      prefs.setInt('users_lastUpdateTime', result.latestUpdateTime);
      result.userList.forEach((UserInfo userInfo) {
        UserEntry userEntry = new UserEntry(
            id: userInfo.userId,
            name: userInfo.userNickName,
            avatar: userInfo.avatarUrl,
            signInfo: userInfo.signInfo);
        userDao.updateOrInsert(userEntry);
        userMap[userEntry.id] = userEntry;
      });
    }
    return 1;
  }

  loadAllGroupsFromServer() async {
    var result = await imClient.requestAllGroupVersion();
    if (result != null) {
      List groupVersionList = result.groupVersionList;
      List<int> ids = new List();
      await loadLocalGroups();
      groupVersionList.forEach((groupVerion) {
        GroupEntry entry = groupMap[groupVerion.groupId];
        if (entry == null || entry.version < groupVerion.version) {
          ids.add(groupVerion.groupId);
        }
      });

      if (ids.length > 0) {
        result = await imClient.requestGroupInfoByIds(ids);
        if (result != null && result.groupInfoList.length > 0) {
          for (int i = 0; i < result.groupInfoList.length; i++) {
            GroupInfo groupInfo = result.groupInfoList[i];
            GroupEntry entry = new GroupEntry(
                id: groupInfo.groupId,
                name: groupInfo.groupName,
                avatar: groupInfo.groupAvatar,
                version: groupInfo.version,
                shieldStatus: groupInfo.shieldStatus);
            await groupDao.save(entry);
            groupMap[groupInfo.groupId] = entry;
          }
        }
      }
    }
    return 1;
  }

  loadMessagesByServer(int sessionId, int type,
      {beginMsgId = 0, cnt = 20}) async {
    IMGetMsgListRsp result;
    if (type == IMSeesionType.Person) {
      result = await imClient.loadSingleChatMsgs(sessionId, beginMsgId, cnt);
    } else {
      result = await imClient.loadGroupChatMsgs(sessionId, beginMsgId, cnt);
    }
    List<MessageEntry> msgs = List();
    if (result != null && result.msgList != null) {
      result.msgList.forEach((MsgInfo msg) {
        //String msgText = decodeMsgData(msg.msgData, msg.msgType);
        var messageEntry2 = new MessageEntry(
            fromId: msg.fromSessionId,
            msgData: msg.msgData,
            msgId: msg.msgId,
            time: msg.createTime,
            msgType: msg.msgType.value);
        MessageEntry messageEntry = messageEntry2;
        msgs.add(messageEntry);
      });
    }
    return msgs;
  }


  decodeToImage(msgData) {
    try {
      var tmplastMsg = utf8.decode(msgData);
      if(tmplastMsg.length > 10 && tmplastMsg.startsWith("&\$#@~^@[{:")) {
        return tmplastMsg;
      }
      return security.decryptText(tmplastMsg);
    }catch(e) {

    }
    return "";
  }

  decodeMsgData(msgData, int msgType) {
    String lastMsg = '';
    try {
      var tmplastMsg = utf8.decode(msgData);
      if (tmplastMsg.length > 10 && tmplastMsg.startsWith("&\$#@~^@[{:")) {
        lastMsg = '[图片]';
      } else if (msgType == MsgType.MSG_TYPE_GROUP_AUDIO.value ||
          msgType == MsgType.MSG_TYPE_SINGLE_AUDIO.value) {
        lastMsg = '[语音]';
      } else {
        lastMsg = security.decryptText(tmplastMsg);
        if(lastMsg.length > 10 && lastMsg.startsWith("&\$#@~^@[{:")) {
          lastMsg = '[图片]';
        }
      }
    } catch (e) {
      return "";
    }
    return lastMsg;
  }

  requestUnReadCnt() async {
    var result = await imClient.requestUnReadMsgCnt();
    print(result);
  }



  loadSessionsFromServer() async {
    //保证在initData之后

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var lastUpdateTime = prefs.getInt('sessions_lastUpdateTime');
    lastUpdateTime = lastUpdateTime != null ? lastUpdateTime : 0;
    var result = await imClient.requestSessions(lastUpdateTime);
    List<SessionEntry> sessions = new List();
    if (result != null && result.contactSessionList.length > 0) {
      prefs.setInt('sessions_lastUpdateTime', lastUpdateTime);
      for (int i = 0; i < result.contactSessionList.length; i++) {
        ContactSessionInfo sessionInfo = result.contactSessionList[i];
        //print(sessionInfo);
        SessionEntry sessionEntry = new SessionEntry();
        int sessionID = sessionInfo.sessionId;
        sessionEntry.sessionId = sessionID;
        sessionEntry.lastMsg =
            decodeMsgData(sessionInfo.latestMsgData, sessionInfo.latestMsgType.value);
        if (sessionInfo.sessionType == SessionType.SESSION_TYPE_GROUP) {
          sessionEntry.sessionType = IMSeesionType.Group;
          GroupEntry entry = groupMap[sessionID];
          if (entry == null) {
            print('not GroupEntry for:$sessionID');
            continue;
          }
          sessionEntry.avatar = entry.avatar;
          sessionEntry.sessionName = entry.name;
        } else {
          sessionEntry.sessionType = IMSeesionType.Person;
          UserEntry entry = userMap[sessionID];
          if (entry == null) {
            print('not user for:$sessionID');
            continue;
          }
          sessionEntry.avatar = entry.avatar;
          sessionEntry.sessionName = entry.name;
        }
        sessions.add(sessionEntry);
      }
    }
    return sessions;
  }

  buildTextMsg(String text,int sessionId,int sessionType) {
    int msgType = IMMsgType.MSG_TYPE_GROUP_TEXT;
    if(sessionType == IMSeesionType.Person) {
      msgType = IMMsgType.MSG_TYPE_SINGLE_TEXT;
    }
    MessageEntry msg = MessageEntry(msgId: 0, msgData: utf8.encode(security.encryptText(text)), fromId:imClient.userID(),msgType: msgType);
    return msg;
  }

  

  sendTextMsg(String text,int sessionId,int sessionType) async{
    IMMsgDataAck result;
    int msgType = IMMsgType.MSG_TYPE_GROUP_TEXT;
    if(sessionType == IMSeesionType.Person) {
      result =  await imClient.sendTextMsg(text, sessionId);
      msgType = IMMsgType.MSG_TYPE_SINGLE_TEXT;
    }else {
      result =  await imClient.sendGroupTextMsg(text, sessionId);
    }
    if(result != null) {
      MessageEntry msg = MessageEntry(msgId: result.msgId, msgData: utf8.encode(text), fromId:result.userId,msgType: msgType);
    //print(result);
    return msg;
    }
    return null;
    
  }
}
