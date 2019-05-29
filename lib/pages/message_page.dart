//
// message_page.dart
// Copyright (C) 2019 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/dao.dart';
import '../models/helper.dart';
import 'package:event_bus/event_bus.dart';
import 'package:toast/toast.dart';

class MessagePage extends StatefulWidget {
  final session;
  MessagePage(this.session);

  @override
  createState() => _MessagePageState(this.session);
}

class _MessagePageState extends State<MessagePage> {
  EventBus eventBus = EventBus(sync: true);
  final IMHelper imHelper = IMHelper();
  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController _controller = ScrollController();
  SessionEntry session;
  List<MessageEntry> allMsgs = List();
  StreamSubscription subscription;
  _MessagePageState(this.session);

  void onEvent(event) async {
    if (mounted && event.msg.sessionId == session.sessionId) {
      allMsgs.add(event.msg);
      setState(() {
        
      });
      scrollEnd(10);
    }
  }

  @override
  void initState() {
    super.initState();
    _onRefresh().then((result) {});
    subscription = imHelper.eventBus.on<NewMsgEvent>().listen((event) {
      onEvent(event);
    });
  }

  scrollEnd([animationTime=500]) {
    double scrollValue = _controller.position.maxScrollExtent;
    if (scrollValue < 10) {
      scrollValue = 1000000;
    }

    //_controller.jumpTo(scrollValue);
    _controller.animateTo(scrollValue,
        duration: Duration(milliseconds: animationTime), curve: Curves.easeIn);
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
      if (msgs != null && msgs.length > 0) {
        int size = allMsgs.length;
        allMsgs.insertAll(0, msgs.reversed);
        setState(() {
          if (size == 0) {
            scrollEnd();
          }
        });
      }
    });
    return;
  }

  @override
  void dispose() {
    //_controller.dispose();
    super.dispose();
    subscription.cancel();
  }

  Widget msgItem(MessageEntry msg, UserEntry fromUser) {
    if (imHelper.isSelfId(fromUser.id)) {
      return rightAvatarItem(msg, fromUser);
    }
    return leftAvatarItem(msg, fromUser);
  }

  _avatar(UserEntry fromUser, edge) {
    return Container(
      width: 36,
      margin: edge,
      child: ClipOval(
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
      String url = imHelper.decodeToImage(msg.msgData);
      url = url.substring(10, url.length - 9);
      print("url:$url");
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

  reSendMsg(MessageEntry msg) {
    //还没实现 只是测试
    msg.sendStatus = IMMsgSendStatus.Ok;
    setState(() {});
    //
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
              Row(
                children: <Widget>[
                  msg.sendStatus == IMMsgSendStatus.Sending
                      ? CircularProgressIndicator(
                          strokeWidth: 1.0,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black12),
                        )
                      : (msg.sendStatus == IMMsgSendStatus.Failed
                          ? IconButton(
                              icon: Icon(
                                Icons.error,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                reSendMsg(msg);
                              },
                            )
                          : Center()),
                  _msgContentBuild(msg)
                ],
              )
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
    text = textEditingController.text;
    
    if(text == null || text.length == 0) {
      Toast.show("发送内容不能为空", context, duration: Toast.LENGTH_SHORT, gravity:  Toast.CENTER);
      return;
    }
    MessageEntry messageEntry =
        imHelper.buildTextMsg(text, session.sessionId, session.sessionType);
    messageEntry.sendStatus = IMMsgSendStatus.Sending;
    allMsgs.add(messageEntry);
    setState(() {
      scrollEnd(10);
    });
    textEditingController.clear();
    
    imHelper
        .sendTextMsg(text, session.sessionId, session.sessionType)
        .then((result) {
      setState(() {
        if (result != null) {
          messageEntry.msgId = result.msgId;
          messageEntry.sendStatus = IMMsgSendStatus.Ok;
        } else {
          messageEntry.sendStatus = IMMsgSendStatus.Failed;
        }
      });
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

  _hideBottomLayout() {
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
