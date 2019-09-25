//
// message_page.dart
// Copyright (C) 2019 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/dao.dart';
import '../models/helper.dart';
import 'package:event_bus/event_bus.dart';
import 'package:toast/toast.dart';
import '../utils/emoji_utils.dart';
import '../utils/utils.dart';


class _PanelType {
    static const int Normal = 0;
    static const int Emoji = 1;
    static const int Tools = 2;
}


class MessagePage extends StatefulWidget {
  final session;
  MessagePage(this.session);

  @override
  createState() => _MessagePageState();
}


class _MessagePageState extends State<MessagePage> with WidgetsBindingObserver {
  EventBus eventBus = EventBus(sync: true);
  final IMHelper imHelper = IMHelper();
  String chatTitle = "";
  final TextEditingController textEditingController =
      new TextEditingController();
  FocusNode _textFocusNode = FocusNode();
  final ScrollController _controller = ScrollController();
  //SessionEntry session;
  List<MessageEntry> allMsgs = List();
  StreamSubscription subscription;
  bool _showPanel = false;
  int panelType = _PanelType.Normal;
  //_MessagePageState(this.session);

  //EventBus 回调
  void _onEvent(NewMsgEvent event) async {
    SessionEntry session = widget.session;
    if (mounted && event.sessionKey == session.sessionKey) {
      allMsgs.add(event.msg);
      session.lastMsg =
          imHelper.decodeMsgData(event.msg.msgData, event.msg.msgType);
      session.updatedTime = event.msg.time;
      imHelper.sureReadMessage(event.msg);
      setState(() {});
      _waitTimeScrollToEnd(500);
    }
  }

  @override
  void initState() {
    super.initState();
    SessionEntry session = widget.session;
    if (session.sessionType == IMSeesionType.Person) {
      UserEntry userEntry = imHelper.userMap[session.sessionId];
      chatTitle = userEntry.name;
    } else {
      GroupEntry groupEntry = imHelper.groupMap[session.sessionId];
      chatTitle = groupEntry.name;
    }

    WidgetsBinding.instance.addObserver(this);
    _textFocusNode.addListener(() {
      //print("_textFocusNode.hasFocus:" + _textFocusNode.hasFocus.toString());
      if (_textFocusNode.hasFocus) {
        setState(() {
          _showPanel = false;
        });
      } else {}
    });

    _onRefresh().then((result) {
      _waitTimeScrollToEnd();
    });
    imHelper.setShowSession(session);
    subscription = imHelper.eventBus.on<NewMsgEvent>().listen((event) {
      _onEvent(event);
    });
  }

