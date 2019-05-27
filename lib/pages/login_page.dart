//
// login_page.dart
// Copyright (C) 2019 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//

import 'package:flutter/material.dart';
import '../utils/utils.dart';
import 'home_page.dart';
import '../teamtalk_dart_lib/src/client.dart';
import '../models/helper.dart';

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  EdgeInsets textFieldPadding = EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 15.0);
  OutlineInputBorder textFieldBorder =
      OutlineInputBorder(borderRadius: BorderRadius.circular(10.0));

  TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0);

  bool logining = false;

  final usernameTextFieldController = TextEditingController(text: "xiaominfc");
  final passwordTextFieldController = TextEditingController(text: "123456");

  showHome() {
    navigatePage(context, new HomePage());
  }

  loginFailed() {
    setState(() {
      logining = false;
    });
  }

  doLogin() {
    if (logining) {
      return;
    }

    setState(() {
      logining = true;
    });
    var username = usernameTextFieldController.text;
    var password = passwordTextFieldController.text;
    var imClient = new IMClient()
        .init(username, password, "http://im.xiaominfc.com:8080/msg_server");
        //.init(
        //    username, password, "http://im.jingnongfucang.cn:8080/msg_server");
    imClient.requesetMsgSever().then((serverInfo) {
      if (serverInfo == null) {
        loginFailed();
        return;
      }
      imClient
          .doLogin(serverInfo['priorIP'], int.parse(serverInfo['port']))
          .then((result) {
        if (result) {
          IMHelper.defaultInstance().initData().then((result){
            showHome();
          });
        } else {
          print("login failed!");
          loginFailed();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final passwordTextField = TextField(
      controller: passwordTextFieldController,
      decoration: InputDecoration(
        contentPadding: textFieldPadding,
        hintText: "密码",
        border: textFieldBorder,
      ),
      obscureText: true,
      style: style,
    );
    final usernameTextField = TextField(
      controller: usernameTextFieldController,
      decoration: InputDecoration(
        contentPadding: textFieldPadding,
        hintText: "账号",
        border: textFieldBorder,
      ),
      style: style,
    );

    final loginButon = Material(
      elevation: 5.0,
      borderRadius: BorderRadius.circular(30.0),
      color: Colors.blue,
      child: MaterialButton(
        minWidth: MediaQuery.of(context).size.width,
        padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
        onPressed: () {
          doLogin();
        },
        child: Text("登录",
            textAlign: TextAlign.center,
            style: style.copyWith(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );

    var center = Center(
        child: Padding(
      padding: const EdgeInsets.fromLTRB(30, 60, 30, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        //mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          usernameTextField,
          SizedBox(height: 10.0),
          passwordTextField,
          SizedBox(height: 10.0),
          loginButon
        ],
      ),
    ));
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Login"),
      ),
      body: Stack(
        children: <Widget>[
          center,
          Center(
              child: logining
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black12),
                    )
                  : null),
        ],
      ),
    );
  }
}
