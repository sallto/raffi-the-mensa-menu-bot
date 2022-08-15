import 'dart:convert';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:raffi_the_mensa_menu_bot/model/menu_item.dart' as mensa;
import 'package:raffi_the_mensa_menu_bot/scraper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
    Widget build(BuildContext context) {
      return MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            // This is the theme of your application.
            //
            // Try running your application with "flutter run". You'll see the
            // application has a blue toolbar. Then, without quitting the app, try
            // changing the primarySwatch below to Colors.green and then invoke
            // "hot reload" (press "r" in the console where you ran "flutter run",
            // or simply save your changes to "hot reload" in a Flutter IDE).
            // Notice that the counter didn't reset back to zero; the application
            // is not restarted.
            primarySwatch: Colors.blue,
            ),
          home: const MyHomePage(title: 'Flutter Demo Home Page'),
          );
    }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
    State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var menu=[];
  void fetchMenu() async {
    final prefs = await SharedPreferences.getInstance();
    var menu= await scrapeMensaSite();
    if(menu.isEmpty){
      // if there is already state it is automatically equal to the saved state.
      if(this.menu.isNotEmpty){
          return;
        }
      var menuStr =prefs.getString('menu');
      if(menuStr==null){
          return;
        }
        // Decode to list then decode the elements to their Respective class.
      var stored_menu = json.decode(menuStr).map<mensa.MenuItem>((e)=>mensa.MenuItem.fromJson(e)).toList();
      setState(() {
              this.menu.addAll(stored_menu);
            });
    }else{
      prefs.setString('menu',jsonEncode(menu));
      setState(() {
              this.menu.clear();
              this.menu.addAll(menu);
            });
    }
  }
  @override
    void initState() {
      super.initState();
      initFetching();
    }
  Future<void> initFetching() async{
    // Configure BackgroundFetch.
    await BackgroundFetch.configure(BackgroundFetchConfig(
          minimumFetchInterval: 8*60, // Fetch every 8 hours min.
          stopOnTerminate: false,
          enableHeadless: true,
          requiresBatteryNotLow: true, // Mensa menu is not important enough to drain battery if it is low
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.NOT_ROAMING
          ), (String taskId) async {
        fetchMenu();
        // IMPORTANT:  You must signal completion of your task or the OS can punish your app
        // for taking too long in the background.
        BackgroundFetch.finish(taskId);
        }, (String taskId) async {  
        // This task has exceeded its allowed running-time.  You must stop what you're doing and immediately .finish(taskId)
        print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
        BackgroundFetch.finish(taskId);
        });

        //fetch initial State
        fetchMenu();
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  @override
    Widget build(BuildContext context) {
      // This method is rerun every time setState is called, for instance as done
      // by the _incrementCounter method above.
      //
      // The Flutter framework has been optimized to make rerunning build methods
      // fast, so that you can just rebuild anything that needs updating rather
      // than having to individually change instances of widgets.
      return Scaffold(
          appBar: AppBar(
            // Here we take the value from the MyHomePage object that was created by
            // the App.build method, and use it to set our appbar title.
            title: Text(widget.title),
            ),
          body: Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            child: Column(
              // Column is also a layout widget. It takes a list of children and
              // arranges them vertically. By default, it sizes itself to fit its
              // children horizontally, and tries to be as tall as its parent.
              //
              // Invoke "debug painting" (press "p" in the console, choose the
              // "Toggle Debug Paint" action from the Flutter Inspector in Android
              // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
              // to see the wireframe for each widget.
              //
              // Column has various properties to control how it sizes itself and
              // how it positions its children. Here we use mainAxisAlignment to
              // center the children vertically; the main axis here is the vertical
              // axis because Columns are vertical (the cross axis would be
              // horizontal).
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
              const Text(
                'You have pushed the button this many times:',
                ),
              Text(
                "${menu.length}",
                style: Theme.of(context).textTheme.headline4,
                ),
              ],
              ),
              ),
              );
    }
}
