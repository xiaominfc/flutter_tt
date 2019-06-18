//
// contacts_page.dart
// Copyright (C) 2019 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//

import 'package:flutter/material.dart';
import '../models/dao.dart';
import '../models/helper.dart';
import './message_page.dart';
import '../utils/utils.dart';

class ContactsPage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return _ContactsPageState();
  }
}

class _ContactsPageState extends State<ContactsPage> {
  List users;
  final IMHelper imHelper = IMHelper();
  UserDao userDao = new UserDao();
  @override
  void initState() {
    super.initState();
    userDao.queryAllWith(" id != " + imHelper.loginUserId().toString() ).then((list) {
      setState(() {
        print(list);
        users = list;
      });
    });
  }


  _handleUserChat(UserEntry user) {
    if(imHelper.isSelfId(user.id)) {
      
    }else {
      SessionEntry entry = SessionEntry(user.id,IMSeesionType.Person);
      entry.avatar = user.avatar;
      //entry.sessionId = user.id;
      entry.sessionName = user.name;
      //entry.sessionType = IMSeesionType.Person;
      navigatePushPage(this.context, MessagePage(entry));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('联系人')),
        body: Center(
          child: ListView.builder(
            itemCount: users == null ? 0 : users.length,
            itemBuilder: (context, position) {
              if (position < users.length) {
                UserEntry user = users[position];
                return new GestureDetector(
                  onTap: (){
                    _handleUserChat(user);
                  },
                  child: Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: new Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Container(
                              margin: const EdgeInsets.only(right: 16.0),
                              width: 36,
                              child: ClipOval(
                                child: FadeInImage(
                                  image: NetworkImage(user.avatar),
                                  placeholder:
                                      AssetImage('images/avatar_default.png'),
                                ),
                              ),
                            ),
                            new Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                new Text(user.name,
                                    style: Theme.of(context).textTheme.subtitle),
                                new Text(user.signInfo,
                                    style: Theme.of(context).textTheme.subhead),
                              ],
                            )
                          ],
                        )),
                  ),
                );
              }
              return null;
            },
          ),
        ));
  }
}
