//
// message_page.dart
// Copyright (C) 2019 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//

import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/dao.dart';
import '../models/helper.dart';

class MessagePage extends StatefulWidget {
  final session;
  MessagePage(this.session);

  @override
  createState() => _MessagePageState(this.session);
}

class _MessagePageState extends State<MessagePage> {
  final IMHelper imHelper = IMHelper();
  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController _controller = ScrollController();
  SessionEntry session;
  List<MessageEntry> allMsgs = List();

  _MessagePageState(this.session);

  @override
  void initState() {
    super.initState();
    _onRefresh().then((result) {});
  }

  scrollEnd() {
    print("=================scroll to bottom:" +
        _controller.position.maxScrollExtent.toString());
    _controller.animateTo(_controller.position.maxScrollExtent + 1000000,
        duration: Duration(milliseconds: 500), curve: Curves.easeIn);
  }

  Future<Null> _onRefresh() async {
    int msgBeginId = 0;
    if (allMsgs.length > 0) {
      msgBeginId = allMsgs[0].msgId;
    }
    imHelper
        .loadMessagesByServer(this.session.sessionId, this.session.sessionType,
            beginMsgId: msgBeginId)
        .then((msgs) {
      int size = allMsgs.length;
      allMsgs.insertAll(0, msgs.reversed);
      setState(() {
        if (size == 0) {
          scrollEnd();
        }
      });
    });
    return;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget msgItem(MessageEntry msg, UserEntry fromUser) {
    if (imHelper.isSelfId(fromUser.id)) {
      return rightAvatarItem(msg, fromUser);
    }
    return leftAvatarItem(msg, fromUser);
  }

  _avatar(UserEntry fromUser, edge) {
    return Container(
      margin: edge,
      child: CircleAvatar(
        child: FadeInImage(
          image: NetworkImage(fromUser.avatar),
          placeholder: AssetImage('images/avatar_default.png'),
        ),
      ),
    );
  }

  _msgContentBuild(MessageEntry msg) {
    double maxWidth = MediaQuery.of(context).size.width * 0.7;
    var text = imHelper.decodeMsgData(msg.msgData, msg.msgType);

    if (text == '[图片]') {
      String url = ascii.decode(msg.msgData);
      url = url.substring(10, url.length - 9);
      return Card(
          child: Container(
              child: Image(
        image: NetworkImage(url),
        fit: BoxFit.cover,
        width: maxWidth,
      )));
    }
    return Card(
        child: Container(
            padding: EdgeInsets.all(10),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Text(text,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.subhead),
            )));
  }

  Widget rightAvatarItem(MessageEntry msg, UserEntry fromUser) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(fromUser.name, style: Theme.of(context).textTheme.subhead),
              _msgContentBuild(msg)
            ],
          ),
          _avatar(fromUser, EdgeInsets.only(left: 8.0, top: 8.0))
        ],
      ),
    );
  }

  Widget leftAvatarItem(MessageEntry msg, UserEntry fromUser) {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _avatar(fromUser, EdgeInsets.only(right: 8.0, top: 8.0)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(fromUser.name, style: Theme.of(context).textTheme.subhead),
                _msgContentBuild(msg)
              ],
            ),
          ],
        ));
  }

  void _handleSubmit(String text) {
    imHelper
        .sendTextMsg(text, session.sessionId, session.sessionType)
        .then((result) {
      print(result);
      textEditingController.clear();
      if (result != null) {
        allMsgs.add(result);
        _controller.animateTo(_controller.position.maxScrollExtent,
            duration: Duration(milliseconds: 1000), curve: Curves.easeOut);
        setState(() {
          scrollEnd();
          //_controller.jumpTo(100000);
        });
      }
    });
  }

  Widget _textComposerWidget() {
    return new IconTheme(
      data: new IconThemeData(color: Colors.blue),
      child: new Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        child: new Row(
          children: <Widget>[
            new Flexible(
              child: new TextField(
                decoration: new InputDecoration.collapsed(hintText: "输入消息"),
                controller: textEditingController,
                onSubmitted: _handleSubmit,
              ),
            ),
            new Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: () => _handleSubmit(textEditingController.text),
              ),
            )
          ],
        ),
      ),
    );
  }

  _hideBottomLayout(){
    FocusScope.of(context).requestFocus(new FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(session.sessionName)),
        body: Container(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: Column(children: <Widget>[
              Flexible(
                  child: GestureDetector(
                onTap: _hideBottomLayout,
                child: ListView.builder(
                  controller: _controller,
                  itemCount: allMsgs == null ? 0 : allMsgs.length,
                  itemBuilder: (context, position) {
                    MessageEntry msg = allMsgs[position];
                    UserEntry fromUser =
                        IMHelper.defaultInstance().userMap[msg.fromId];
                    return msgItem(msg, fromUser);
                  },
                ),
              )),
              Divider(
                height: 1.0,
              ),
              Container(
                decoration: new BoxDecoration(
                  color: Theme.of(context).cardColor,
                ),
                child: _textComposerWidget(),
              )
            ]),
          ),
        ));
  }
}