  @override
  void dispose() {
    SessionEntry session = widget.session;
    WidgetsBinding.instance.removeObserver(this);
    subscription.cancel();
    imHelper.resetShowSession(session);
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
      if (_textFocusNode.hasFocus) {
        _waitTimeScrollToEnd(100,300);
      }
    } else {
      //print("KEYBOARD HIDDEN");
      if (_showPanel) {
        setState(() {});
      }
    }
  }


  _waitTimeScrollToEnd([time = 1000, animationTime = 500]) {
      Timer(Duration(milliseconds: time), () {
        if(_controller.position.maxScrollExtent > 0) {
          _scrollToEnd(animationTime);
        }
      });
  }


  //滑动到底部
  _scrollToEnd([animationTime = 500]) async{
    //print("scroll end");
    if(_controller.position.maxScrollExtent == 0) {
      return;
    }

    //String t;

    //List<String> t;
    double scrollValue = _controller.position.maxScrollExtent;
    //print('scroll to $scrollValue');
    _controller.animateTo(scrollValue,
      duration: Duration(milliseconds: animationTime), curve: Curves.easeIn).then((value){
        print("");
          //print('value:' + (_controller.offset).toString() + "  max:" + _controller.position.maxScrollExtent.toString());
          if(_controller.offset < _controller.position.maxScrollExtent) {
            _scrollToEnd(200);
          }
      }
    );
  }

  Future<Null> _onRefresh() async {
    SessionEntry session = widget.session;
    int msgBeginId = 0;
    if (allMsgs.length > 0) {
      msgBeginId = allMsgs[0].msgId - 1;
      if (msgBeginId <= 0) {
        //setState(() {});
        return;
      }
    }
    imHelper
        .loadMessagesByServer(session.sessionId, session.sessionType,
            beginMsgId: msgBeginId)
        .then((msgs) {
      if (msgs != null && msgs.length > 0) {
        int size = allMsgs.length;
        allMsgs.insertAll(0, msgs.reversed);
        setState(() {
          if (size == 0) {
            //_scrollToEnd(0);
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
      return Card(
          child: Container(
              child: Image(
                  image: NetworkImage(url),
                  fit: BoxFit.cover,
                  width: maxWidth,
              )));
    } else if (text.startsWith("[牙牙")) {//动态表情
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
    DateTime date = new DateTime.fromMillisecondsSinceEpoch(msg.time * 1000);
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
              ),
              Text(dateFormat(date,""))
            ],
          ),
          _avatar(fromUser, EdgeInsets.only(left: 8.0, top: 8.0))
        ],
      ),
    );
  }

  Widget leftAvatarItem(MessageEntry msg, UserEntry fromUser) {
    DateTime date = new DateTime.fromMillisecondsSinceEpoch(msg.time * 1000);
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
                _msgContentBuild(msg),
                Text(dateFormat(date,''))
              ],
            ),
          ],
        ));
  }

  //no check
  void _sendText(String text) {

    //BottomNa
    SessionEntry session = widget.session;
    MessageEntry messageEntry =
        imHelper.buildTextMsg(text, session.sessionId, session.sessionType);
    messageEntry.sendStatus = IMMsgSendStatus.Sending;
    messageEntry.time = currentUnixTime();
    allMsgs.add(messageEntry); 
    setState(() {
       //_scrollToEnd();
       _waitTimeScrollToEnd(500);
    });
    
    imHelper
        .sendTextMsg(text, session.sessionId, session.sessionType)
        .then((result) {
      setState(() {
        if (result != null) {
          messageEntry.msgId = result.msgId;
          messageEntry.sendStatus = IMMsgSendStatus.Ok;
          session.lastMsg = result.msgText;
          session.updatedTime = result.time;
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

  Widget _buildEmojiPanel(double maxHeight) {
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
                      EmojiUtil.YAYAMAP.values.elementAt(emojiIndex);
                  //print(yayaEmoji);
                  return Center(
                      child: GestureDetector(
                          onTap: () {
                            _sendText(
                                EmojiUtil.YAYAMAP.keys.elementAt(emojiIndex));
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

  selectImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    return _sendImage(image);
  }

  _sendImage(File file) async{
    var dio = new Dio();
    FormData formData = new FormData.from({
      "file": new UploadFileInfo(new File("/Users/xiaominfc/Pictures/origin_1.png"), "origin_1.png")
    });
    var response = await dio.post("http://msfs.xiaominfc.com/", data: formData);

    if(response.statusCode == 200) {
      Map<String, dynamic> result = jsonDecode(response.data);
      //_sendText("");
    }
  }

  Widget _buildPanel(double maxHeight) {
    if(this.panelType == _PanelType.Emoji) {
        return _buildEmojiPanel(maxHeight);
    }
    return Container(
        height: maxHeight, 
        child: Center(
            child:Row(children: <Widget>[
              Container(
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () {
                    selectImage();
                  },
                  child:Icon(Icons.add_a_photo),
              ),
              ),
              
            ],)
            //child:Text('not implement tools panel!')
            )
        );
  }

 
  _toggleToPanelType(int targetType) {
    if(_showPanel && panelType == targetType) {
      _showPanel = !_showPanel;
    }else if(!_showPanel) {
      _showPanel = !_showPanel;
      panelType = targetType;
    }else {
      panelType = targetType;
    }
    if (_showPanel) {
      if (_isKeyboardOpen) {
        FocusScope.of(context).requestFocus(
            new FocusNode()); //show panel after hide keyboard
        return;
      }
    }
    setState(() {});
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
                        //_showPanel = !_showPanel;
                        _toggleToPanelType(_PanelType.Tools);
                      },
                    ),
                  ),
                  new Container(
                    margin: const EdgeInsets.only(left: 2, right: 2),
                    child: new IconButton(
                      padding: EdgeInsets.zero,
                      icon: new Icon(Icons.insert_emoticon),
                      onPressed: () {
                        _toggleToPanelType(_PanelType.Emoji);
                        //_showPanel = !_showPanel;
                        
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
                        ? _buildPanel(200)
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
        appBar: AppBar(title: Text(chatTitle)),
        body: SafeArea(
          child: Container(
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
          ),
        ));
  }
}
