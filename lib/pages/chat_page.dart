//
// chat_page.dart
// Copyright (C) 2019 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//

import 'package:flutter/material.dart';
import 'package:flutter_tt/utils/utils.dart';
import '../models/dao.dart';
import 'message_page.dart';
import '../models/helper.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() {
    print('createState');
    return new _ChatPageState();
  }
}

class _ChatPageState extends State<ChatPage> {
  List _sessions;
  void updateData() async {
    var sessions = await IMHelper.defaultInstance().loadLocalSessions();
    bool force = true;
    if (sessions.length > 0) {
      setState(() {
        _sessions = sessions;
      });
      force = false;
    }
    IMHelper.defaultInstance()
        .loadSessionsFromServer(force: force)
        .then((result) async {
      if (result > 0) {
        _sessions = await IMHelper.defaultInstance().loadLocalSessions();
      }
      await _updateUnReadCnt();
      setState(() {});
    });
  }

  @override
  void initState() {
    print("chat init");
    super.initState();
    updateData();
  }

  @override
  void deactivate() {
    super.deactivate();
    //print("chat deactivate");
  }
  

  _updateUnReadCnt() async {
    await IMHelper.defaultInstance().requestUnReadCnt();
  }

  _onTap(int position) {
    navigatePushPage(this.context, MessagePage(_sessions[position]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('消息')),
        body: Center(
          child: ListView.builder(
            itemCount: _sessions == null ? 0 : _sessions.length,
            itemBuilder: (context, position) {
              SessionEntry sessionEntry = _sessions[position];
              int unReadCnt = IMHelper.defaultInstance()
                  .getUnreadCntBySessionKey(sessionEntry.sessionKey);

              return Column(children: <Widget>[
                GestureDetector(
                  onTap: () => _onTap(position),
                  child: ListTile(
                    leading: ClipOval(
                      child: FadeInImage(
                        image: NetworkImage(sessionEntry.avatar),
                        placeholder: AssetImage('images/avatar_default.png'),
                      ),
                    ),
                    title: Text(sessionEntry.sessionName,
                        style: Theme.of(context).textTheme.subhead),
                    subtitle: new Text(sessionEntry.lastMsg, maxLines: 1),
                    trailing: unReadCnt > 0
                        ? Container(
                            child: Center(child: Text(unReadCnt.toString(),style: TextStyle(color: Colors.white))),
                            width: 20,
                            decoration: new BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                          )
                        : Icon(
                            Icons.arrow_forward_ios,
                          ),
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
