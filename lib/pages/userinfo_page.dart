//
// userinfo_page.dart
// Copyright (C) 2020 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//
import 'package:flutter/material.dart';
import '../models/dao.dart';
import './message_page.dart';
import '../models/helper.dart';
import '../utils/utils.dart';



class UserInfoPage extends StatefulWidget {
  final UserEntry user;
  UserInfoPage(this.user);

  createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final IMHelper imHelper = IMHelper();
  void _chatToUser() {
    UserEntry user = widget.user;
    if (imHelper.isSelfId(user.id)) {
    } else {
      String sessionKey =
          user.id.toString() + "_" + IMSeesionType.Person.toString();
      SessionEntry entry = imHelper.getSessionBySessionKey(sessionKey);
      if (entry == null) {
        entry = SessionEntry(user.id, IMSeesionType.Person);
      }
      navigatePushPage(this.context, MessagePage(entry));
    }
  }

  Widget build(BuildContext context) {
    UserEntry userEntry = widget.user;
    return Scaffold(
        appBar: AppBar(title: Text(userEntry.name)),
        body: Column(children: [
          Center(
            child: Container(
                margin: EdgeInsets.only(top: 32),
                width: 64,
                child: ClipOval(
                  child: FadeInImage(
                    image: NetworkImage(userEntry.avatar),
                    placeholder: AssetImage('images/avatar_default.png'),
                  ),
                )),
          ),
          Container(
              padding: EdgeInsets.all(10),
              child:Row(children:[
                Text('昵称:' + userEntry.name)
              ])
              ),
          Container(
              padding: EdgeInsets.all(10),
              child:Row(children:[
                Text('邮箱:' + userEntry.email)
              ])
              ),
          Container(
              padding: EdgeInsets.all(10),
              child:Row(children:[
                Text('电话:' + userEntry.phone)
              ])
              ),
          Container(
              padding: EdgeInsets.all(10),
              child:Row(children:[
                Text('心情:' + userEntry.signInfo)
              ])
              ),
          Container(
              padding: EdgeInsets.all(10),
              child: Material(
                  elevation: 5.0,
                  borderRadius: BorderRadius.circular(30.0),
                  color: Colors.blue,
                  child: MaterialButton(
                      minWidth: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                      onPressed: _chatToUser,
                      child: Text("发消息",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold))))),
        ]));
  }
}
