//
// contacts_page.dart
// Copyright (C) 2019 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//

import 'package:flutter/material.dart';
import 'package:flutter_tt/models/dao.dart';

class ContactsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ContactsPageState();
  }
}

class _ContactsPageState extends State<ContactsPage> {
  List users;

  UserDao userDao = new UserDao();
  @override
  void initState() {
    super.initState();
    userDao.queryAll().then((list) {
      setState(() {
        print(list);
        users = list;
      });
    });
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
                return Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: new Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          new Container(
                            margin: const EdgeInsets.only(right: 16.0),
                            child: new CircleAvatar(
                              child: FadeInImage(
                                image: NetworkImage(user.avatar),
                                placeholder:
                                    AssetImage('images/avatar_default.png'),
                              ),
                            ),
                          ),
                          new Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              new Text(user.name,
                                  style: Theme.of(context).textTheme.subhead),
                            ],
                          )
                        ],
                      )),
                );
              }
              return null;
            },
          ),
        ));
  }
}
