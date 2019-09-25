//
// chat_page.dart
// Copyright (C) 2019 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tt/utils/utils.dart';
import '../models/dao.dart';
import 'message_page.dart';
import '../models/helper.dart';
import '../utils/utils.dart';


class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() =>_ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List _sessions;

  StreamSubscription subscription;

  IMHelper imHelper = IMHelper.defaultInstance();
  void updateData() async {
    var sessions = await imHelper.loadLocalSessions();
    bool force = true;
    if (sessions.length > 0) {
      setState(() {
        _sessions = sessions;
      });
      force = false;
    }
    imHelper
        .loadSessionsFromServer(force: force)
        .then((result) async {
      if (result > 0) {
        _sessions = await imHelper.loadLocalSessions();
      }
      await _updateUnReadCnt();
      setState(() {});
    });
  }


  void _onEvent(NewMsgEvent event) async{

    if(imHelper.showSessionEntry == null || event.sessionKey != imHelper.showSessionEntry.sessionKey) {
        SessionEntry sessionEntry = imHelper.getSessionBySessionKey(event.sessionKey);
        if(sessionEntry != null) {
          sessionEntry.updatedTime = event.msg.time;
          sessionEntry.lastMsg = imHelper.decodeMsgData(event.msg.msgData, event.msg.msgType);
          sessionEntry.unreadCnt = sessionEntry.unreadCnt + 1;
        }else {
          MessageEntry msg = event.msg;
          sessionEntry = await imHelper.buildAndSaveSessionForNewMsg(msg);
          _sessions.insert(0, sessionEntry);
        }
        setState(() {
            
        });
    }
  }

  @override
  void initState() {
    super.initState();
    updateData();
    subscription = imHelper.eventBus.on<NewMsgEvent>().listen((event) {
      _onEvent(event);
    });
  }

  @override
  void dispose(){
    subscription.cancel();
    super.dispose();
  }

  @override
  void deactivate() {
    super.deactivate();
  }
  

  _updateUnReadCnt() async {
    await IMHelper.defaultInstance().requestUnReadCnt();
  }

  _onTap(int position) {
    navigatePushPage(this.context, MessagePage(_sessions[position]));
  }


  Widget buildTailWidget(int unReadCnt, int updateTime){
    DateTime date = new DateTime.fromMillisecondsSinceEpoch(updateTime * 1000);
    return  Row(
        mainAxisSize:MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(dateFormat(date,"")),
          unReadCnt > 0 ? Container(
              child: Center(child: Text(unReadCnt.toString(),style: TextStyle(color: Colors.white))),
              width: 20,
              decoration: new BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
              ),
          )
          : Icon(
              Icons.arrow_forward_ios,
          )
        ],
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('消息',
          style: TextStyle(
            fontStyle: FontStyle.normal,
          ),
        )),
        body: Center(
          child: ListView.builder(
            itemCount: _sessions == null ? 0 : _sessions.length,
            itemBuilder: (context, position) {
              SessionEntry sessionEntry = _sessions[position];
              var avatar;
              var name;
              if(sessionEntry.sessionType == IMSeesionType.Person){
                UserEntry user = imHelper.userMap[sessionEntry.sessionId];
                avatar = user.avatar;
                name = user.name;
              }else {
                GroupEntry group = imHelper.groupMap[sessionEntry.sessionId];
                avatar = group.avatar;
                name = group.name;
              }

              int unReadCnt = sessionEntry.unreadCnt;
              return Column(children: <Widget>[
                GestureDetector(
                  onTap: () => _onTap(position),
                  child: ListTile(
                    leading: ClipOval(
                      child: avatar==null?Image.asset('images/avatar_default.png'):FadeInImage(
                        image: NetworkImage(avatar),
                        width: 56,
                        height: 56,
                        fit:BoxFit.fitWidth,
                        placeholder: AssetImage('images/avatar_default.png'),
                      ),
                    ),
                    title: Text(name??"",
                        style: Theme.of(context).textTheme.subhead),
                    subtitle: new Text(sessionEntry.lastMsg, maxLines: 1),
                    trailing: buildTailWidget(unReadCnt, sessionEntry.updatedTime),
                  ),
                ),
                Divider(
                  height: 12.0,
                ),
              ]);
            },
          ),
        ));
  }
}
