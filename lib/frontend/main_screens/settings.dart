import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:spark/backend/sqlite_management/local_database_management.dart';
import 'package:spark/frontend/main_screens/profile.dart';
import 'package:spark/global_uses/constants.dart';
import 'package:spark/global_uses/enum_generation.dart';

class SettingsWindow extends StatefulWidget {
  const SettingsWindow({
    Key? key,
  }) : super(key: key);

  @override
  State<SettingsWindow> createState() => _SettingsWindowState();
}

class _SettingsWindowState extends State<SettingsWindow> {
  bool _isDarkMode = false;
  final LocalDatabase _localDatabase = LocalDatabase();
  String username = '';
  String? profilePic;
  String userMail = '';

  //get current username, profile pic and usernamil from local
  void _getProfileDetailsFromLocal() async {
    final String? currentUserName = await _localDatabase.getUserNameForAnyUser(
        FirebaseAuth.instance.currentUser!.email.toString());

    String? pic = await _localDatabase.getParticularFieldDataFromImportantTable(
        userName: currentUserName!,
        getField: GetFieldForImportantDataLocalDatabase.profileImagePath);
    String? mail =
        await _localDatabase.getParticularFieldDataFromImportantTable(
            userName: currentUserName,
            getField: GetFieldForImportantDataLocalDatabase.userEmail);

    if (mounted) {
      setState(() {
        username = currentUserName;
        userMail = mail!;
        profilePic = pic;
      });
    }
  }

  @override
  void initState() {
    _getProfileDetailsFromLocal();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: kWhite,
            body: Center(
              child: Column(children: [
                const SizedBox(height: 15.0),
                const Text('Settings',
                    style: TextStyle(
                      color: kBlack,
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 20.0),
                profilePic == null
                    ? const CircleAvatar(
                        backgroundImage: AssetImage('assets/images/person.png'),
                        radius: 60.0,
                        backgroundColor: kTransparent,
                      )
                    : CircleAvatar(
                        backgroundImage: FileImage(File(profilePic!)),
                        radius: 60.0,
                        backgroundColor: kTransparent,
                      ),
                const SizedBox(height: 10.0),
                Text(
                  username,
                  style: const TextStyle(
                      fontSize: 20.0,
                      color: kBlack,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.0),
                ),
                const SizedBox(height: 5.0),
                Text(
                  userMail,
                  style: const TextStyle(
                      fontSize: 16.0,
                      color: kGrey,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.0),
                ),
                const SizedBox(height: 5.0),
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 10.0, left: 100.0, right: 100.0),
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(100.0, 30.0),
                          primary: kPrimaryAppColor,
                          elevation: 0.0,
                          padding: const EdgeInsets.symmetric(
                              vertical: 2.0, horizontal: 8.0),
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(40.0)))),
                      child: const Text('EDIT PROFILE',
                          style: TextStyle(
                              color: kWhite,
                              letterSpacing: 1.0,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500)),
                      onPressed: () async {
                        final String currentProfilePic = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()));

                        if (mounted) {
                          setState(() {
                            profilePic = currentProfilePic;
                          });
                        }
                      }),
                ),
                const SizedBox(height: 10.0),
                Container(
                  color: const Color.fromARGB(66, 214, 177, 237),
                  width: double.maxFinite,
                  padding:
                      const EdgeInsets.only(top: 3.0, bottom: 3.0, left: 20.0),
                  height: 30.0,
                  child: const Text(
                    'PREFERENCES',
                    style: TextStyle(
                        fontSize: 16.0,
                        color: kGrey,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.0),
                  ),
                ),
                const SizedBox(height: 10.0),
                Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Entypo.moon, color: kGrey, size: 18.0),
                        const SizedBox(width: 10.0),
                        const Text(
                          'Dark Mode',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: kBlack,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Switch(
                            inactiveThumbColor: kGrey,
                            activeColor: kPrimaryAppColor,
                            value: _isDarkMode,
                            onChanged: (value) {
                              setState(() {
                                _isDarkMode = value;
                              });
                            })
                      ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: const [
                      Icon(Entypo.globe, color: kGrey, size: 18.0),
                      SizedBox(width: 10.0),
                      Text(
                        'Language',
                        style: TextStyle(
                            fontSize: 16.0,
                            color: kBlack,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13.0),
                Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: const [
                      Icon(Icons.text_format, color: kGrey, size: 22.0),
                      SizedBox(width: 10.0),
                      Text(
                        'Font Size',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: kBlack,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15.0),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        bottom: 10.0, left: 100.0, right: 100.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(100.0, 30.0),
                          primary: kPrimaryAppColor,
                          elevation: 0.0,
                          padding: const EdgeInsets.symmetric(
                              vertical: 2.0, horizontal: 8.0),
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(40.0)))),
                      child: const Text('LOGOUT',
                          style: TextStyle(
                              color: kWhite,
                              letterSpacing: 1.0,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500)),
                      onPressed: () {},
                    ),
                  ),
                ),
              ]),
            )));
  }
}
