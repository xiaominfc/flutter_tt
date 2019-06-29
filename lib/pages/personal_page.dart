//
// personal_page.dart
// Copyright (C) 2019 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//

import 'package:flutter/material.dart';
import 'package:flutter_tt/models/dao.dart';
import 'package:flutter_tt/models/helper.dart';
import 'package:flutter_tt/utils/utils.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';


class PersonalPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {

  _loginOut() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("diable_autoLogin", true);
    await IMHelper.defaultInstance().loginOut();
    navigatePage(context, new LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    UserEntry userEntry = IMHelper.defaultInstance().loginUserEntry;
    return Scaffold(
      appBar: AppBar(title: Text("我的")),
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 128,
                padding: EdgeInsets.all(32),
                child: ClipOval(
                  child: FadeInImage(
                    image: NetworkImage(userEntry.avatar),
                    placeholder: AssetImage('images/avatar_default.png'),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    userEntry.name??"",
                    style: Theme.of(context).textTheme.headline
                    ),
                  Text(userEntry.signInfo??"",
                    style: Theme.of(context).textTheme.subtitle
                  )
                  ],
              )
            ],
          ),
          SizedBox(
            height: 120,
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
              onPressed: _loginOut,
              child: Text("退出登录",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          ),
        ],
      ),
    );
  }
}
