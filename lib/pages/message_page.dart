//
// message_page.dart
// Copyright (C) 2019 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/dao.dart';
import '../models/helper.dart';
import 'package:event_bus/event_bus.dart';
import 'package:toast/toast.dart';
import '../utils/emoji_utils.dart';

class MessagePage extends StatefulWidget {
  final session;
  MessagePage(this.session);

  @override
  createState() => _MessagePageState(this.session);
}

class _MessagePageState extends State<MessagePage> with WidgetsBindingObserver {
  EventBus eventBus = EventBus(sync: true);
  final IMHelper imHelper = IMHelper();
  final TextEditingController textEditingController =
      new TextEditingController();
  FocusNode _textFocusNode = FocusNode();
  final ScrollController _controller = ScrollController();
  SessionEntry session;
  List<MessageEntry> allMsgs = List();
  StreamSubscription subscription;
  bool _showPanel = false;
  _MessagePageState(this.session);
  //EventBus 回调
  void _onEvent(event) async {
    if (mounted && event.msg.sessionId == session.sessionId) {
      allMsgs.add(event.msg);
      imHelper.sureReadMessage(event.msg);
      setState(() {});
      _scrollToEnd(10);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _textFocusNode.addListener(() {
      //print("_textFocusNode.hasFocus:" + _textFocusNode.hasFocus.toString());
      if (_textFocusNode.hasFocus) {
        setState(() {
          _showPanel = false;
        });

        //_scrollToEnd(10);
      } else {}
      //print(MediaQuery.of(context).viewInsets.bottom);
    });

    _onRefresh().then((result) {});
    subscription = imHelper.eventBus.on<NewMsgEvent>().listen((event) {
      _onEvent(event);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    subscription.cancel();
    super.dispose();
  }

  var _isKeyboardOpen = false;
  @override
  void didChangeMetrics() {
    final value = WidgetsBinding.instance.window.viewInsets.bottom;
    if (value <= 0) {
      if (_isKeyboardOpen) {
        _onKeyboardChanged(false);
      }
      _isKeyboardOpen = false;
    } else {
      _isKeyboardOpen = true;
      _onKeyboardChanged(true);
    }
  }

  _onKeyboardChanged(bool isVisible) {
    if (isVisible) {
      //print("KEYBOARD VISIBLE");
      if (_textFocusNode.hasFocus) {
        _controller.jumpTo(_controller.position.maxScrollExtent + 100);
      }
    } else {
      //print("KEYBOARD HIDDEN");
      if (_showPanel) {
        setState(() {});
      }
    }
  }

  //滑动到底部
  _scrollToEnd([animationTime = 500]) {
    double scrollValue = _controller.position.maxScrollExtent + 100;
    if (scrollValue < 10) {
      scrollValue = 1000000;
    }

    //print("scroll to :$scrollValue");

    if (animationTime == 0) {
      _controller.jumpTo(scrollValue);
      return;
    }

    _controller.animateTo(scrollValue,
        duration: Duration(milliseconds: animationTime), curve: Curves.easeIn);
  }

  Future<Null> _onRefresh() async {
    int msgBeginId = 0;
    if (allMsgs.length > 0) {
      msgBeginId = allMsgs[0].msgId - 1;
      if (msgBeginId <= 0) {
        setState(() {});
      }
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
            _scrollToEnd(0);
            if (allMsgs.length > 0) {
              MessageEntry last = allMsgs.last;
              imHelper.clearUnReadCntBySessionKey(session.sessionKey);
              imHelper.sureReadMessage(last);
            }
          }
        });
      }
    });
    return;
  }

  //构建单个消息体
  Widget _buildMsgItem(MessageEntry msg, UserEntry fromUser) {
    if (imHelper.isSelfId(fromUser.id)) {
      return rightAvatarItem(msg, fromUser);
    }
    return leftAvatarItem(msg, fromUser);
  }

  //生成 头像

  Widget _avatar(UserEntry fromUser, edge) {
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

  // 构建内容显示

  Widget _msgContentBuild(MessageEntry msg) {
    double maxWidth = MediaQuery.of(context).size.width * 0.7;
    String text = imHelper.decodeMsgData(msg.msgData, msg.msgType);

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
    } else if (text.startsWith("[牙牙")) {
      String yayaEmoji = EmojiUtil.yaya(text);
      if (yayaEmoji != null) {
        return Card(
            child: Container(
                width: 128,
                child: Image(
                  image: AssetImage(yayaEmoji),
                  fit: BoxFit.cover,
                  width: maxWidth,
                )));
      }
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

  //重发消息
  _reSendMsg(MessageEntry msg) {
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
                                _reSendMsg(msg);
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

  //no check
  void _sendText(String text){
    MessageEntry messageEntry =
        imHelper.buildTextMsg(text, session.sessionId, session.sessionType);
    messageEntry.sendStatus = IMMsgSendStatus.Sending;
    allMsgs.add(messageEntry);
    setState(() {
      _scrollToEnd(0);
    });
    

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

  void _handleSubmit(String text) {
    text = textEditingController.text;
    FocusScope.of(context).requestFocus(_textFocusNode);
    if (text == null || text.length == 0) {
      Toast.show("发送内容不能为空", context,
          duration: Toast.LENGTH_SHORT, gravity: Toast.CENTER);
      return;
    }
    textEditingController.clear();
    _sendText(text);
    
  }

  Widget _buildEmojiPannel(double maxHeight) {
    int count = EmojiUtil.YAYAMAP.length;
    int pageItemsCount = 8;
    int pageCount = count ~/ pageItemsCount;
    if (count % pageItemsCount > 0) {
      pageCount = pageCount + 1;
    }

    return Container(
        height: maxHeight,
        child: Center(
          child: PageView.builder(
            itemBuilder: (context, position) {
              int emojiCount = pageItemsCount;
              if ((position + 1) * emojiCount > count) {
                emojiCount = count - position * emojiCount;
              }
              //print(emojiCount);
              return Container(
                  child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, gPosition) {
                  int emojiIndex = gPosition + position * pageItemsCount;
                  String yayaEmoji = EmojiUtil.YAYABASEPATH +
                      EmojiUtil.YAYAMAP.values
                          .elementAt(emojiIndex);
                  //print(yayaEmoji);
                  return Center(
                      child: GestureDetector(
                          onTap: () {
                            _sendText(EmojiUtil.YAYAMAP.keys.elementAt(emojiIndex));
                          },
                          child: Image(
                            image: AssetImage(yayaEmoji),
                            fit: BoxFit.cover,
                          )));
                },
                itemCount: emojiCount,
              ));
            },
            itemCount: pageCount,
          ),
        ));
  }

  Widget _textComposerWidget() {
    return new IconTheme(
      data: new IconThemeData(color: Colors.blue),
      child: new Container(
          decoration: Theme.of(context).platform == TargetPlatform.iOS
              ? new BoxDecoration(
                  border:
                      new Border(top: new BorderSide(color: Colors.grey[200])))
              : null,
          margin: EdgeInsets.only(left: 8, right: 8),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  new Flexible(
                    child: new TextFormField(
                      decoration:
                          new InputDecoration.collapsed(hintText: "输入消息"),
                      controller: textEditingController,
                      focusNode: _textFocusNode,
                      textInputAction: TextInputAction.send,
                      onFieldSubmitted: _handleSubmit,
                    ),
                  ),
                  new Container(
                    margin: const EdgeInsets.only(left: 2, right: 2),
                    child: new IconButton(
                      padding: EdgeInsets.zero,
                      icon: new Icon(Icons.add_circle_outline),
                      onPressed: () {
                        _showPanel = !_showPanel;
                        if (_showPanel) {
                          if (_isKeyboardOpen) {
                            FocusScope.of(context).requestFocus(
                                new FocusNode()); //show panel after hide keyboard
                            return;
                          }
                        }
                        setState(() {});
                      },
                    ),
                  ),
                  new Container(
                    margin: const EdgeInsets.only(left: 2, right: 2),
                    child: new IconButton(
                      padding: EdgeInsets.zero,
                      icon: new Icon(Icons.insert_emoticon),
                      onPressed: () {
                        _showPanel = !_showPanel;
                        if (_showPanel) {
                          if (_isKeyboardOpen) {
                            FocusScope.of(context).requestFocus(
                                new FocusNode()); //show panel after hide keyboard
                            return;
                          }
                        }
                        setState(() {});
                      },
                    ),
                  )
                ],
              ),
              Container(
                height: _showPanel ? 202 : 0,
                child: Column(
                  children: <Widget>[
                    Divider(
                      height: 1.0,
                    ),
                    _showPanel
                        ? _buildEmojiPannel(200)
                        : Divider(
                            height: 0.0,
                          ),
                  ],
                ),
              )
            ],
          )),
    );
  }

  //hide panel and keyboard
  _hideBottomLayout() {
    if (_showPanel) {
      setState(() {
        _showPanel = !_showPanel;
      });
    }
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
                    return _buildMsgItem(msg, fromUser);
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
