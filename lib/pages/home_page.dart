//
// home_page.dart
// Copyright (C) 2019 xiaominfc(武汉鸣鸾信息科技有限公司) <xiaominfc@gmail.com>
//
// Distributed under terms of the MIT license.
//

import 'package:flutter/material.dart';
import './chat_page.dart';
import './contacts_page.dart';
import './personal_page.dart';

class HomePage extends StatefulWidget { 
  
  @override
  State<StatefulWidget> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.bold);
  List<Widget> _widgetOptions = <Widget>[
    ChatPage(),
    ContactsPage(),
    PersonalPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  buildPage(int index) {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar: AppBar(
        //     title: const Text('BottomNavigationBar Sample'),
        // ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: BottomNavigationBar(
            type:BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  icon: Icon(Icons.message),
                  title: Text('消息'),
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.contacts),
                  title: Text('联系人'),
              ),
              // BottomNavigationBarItem(
              //     icon: Icon(Icons.devices_other),
              //     title: Text('其他'),
              // ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  title: Text('我的'),
              ),
              
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.blue,
            
            onTap: _onItemTapped,
        ),
        );
  }

}
