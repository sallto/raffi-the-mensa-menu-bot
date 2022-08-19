import 'dart:convert';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
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
            primaryColor: Color.fromRGBO(58, 66, 86, 1.0), fontFamily: 'Raleway'
            ),
          home: const MyHomePage(),
          );
    }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

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
      IconData getIcon(String category){switch(category){
          case "Suppe":
            return Icons.soup_kitchen;
          case "Pizza":
            return Icons.local_pizza;
          case "Pasta":
            return MaterialCommunityIcons.pasta;
          case "Grill":
            return Icons.outdoor_grill;
          case "Wok":
            return MaterialCommunityIcons.bowl;
          case "Vegetarisch":
            return MaterialCommunityIcons.carrot;
          case "Fleisch":
            return MaterialCommunityIcons.pig;
          case "Studitopf":
            return MaterialCommunityIcons.pot_mix;
          case "Süßspeise":
            return MaterialCommunityIcons.ice_cream;
          case "Fisch":
            return MaterialCommunityIcons.fish;
          default:
            return Icons.key;
        }};
      ListTile makeListTile(mensa.MenuItem item) => ListTile(contentPadding: EdgeInsets.symmetric(horizontal: 20.0,vertical: 10.0),
          leading: Container(
            padding: EdgeInsets.only(right: 10.0),
            decoration: new BoxDecoration(border: Border(right: new BorderSide(width: 1.0,color: Colors.white24))),
            child: Icon(getIcon(item.category),color: Colors.white,),
            ),
          title: Text(item.dish,
            style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
          );
      Card makeCard(mensa.MenuItem item)=>Card(elevation: 8.0,margin:EdgeInsets.symmetric(horizontal: 10.0,vertical: 6.0),
          child: Container(decoration: BoxDecoration(color: Color.fromRGBO(64,75,96,.9)),child: makeListTile(item)));

      final bodyContent= Container(
          child: ListView.builder(
          shrinkWrap: true,
          itemCount: menu.length,
          itemBuilder: ((context, index) {
              return makeCard(this.menu[index]);
              })),
          );

          final topBar=AppBar(elevation: 0.1,
          backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
          title: Text("Mensa Menu Fetcher"),
          centerTitle: true,
          );
      return Scaffold(backgroundColor: Color.fromRGBO(58,66,86,1.0),appBar: topBar,body: bodyContent,);
    }
}
