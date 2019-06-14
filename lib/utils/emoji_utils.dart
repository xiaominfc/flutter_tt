//
// emoji_utils.dart
// Copyright (C) 2019 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//

/*
<item>[牙牙撒花]</item>
<item>[牙牙尴尬]</item>
<item>[牙牙大笑]</item>
<item>[牙牙组团]</item>
<item>[牙牙凄凉]</item>
<item>[牙牙吐血]</item>
<item>[牙牙花痴]</item>
<item>[牙牙疑问]</item>
<item>[牙牙爱心]</item>
<item>[牙牙害羞]</item>
<item>[牙牙牙买碟]</item>
<item>[牙牙亲一下]</item>
<item>[牙牙大哭]</item>
<item>[牙牙愤怒]</item>
<item>[牙牙挖鼻屎]</item>
<item>[牙牙嘻嘻]</item>
<item>[牙牙漂漂]</item>
<item>[牙牙冰冻]</item>
<item>[牙牙傲娇]</item>
*/


class EmojiUtil {

  static const String YAYABASEPATH = "images/yaya/";
  static const Map<String, String> YAYAMAP = {
    "[牙牙撒花]": "tt_yaya_e1.gif",
    "[牙牙尴尬]": "tt_yaya_e2.gif",
    "[牙牙大笑]": "tt_yaya_e3.gif",
    "[牙牙组团]": "tt_yaya_e4.gif",
    "[牙牙凄凉]": "tt_yaya_e5.gif",
    "[牙牙吐血]": "tt_yaya_e6.gif",
    "[牙牙花痴]": "tt_yaya_e7.gif",
    "[牙牙疑问]": "tt_yaya_e8.gif",
    "[牙牙爱心]": "tt_yaya_e9.gif",
    "[牙牙害羞]": "tt_yaya_e10.gif",
    "[牙牙牙买碟]": "tt_yaya_e11.gif",
    "[牙牙亲一下]": "tt_yaya_e12.gif",
    "[牙牙大哭]": "tt_yaya_e13.gif",
    "[牙牙愤怒]": "tt_yaya_e14.gif",
    "[牙牙挖鼻屎]": "tt_yaya_e15.gif",
    "[牙牙嘻嘻]": "tt_yaya_e16.gif",
    "[牙牙漂漂]": "tt_yaya_e17.gif",
    "[牙牙冰冻]": "tt_yaya_e18.gif",
    "[牙牙傲娇]": "tt_yaya_e19.gif"
  };

  static yaya(String name){
    if(YAYAMAP.containsKey(name)){
      return  YAYABASEPATH + YAYAMAP[name];
    }
    return null;
  }

}
