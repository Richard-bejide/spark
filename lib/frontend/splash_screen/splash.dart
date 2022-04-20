import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spark/backend/firebase/online_database_management/cloud_data_management.dart';
import 'package:spark/frontend/auth_screens/login.dart';
import 'package:spark/frontend/main_screens/main_screen.dart';
import 'package:spark/frontend/new_user_entry_screen/new_user_entry.dart';
import 'package:spark/global_uses/constants.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    Timer(const Duration(seconds: 3), () => _contextManager());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
        backgroundColor: kWhite,
        body: Padding(
     padding: const EdgeInsets.only(top: 40.0),
     child: Center(
         child: Image.asset('assets/images/app_icon.jpg',
             height: 160.0, width: 120.0)),
        ),
      );
    
  }

//navigate to login screen if user is not authenticated OR set account screen if user has not added profile pic, username and about OR main screen otherwise
  _contextManager() async {
    //check if user has data on firestore or not
    if (FirebaseAuth.instance.currentUser != null &&
        FirebaseAuth.instance.currentUser!.email != null) {
      final CloudStoreDataManagement _cloudStoreDataManagement =
          CloudStoreDataManagement();
      final bool isDataPresent =
          await _cloudStoreDataManagement.userRecordPresentOrNot(
              email: FirebaseAuth.instance.currentUser!.email.toString());

      ///navigate to [MainScreen] if data is present or  [TakePrimaryUserData] otherwise
      return isDataPresent
          ? Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const MainScreen()))
          : Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const TakePrimaryUserData()));
    }
    //navigate to login screen if user is not authenticated
    else {
      return Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LoginPage()));
    }
  }
}
