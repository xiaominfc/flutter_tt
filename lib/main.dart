import 'dart:async';
import 'package:flutter/material.dart';
import './pages/login_page.dart';
import './utils/utils.dart';


void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter tt',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //home: MyHomePage(title: 'Flutter Demo Home Page'),
      //home: new WelcomePage(),
      home: new WelcomePage(),
    );
  }
}

class WelcomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _WelcomePageState();
  }
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            'images/linux_512.png',
            fit: BoxFit.fitWidth,
          ),
          Text('XIAOMINFC.COM',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
        ],
      ),
    );
  }

  Timer timer;

  @override
  void initState() {
    super.initState();
    timer = new Timer(const Duration(milliseconds: 1000), () {
      navigatePage(context, new LoginPage());
      //navigatePage(context,new WelcomePage());
    });
  }
}
