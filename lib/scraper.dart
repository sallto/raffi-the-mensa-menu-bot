import 'dart:convert';
import 'package:collection/collection.dart';

import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:raffi_the_mensa_menu_bot/model/menu_item.dart';

Future scrapeMensaSite() async {
    try{
    // Make API Call
    Response r = await Client().get(Uri.parse('https://www.studentenwerk-muenchen.de/mensa/speiseplan/speiseplan_422_-de.html#heute'));
    if(r.statusCode!=200){
        return [];
      }
      var doc = parse(r.body);
      var todayMenu=doc.querySelector('a[name="heute"]')?.parent?.parent;
      if(todayMenu==null){
          return [];
        }
      var categories = todayMenu.querySelectorAll(".stwm-artname").map((e) => e.text);
      var dishes= todayMenu.querySelectorAll(".js-schedule-dish-description").map((e) => e.innerHtml.split("<")[0])
      // Fix bad encoding on original site
      .map((e) => utf8.decode(latin1.encode(e),allowMalformed: true));
      return  IterableZip([dishes,categories]).map((e) => MenuItem(e[0],e[1])).toList();
    } catch (e){
      return [];
    }
  }
