import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spark/backend/firebase/online_database_management/cloud_data_management.dart';
import 'package:spark/backend/sqlite_management/local_database_management.dart';
import 'package:spark/frontend/call_screens/call_screen.dart';
import 'package:spark/global_uses/constants.dart';
import 'package:spark/models/call.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PickupScreen extends StatefulWidget {
  final Call call;
  const PickupScreen({Key? key, required this.call}) : super(key: key);

  @override
  State<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen> {
  bool _isLoading = false;

  Dio dio = Dio();

  final FirestoreFieldConstants _firestoreFieldConstants =
      FirestoreFieldConstants();

  final CloudStoreDataManagement _cloudStoreDataManagement =
      CloudStoreDataManagement();
  final LocalDatabase _localDatabase = LocalDatabase();

  /// Fetch Real Time Data From Cloud Firestore
  Future<void> _fetchCallStream() async {
    final Stream<DocumentSnapshot<Map<String, dynamic>>>? realTimeSnapshot =
        await _cloudStoreDataManagement.callStream(
            connectionEmail: widget.call.callerId);
    //check for changes
    realTimeSnapshot!.listen((documentSnapshot) async {
      await _checkingWhetherCallHasEnded(documentSnapshot.data());
    });
  }

  // detect whether call has been cancelled
  Future<void> _checkingWhetherCallHasEnded(Map<String, dynamic>? docs) async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      final Map<String, dynamic> _hasDialled =
          docs![_firestoreFieldConstants.call];
      if (_hasDialled.isEmpty) {
        final String _dateTime =
            "${DateTime.now().day}|${DateTime.now().month}|${DateTime.now().year}  , ${DateTime.now().hour}:${DateTime.now().minute}";

        final String profilePicToDownload =
            (FirebaseAuth.instance.currentUser!.email.toString() ==
                    widget.call.callerId)
                ? widget.call.receiverPic
                : widget.call.callerPic;

        final Directory? directory = await getExternalStorageDirectory();

        Directory _profilePicsDirectory =
            await Directory(directory!.path + '/ProfilePics/').create();

        final String _downloadedProfilePic =
            "${_profilePicsDirectory.path}${DateTime.now().toString().split(" ").join("")}.jpg";

        await dio.download(profilePicToDownload, _downloadedProfilePic);

        _localDatabase.insertDataInCallLogsTable(
            username: (FirebaseAuth.instance.currentUser!.email.toString() ==
                    widget.call.callerId)
                ? widget.call.receiverName
                : widget.call.callerName,
            profilePic: _downloadedProfilePic,
            dateTime: _dateTime,
            isPicked: false,
            isCaller: false);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        Navigator.pop(context);
      }
    } catch (e) {
      print('error in checking call status ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: kWhite,
        body: Container(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.only(top: 100.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Incoming...", style: TextStyle(fontSize: 30)),
                const SizedBox(height: 50),
                CircleAvatar(
                    radius: 35.0,
                    backgroundColor: kTransparent,
                    backgroundImage: NetworkImage(
                      widget.call.callerPic,
                    )),
                const SizedBox(height: 10),
                Text(
                  widget.call.callerName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 75),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        onPressed: () async {
                         
                           await CloudStoreDataManagement()
                             .endCall(call: widget.call);
                        },
                        icon: const Icon(
                          Icons.call_end,
                          color: kRed,
                        )),
                    const SizedBox(
                      width: 25,
                    ),
                    IconButton(
                        onPressed: () async {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      CallScreen(call: widget.call)));
                        },
                        icon: const Icon(
                          Icons.call,
                          color: kGreen,
                        )),
                  ],
                )
              ],
            ),
          ),
        ));
  }
}
