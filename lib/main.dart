import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/*
curl -X POST -H "Authorization: Bearer ACCESS_TOKEN" \
-H "Content-Type: application/json" \
-d '{
  "message": {
    "token": "DEVICE_REGISTRATION_TOKEN",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test message"
    }
  }
}' https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send


* */

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('onBackgroundMessage received: $message');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  _firebaseMessaging.requestPermission();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  notificationDetails() {
    return NotificationDetails(
        android: AndroidNotificationDetails('kanalid', 'kanalisim',
            importance: Importance.max),
        iOS: DarwinNotificationDetails());
  }

  Future showNotification(
      {int id = 0, String? title, String? body, String? payLoad}) async {
    return flutterLocalNotificationsPlugin.show(
        id, title, body, await notificationDetails());
  }

  String? gelenToken = "";

  Future<void> fcmBaslat() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // iOS için izin isteme
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }

    AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings("@mipmap/ic_launcher");

    var initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payload) async {});

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {});

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Token almak için
    gelenToken = await _firebaseMessaging.getToken();
    print('Token: $gelenToken');
    // await Clipboard.setData(ClipboardData(text: gelenToken!));

    // mesaj gelince burası çalışır
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('onMessage received: $message');
      if (Platform.isAndroid) {
        final title = message.notification!.title;
        final body = message.notification!.body;
        showNotification(title: title, body: body);
      }

    });

    // uygulama kapalı iken veya arkaplanda iken Bildirime tıklanınca çalışır
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('onMessageOpenedApp received: $message');
    });

    FirebaseMessaging.instance
        .subscribeToTopic("all")
        .then((value) => print("topic all olarak eklendi"));

    setState(() {

    });
  }

  @override
  void initState() {
    super.initState();
    fcmBaslat();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter FCM V1',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: false,
      ),
      home: Container(child: Text("Anasayfa"),),
    );
  }
}

