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
          title: 'Mensa Menu fetcher',
          theme: ThemeData(
            primaryColor: Color.fromRGBO(58, 66, 86, 1.0), fontFamily: 'Raleway'
            ),
          home: const MenuPage(),
          );
    }
}

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
    State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  var menu=[];
  void fetchMenu() async {
    final prefs = await SharedPreferences.getInstance();
    var webMenu= await scrapeMensaSite();
    if(webMenu.isEmpty){
      // if there is already state it is automatically equal to the saved state.
      if(menu.isNotEmpty){
        return;
      }
      var menuString =prefs.getString('menu');
      if(menuString==null){
        return;
      }
      // Decode to list then decode the elements to their Respective class.
      var storedMenu = json.decode(menuString).map<mensa.MenuItem>((e)=>mensa.MenuItem.fromJson(e)).toList();
      setState(() {
        // no need to clear since it has to be empty if this code path is reached
          menu.addAll(storedMenu);
          });
    }else{
      prefs.setString('menu',jsonEncode(webMenu));
      setState(() {
          menu.clear();
          menu.addAll(webMenu);
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
        // Signal compleation to OS
        BackgroundFetch.finish(taskId);
        }, (String taskId) async {  
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
            decoration: BoxDecoration(border: Border(right: BorderSide(width: 1.0,color: Colors.white24))),
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
