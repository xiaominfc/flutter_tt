//
// utils.dart
// Copyright (C) 2019 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//

import 'package:flutter/material.dart';

void navigatePage(BuildContext context, Widget widget){
  try {
    Navigator.of(context).pushAndRemoveUntil(new MaterialPageRoute(
            builder: (BuildContext context) => widget), (//跳转页面
            Route route) => route == null);
  } catch (e) {
    print(e);
  }
}


void navigatePushPage(BuildContext context, Widget widget){
  try {
    Navigator.of(context).push(new MaterialPageRoute(
            builder: (BuildContext context) => widget));
  } catch (e) {
    print(e);
  }
}
