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
import 'package:toast/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const DEFAULTLOGINSERVERURL = 'http://im.xiaominfc.com:8080/msg_server';
  

  @override
  initState(){
    super.initState();
    _initLastUser();
  }

  _initLastUser() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var name = prefs.getString("login_username");
    var password = prefs.getString("login_password");
    var diableAutoLogin =  prefs.getBool("diable_autoLogin");
    if(diableAutoLogin == null) {
      diableAutoLogin = false;
    }
    if(name != null && password != null) {
      usernameTextFieldController.text = name;
      passwordTextFieldController.text = password;
      setState(() {
        
      });
      if(!diableAutoLogin) {
        _doLogin();
      }
    }
  }

  _showHome() {
    navigatePage(context, new HomePage());
  }

  _loginFailed({String msg}) {
    if(msg!=null) {
      Toast.show(msg, context,gravity: Toast.CENTER);
    }
    setState(() {
      logining = false;
    });
  }

  _doLogin()async{
    if (logining) {
      return;
    }

    setState(() {
      logining = true;
    });
    var username = usernameTextFieldController.text;
    var password = passwordTextFieldController.text;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var loginServerUrl = prefs.getString("login_server_url");
    if(loginServerUrl == null) {
      loginServerUrl = DEFAULTLOGINSERVERURL;
    }
    var imClient = new IMClient()
        .init(username, password, loginServerUrl);
    imClient.requesetMsgSever().then((serverInfo) {
      if (serverInfo == null) {
        _loginFailed(msg:'获取msg_server失败:' + loginServerUrl);
        return;
      }
      imClient
          .doLogin(serverInfo['priorIP'], int.parse(serverInfo['port']))
          .then((loginResult){
        if (loginResult.result) {
          prefs.setString('login_username', username);
          prefs.setString('login_password', password);
          prefs.setBool("diable_autoLogin",false);
          IMHelper.defaultInstance().initData().then((result){
            _showHome();
          });
        } else {
          print("login failed!");
          _loginFailed();
        }
      });
    });
  }


  Future<String> _asyncInputDialog(BuildContext context) async {
  
  final textFieldController = TextEditingController(text: DEFAULTLOGINSERVERURL);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var loginServerUrl = prefs.getString("login_server_url");
  if(loginServerUrl == null) {
    loginServerUrl = DEFAULTLOGINSERVERURL;
  }
  textFieldController.text = loginServerUrl;
  return showDialog<String>(
    context: context,
    barrierDismissible: false, // dialog is dismissible with a tap on the barrier
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('login_server地址编辑:'),
        content: new Row(
          children: <Widget>[
            new Expanded(
                child: new TextField(
                  controller: textFieldController,
              autofocus: true,
              decoration: new InputDecoration(
                  labelText: 'url', hintText: DEFAULTLOGINSERVERURL),
            ))
          ],
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('确认'),
            onPressed: () {
              var text = textFieldController.text;
              if(text.length > 0 && text.startsWith('http')) {
                prefs.setString('login_server_url',text);
                Navigator.of(context).pop(text);
              }else {
                Toast.show('地址无效',  context, gravity:Toast.CENTER);
              }
            },
          ),
        ],
      );
    },
  );
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
        onPressed: _doLogin,
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
        title: Text("Login"),
        actions: <Widget>[
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                _asyncInputDialog(context);
              },
            ),],
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
