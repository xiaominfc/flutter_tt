//
// register_page.dart
// Copyright (C) 2019 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//


import 'package:flutter/material.dart';
import 'home_page.dart';
import '../utils/utils.dart';
import '../models/helper.dart';
import 'package:dio/dio.dart';
import 'package:dio/dio.dart';
import '../teamtalk_dart_lib/src/client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';

class RegisterPage extends StatefulWidget {
  
  @override
  createState()=>_RegisterPageState();
}



class RegisterUser {
  RegisterUser();
  String name;
  String password;
  String nick;
  int sex = 0;

  toJson()=> {
    'name':name,
    'nick':nick,
    'password':password,
    'sex':sex
  };
}

class _RegisterPageState extends State<RegisterPage> {

  final RegisterUser rUser = RegisterUser();
  final _formKey = GlobalKey<FormState>();
  
  _postNewUser(String baseUrl) async{
    var dio = Dio();
    var response = await dio.post(baseUrl + "/register", data:rUser.toJson());
    if (response.statusCode == 200) {
      print(response.data);
      if(response.data['status'] == 'ok') {
        return null;
      }
      return response.data['msg'];
    }
    return "";
  }

  _doReg() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var loginServerUrl = prefs.getString("login_server_url");
    if(loginServerUrl == null) {
      loginServerUrl = IMHelper.DEFAULTLOGINSERVERURL;
    }
    var imClient = new IMClient()
        .init(rUser.name, rUser.password, loginServerUrl);
    imClient.requesetMsgSever().then((serverInfo) {
      print(serverInfo);
      if (serverInfo == null) {
        return;
      }
      _postNewUser(serverInfo['baseUrl']).then((var result){
      if(result == null) {
        imClient
            .doLogin(serverInfo['priorIP'], int.parse(serverInfo['port']))
            .then((loginResult){
              if (loginResult.result) {
                prefs.setString('login_username', rUser.name);
                prefs.setString('login_password', rUser.password);
                prefs.setBool("diable_autoLogin",false);
                IMHelper.defaultInstance().initData().then((result){
                  _showHome();
                });
              } else {
                print("login failed!");
              }
            });

      }else {
        Toast.show(result, context,gravity: Toast.CENTER); 
      }
      });

    });

  }

  _showHome() {
    navigatePage(context, new HomePage());
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:AppBar(
            title:Text("注册"),
        ),
        body:Form(
            key:_formKey,
            child:Padding(
                padding:EdgeInsets.all(20),
                child:Column(
                    children:<Widget>[
                      TextFormField(
                          decoration: InputDecoration(
                              labelText:'账号'
                          ),
                          onSaved:(String value){
                            rUser.name = value;
                          },
                          validator:(value) {
                            if (value.isEmpty) {
                              return "输入账号";
                            }
                            return null;
                          }
                      ),
                      TextFormField(
                          decoration: InputDecoration(
                              labelText:'昵称'
                          ),
                          onSaved:(String value){
                            rUser.nick = value;

                          },
                          validator:(value) {
                            if (value.isEmpty) {
                              return "输入昵称";
                            }
                            return null;
                          }
                      ),
                      TextFormField(
                          decoration: InputDecoration(
                              labelText:'密码'
                          ),
                          onSaved:(String value){
                            rUser.password = value;

                          },
                          validator:(value) {
                            if (value.isEmpty) {
                              return "输入密码";
                            }
                            return null;
                          }
                      ),

                      Row(children:<Widget>[
                        Text("女"),
                        Radio(value:0,groupValue:rUser.sex,onChanged:(int value){
                          setState((){
                            rUser.sex = 0;
                          });
                        }),
                        Text("男"),
                        Radio(value:1,groupValue:rUser.sex,onChanged:(int value){
                          setState((){
                            rUser.sex = 1;
                          });
                        }),
                      ]),
                      Divider(height:20),
                      Material(
                          elevation:5.0,
                          borderRadius: BorderRadius.circular(30.0),
                          color: Colors.blue,
                          child:MaterialButton(
                              padding:EdgeInsets.fromLTRB(20,15,20,15),
                              child:Text("提交",
                                  textAlign:TextAlign.center),
                              onPressed:(){
                                if (_formKey.currentState.validate()) {
                                  _formKey.currentState.save();
                                  //print(rUser.name);
                                  //print(rUser.toJson());
                                  _doReg();
                                }
                              }
                          )
                      )

                    ]
                )
            )
            )
    );
  }

}
