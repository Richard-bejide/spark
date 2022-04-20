import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jitsi_meet/jitsi_meet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spark/backend/firebase/online_database_management/cloud_data_management.dart';
import 'package:spark/backend/sqlite_management/local_database_management.dart';
import 'package:spark/global_uses/constants.dart';
import 'package:spark/models/call.dart';

class CallScreen extends StatefulWidget {
  final Call call;
  const CallScreen({Key? key, required this.call}) : super(key: key);
  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final serverText = TextEditingController();
  final roomText = TextEditingController(text: "plugintestroom");
  final subjectText = TextEditingController(text: "Video");
  late String username;
  late String email;
  final iosAppBarRGBAColor =
      TextEditingController(text: "#0080FF80"); //transparent blue
  bool? isAudioOnly = false;
  bool? isAudioMuted = false;
  bool? isVideoMuted = false;

  final CloudStoreDataManagement _cloudStoreDataManagement =
      CloudStoreDataManagement();
  final FirestoreFieldConstants _firestoreFieldConstants =
      FirestoreFieldConstants();
  final LocalDatabase _localDatabase = LocalDatabase();

  bool _isLoading = false;

  Dio dio = Dio();

  /// Fetch Real Time Data From  Cloud Firestore
  Future<void> _fetchCallStream() async {
    final Stream<DocumentSnapshot<Map<String, dynamic>>>? realTimeSnapshot =
        await _cloudStoreDataManagement.callStream(
            connectionEmail: widget.call.callerId);
    realTimeSnapshot!.listen((documentSnapshot) async {
      await _checkingWhetherCallHasEnded(documentSnapshot.data());
    });
  }

  /// check if call has been cancelled
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
            "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}, ${DateTime.now().hour}:${DateTime.now().minute}";

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
            isPicked: true,
            isCaller: (FirebaseAuth.instance.currentUser!.email.toString() ==
                    widget.call.callerId)
                ? true
                : false);
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
  void initState() {
    super.initState();
    username = (FirebaseAuth.instance.currentUser!.email.toString() ==
            widget.call.callerId)
        ? widget.call.callerName
        : widget.call.receiverName;
    email = (FirebaseAuth.instance.currentUser!.email.toString() ==
            widget.call.callerId)
        ? widget.call.callerId
        : widget.call.receiverId;
    JitsiMeet.addListener(JitsiMeetingListener(
        onConferenceWillJoin: _onConferenceWillJoin,
        onConferenceJoined: _onConferenceJoined,
        onConferenceTerminated: _onConferenceTerminated,
        onError: _onError));
    _joinMeeting();
    _fetchCallStream();
  }

  @override
  void dispose() {
    super.dispose();
    JitsiMeet.removeAllListeners();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: kBlack,
      body: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Call again?',
                style: TextStyle(
                    fontSize: 33.0,
                    fontWeight: FontWeight.bold,
                    color: kWhite)),
            const SizedBox(height: 12.0),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(40.0, 40.0),
                      primary: kWhite,
                      elevation: 0.0,
                      padding: const EdgeInsets.symmetric(
                          vertical: 2.0, horizontal: 8.0),
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(40.0)))),
                  child: const Text('Yes',
                      style: TextStyle(
                          color: kBlack,
                          letterSpacing: 1.0,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w500)),
                  onPressed: () {}),
              const SizedBox(width: 17.0),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(40.0, 40.0),
                      primary: kWhite,
                      elevation: 0.0,
                      padding: const EdgeInsets.symmetric(
                          vertical: 2.0, horizontal: 8.0),
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(40.0)))),
                  child: const Text('No',
                      style: TextStyle(
                          color: kBlack,
                          letterSpacing: 1.0,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w500)),
                  onPressed: () {
                    _cloudStoreDataManagement.endCall(call: widget.call);
                  }),
            ])
          ],
        ),
      ),
    );
  }

  _onAudioOnlyChanged(bool? value) {
    setState(() {
      isAudioOnly = value;
    });
  }

  _onAudioMutedChanged(bool? value) {
    setState(() {
      isAudioMuted = value;
    });
  }

  _onVideoMutedChanged(bool? value) {
    setState(() {
      isVideoMuted = value;
    });
  }

  _joinMeeting() async {
    String? serverUrl = serverText.text.trim().isEmpty ? null : serverText.text;

    // Enable or disable any feature flag here
    // If feature flag are not provided, default values will be used
    // Full list of feature flags (and defaults) available in the README
    Map<FeatureFlagEnum, bool> featureFlags = {
      FeatureFlagEnum.WELCOME_PAGE_ENABLED: false,
    };
    if (!kIsWeb) {
      // Here is an example, disabling features for each platform
      if (Platform.isAndroid) {
        // Disable ConnectionService usage on Android to avoid issues (see README)
        featureFlags[FeatureFlagEnum.CALL_INTEGRATION_ENABLED] = false;
      } else if (Platform.isIOS) {
        // Disable PIP on iOS as it looks weird
        featureFlags[FeatureFlagEnum.PIP_ENABLED] = false;
      }
    }
    // Define meetings options here
    var options = JitsiMeetingOptions(room: roomText.text)
      ..serverURL = serverUrl
      ..subject = subjectText.text
      ..userDisplayName = username
      ..userEmail = email
      ..iosAppBarRGBAColor = iosAppBarRGBAColor.text
      ..audioOnly = isAudioOnly
      ..audioMuted = isAudioMuted
      ..videoMuted = isVideoMuted
      ..featureFlags.addAll(featureFlags)
      ..webOptions = {
        "roomName": roomText.text,
        "width": "100%",
        "height": "100%",
        "enableWelcomePage": false,
        "chromeExtensionBanner": null,
        "userInfo": {"displayName": username}
      };

    debugPrint("JitsiMeetingOptions: $options");
    await JitsiMeet.joinMeeting(
      options,
      listener: JitsiMeetingListener(
          onConferenceWillJoin: (message) {
            debugPrint("${options.room} will join with message: $message");
          },
          onConferenceJoined: (message) {
            debugPrint("${options.room} joined with message: $message");
          },
          onConferenceTerminated: (message) {
            debugPrint("${options.room} terminated with message: $message");
          },
          genericListeners: [
            JitsiGenericListener(
                eventName: 'readyToClose',
                callback: (dynamic message) {
                  debugPrint("readyToClose callback");
                }),
          ]),
    );
  }

  void _onConferenceWillJoin(message) {
    debugPrint("_onConferenceWillJoin broadcasted with message: $message");
  }

  void _onConferenceJoined(message) {
    debugPrint("_onConferenceJoined broadcasted with message: $message");
  }

  void _onConferenceTerminated(message) {
    debugPrint("_onConferenceTerminated broadcasted with message: $message");
  }

  _onError(error) {
    debugPrint("_onError broadcasted: $error");
  }
}

