import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spark/frontend/onboarding_screen/onboarding.dart';
import 'package:spark/frontend/splash_screen/splash.dart';
import 'package:spark/global_uses/constants.dart';

int? initScreen;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //sets device orientation to portrait mode only
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  
 //change status bar color and birghtness
 SystemChrome.setSystemUIOverlayStyle(
   const SystemUiOverlayStyle(
     statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  // systemStatusBarContrastEnforced: false,
    //statusBarBrightness: Brightness.dark
    )
  );

  //Initializes a new [FirebaseApp] instance
 await Firebase.initializeApp();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  initScreen = prefs.getInt("initScreen");
  await prefs.setInt("initScreen", 1);

  // //initialize notification settings
  // await initializeNotification();

  // //for background message handling
  // FirebaseMessaging.onBackgroundMessage(backgroundMsgAction);

  // //for foreground message handling
  // FirebaseMessaging.onMessage.listen((messageEvent) {
  //   print(
  //       "Message data is : ${messageEvent.notification!.title} ${messageEvent.notification!.body}");
  //   _receiveAndShowNotificationInitialization(
  //       title: messageEvent.notification!.title.toString(),
  //       body: messageEvent.notification!.body.toString());
  // });

  runApp(MaterialApp(
    title: 'Spark',
    debugShowCheckedModeBanner: false,
    themeMode: ThemeMode.light,
    theme: ThemeData(
      fontFamily: kDefaultFont,
      primarySwatch: primarySwatch,
    ),
    initialRoute: initScreen == 0 || initScreen == null ? "first" : "/",
    routes: {
      '/': (context) => const SplashScreen(),
      "first": (context) => const OnboardingScreen(),
    },
  ));
}


// //initialize notification for new messages
// Future<void> initializeNotification() async {
//   await FirebaseMessaging.instance.subscribeToTopic("Spark");

//   await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
//       alert: true, sound: true, badge: true);
// }

// //receive and show notifixation customization
// void _receiveAndShowNotificationInitialization(
//     {required String title, required String body}) async {
//   final ForegroundNotificationService _fgNotificationService =
//       ForegroundNotificationService();

//   print("Notification Activated");

//   await _fgNotificationService.showNotification(title: title, body: body);
// }

// Future<void> backgroundMsgAction(RemoteMessage message) async {
//   await Firebase.initializeApp();

//   _receiveAndShowNotificationInitialization(
//       title: message.notification!.title.toString(),
//       body: message.notification!.body.toString());
// }
