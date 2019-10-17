//
// preview.dart
// Copyright (C) 2019 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';

class PreviewPage extends StatefulWidget {

  final String url;

  PreviewPage(this.url);

  @override
  createState() => _PreviewPageState();
}


class _PreviewPageState extends State<PreviewPage> {
  @override
  initState(){
    super.initState();
  }
  
  @override
  build(BuildContext context) {
    print("show url:" + widget.url);
    var url = widget.url;
    ImageProvider  imageProvider = null;
    if(url.startsWith("http")) {
      imageProvider = NetworkImage(url);
    }else {
      imageProvider = FileImage(File(url));
    }
    return  
        GestureDetector(
        onTap:(){
          Navigator.pop(context);
        },
        child:Container(
                  color:Colors.black,
                  child:Stack(
                      children:<Widget>[
                        Center(child:CircularProgressIndicator()),
                        Center(child:Image(image:imageProvider))
                      ]
                  )
              )
    );
  }
} 
