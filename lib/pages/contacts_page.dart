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

class SelfToolsBar extends StatelessWidget {
  final TextStyle textStyle = TextStyle(fontSize: 16, color: Colors.white);
  double radius = 16.0;
  List<Widget> widgets = List<Widget>();

  Radius defaultRadius;

  SelfToolsBar(
      {List<String> titles,
      int selectedIndex = 0,
      Function(int index) onSelected}) {
    EdgeInsets padding =
        EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5);
    defaultRadius = Radius.elliptical(radius, radius);
    if (titles != null) {
      for (int index = 0; index < titles.length; index++) {
        String title = titles[index];
        Color bgColor =
            selectedIndex == index ? Colors.blue : Color(0xFF9E9E9E);
        Text titleText = Text(title, style: textStyle);
        BorderRadius borderRadius;
        if (index == 0) {
          borderRadius = new BorderRadius.horizontal(
              left: Radius.elliptical(radius, radius));
        } else if (index == titles.length - 1) {
          borderRadius = new BorderRadius.horizontal(
              right: Radius.elliptical(radius, radius));
        }
        widgets.add(new GestureDetector(
          child: Container(
              height: radius * 2,
              padding: padding,
              child: Center(
                child: titleText,
              ),
              decoration:
                  BoxDecoration(color: bgColor, borderRadius: borderRadius)),
          onTap: () {
            if (index != selectedIndex) {
              onSelected(index);
            }
          },
        ));

        if (index != titles.length - 1) {
          widgets.add(Container(
            width: 0.5,
            height: radius * 2,
            decoration: new BoxDecoration(
              color: Colors.white,
            ),
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      decoration: new BoxDecoration(
        border: new Border.all(color: Colors.white, width: 0.5),
        borderRadius: new BorderRadius.horizontal(
            left: defaultRadius, right: defaultRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: widgets,
      ),
    ));
  }
}

class ContactsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List users;
  List groups;
  final IMHelper imHelper = IMHelper();
  UserDao userDao = new UserDao();
  GroupDao groupDao = new GroupDao();
  int selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    onSelected(selectedIndex);
  }

  onSelected(int index) {
    selectedIndex = index;
    if (selectedIndex == 0 && (users == null || users.length == 0)) {
      userDao
          .queryAllWith(" id != " + imHelper.loginUserId().toString())
          .then((list) {
        setState(() {
          users = list;
        });
      });
      return;
    } else if (selectedIndex == 1 && (groups == null || groups.length == 0)) {
      groupDao.queryAll().then((list) {
        setState(() {
          groups = list;
        });
      });
      return;
    }
    setState(() {});
  }

  Widget cantactCard(String title, String avatar, {String subtitle = ""}) {
    return Card(
      child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(right: 16.0),
                width: 48,
                height: 48,
                child: ClipOval(
                  child: FadeInImage(
                    image: NetworkImage(avatar),
                    placeholder: AssetImage('images/avatar_default.png'),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.subtitle),
                  Text(subtitle, style: Theme.of(context).textTheme.subhead),
                ],
              )
            ],
          )),
    );
  }

  Widget groupListView() {
    return ListView.builder(
      itemCount: groups == null ? 0 : groups.length,
      itemBuilder: (context, position) {
        if (position < groups.length) {
          GroupEntry group = groups[position];
          return new GestureDetector(
            onTap: () {
              _handleGroupChat(group);
            },
            child: cantactCard(group.name, group.avatar),
          );
        }
        return null;
      },
    );
  }

  Widget userListView() {
    return ListView.builder(
      itemCount: users == null ? 0 : users.length,
      itemBuilder: (context, position) {
        if (position < users.length) {
          UserEntry user = users[position];
          return new GestureDetector(
            onTap: () {
              _handleUserChat(user);
            },
            child: cantactCard(user.name, user.avatar, subtitle: user.signInfo),
          );
        }
        return null;
      },
    );
  }

  _handleGroupChat(GroupEntry group) {
    String sessionKey =
        group.id.toString() + "_" + IMSeesionType.Group.toString();
    SessionEntry entry = imHelper.getSessionBySessionKey(sessionKey);
    if (entry == null) {
      entry = SessionEntry(group.id, IMSeesionType.Group);
    }
    navigatePushPage(this.context, MessagePage(entry));
  }

  _handleUserChat(UserEntry user) {
    if (imHelper.isSelfId(user.id)) {
    } else {
      String sessionKey =
          user.id.toString() + "_" + IMSeesionType.Person.toString();
      SessionEntry entry = imHelper.getSessionBySessionKey(sessionKey);
      if (entry == null) {
        entry = SessionEntry(user.id, IMSeesionType.Person);
        //entry.sessionType = IMSeesionType.Person;
      }
      navigatePushPage(this.context, MessagePage(entry));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //appBar: AppBar(title: const Text('联系人')),
        appBar: AppBar(
            title: SelfToolsBar(
          titles: ["好友", "群组"],
          selectedIndex: selectedIndex,
          onSelected: (index) {
            onSelected(index);
          },
        )),
        body: Center(
          child: selectedIndex == 0 ? userListView() : groupListView(),
        ));
  }
}
