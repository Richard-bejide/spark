import 'dart:io';
import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spark/backend/firebase/online_database_management/cloud_data_management.dart';
import 'package:spark/backend/sqlite_management/local_database_management.dart';
import 'package:spark/frontend/main_screens/friends/requests.dart';
import 'package:spark/frontend/preview/image_preview.dart';
import 'package:spark/models/request_model.dart';
import 'package:spark/services/chat_management/chat_screen.dart';
import 'package:spark/global_uses/constants.dart';
import 'package:spark/global_uses/enum_generation.dart';
import 'package:spark/models/connection_primary_info.dart';
import 'package:spark/services/search_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => FriendsScreenState();
}

class FriendsScreenState extends State<FriendsScreen> {
  bool _isLoading = false; //loading overlay value

  //all accepted connections
  List<Map<String, String>> _allconnectionsPrimaryInfo = [];

  int totalFriendRequests = 0;
  int totalPendingRequests = 0;
  List<String> usernamesInFriendRequestList = [];
  List<String> usernamesInPendingRequestList = [];
  List<RequestModel> friendRequestList = [];
  List<RequestModel> pendingRequestList = [];

  final CloudStoreDataManagement _cloudStoreDataManagement =
      CloudStoreDataManagement();

  final LocalDatabase _localDatabase = LocalDatabase();

  final FirestoreFieldConstants _firestoreFieldConstants =
      FirestoreFieldConstants();

  TextEditingController _searchFriendsController = TextEditingController();

  Dio dio = Dio();

  //get permission for storage
  void _takePermissionForStorage() async {
    var status = await Permission.storage.request();
    if (status == PermissionStatus.granted) {
      {}
    } else {
      await Permission.storage.request();
    }
  }

  /// check if there are new connected users
  Future<void> _checkingForNewConnection(
      QueryDocumentSnapshot<Map<String, dynamic>> queryDocumentSnapshot,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final List<dynamic> _connectionRequestList =
          queryDocumentSnapshot.get(_firestoreFieldConstants.connectionRequest);

      _connectionRequestList.forEach((element) {
        //check if user has not already been accepted
        List<String> _allFriends = [];
        if (_allconnectionsPrimaryInfo.isNotEmpty) {
          _allconnectionsPrimaryInfo.forEach((element) {
            _allFriends.add(element.keys.first);
          });
        }

        //GET FRIEND REQUESTS
        if (element.values.first ==
            OtherConnectionStatus.invitation_came.toString()) {
          docs.forEach((everyDocument) async {
            if (everyDocument.id == element.keys.first.toString()) {
              final String _userName =
                  everyDocument.get(_firestoreFieldConstants.userName);
              final String _about =
                  everyDocument.get(_firestoreFieldConstants.about);
              final String _profilePic =
                  everyDocument.get(_firestoreFieldConstants.profilePic);

              if (!_allFriends.contains(_userName) &&
                  !usernamesInFriendRequestList.contains(_userName)) {
                if (mounted) {
                  setState(() {
                    totalFriendRequests += 1;
                    usernamesInFriendRequestList.add(_userName);
                    friendRequestList.add(RequestModel(
                        email: everyDocument.id,
                        profilePic: _profilePic,
                        userName: _userName,
                        about: _about));
                   
                  });
                }
              }
            }
          });
        }
        //GET PENDING  REQUESTS
        if (element.values.first ==
            OtherConnectionStatus.request_pending.toString()) {
          docs.forEach((everyDocument) async {
            if (everyDocument.id == element.keys.first.toString()) {
              final String _userName =
                  everyDocument.get(_firestoreFieldConstants.userName);
              final String _about =
                  everyDocument.get(_firestoreFieldConstants.about);
              final String _profilePic =
                  everyDocument.get(_firestoreFieldConstants.profilePic);
              if (!_allFriends.contains(_userName) &&
                  !usernamesInPendingRequestList.contains(_userName)) {
                if (mounted) {
                  setState(() {
                    totalPendingRequests += 1;
                    usernamesInPendingRequestList.add(_userName);
                    pendingRequestList.add(RequestModel(
                        email: everyDocument.id,
                        profilePic: _profilePic,
                        userName: _userName,
                        about: _about));
                   
                  });
                }
              }
            }
          });
        }
      });

      //if connection request has been accepted
      _connectionRequestList.forEach((connectionRequestData) {
        if (connectionRequestData.values.first.toString() ==
                OtherConnectionStatus.invitation_accepted.toString() ||
            connectionRequestData.values.first.toString() ==
                OtherConnectionStatus.request_accepted.toString()) {
          //save accepted connection's data
          //use the usermail in connectionRequestData to search the QueryDocumentSnapshot.id and get the accepted user's data
          docs.forEach((everyDocument) async {
            if (everyDocument.id ==
                connectionRequestData.keys.first.toString()) {
              final String _connectedUserName =
                  everyDocument.get(_firestoreFieldConstants.userName);
              final String _token =
                  everyDocument.get(_firestoreFieldConstants.token);
              final String _about =
                  everyDocument.get(_firestoreFieldConstants.about);
              final String _accCreationDate =
                  everyDocument.get(_firestoreFieldConstants.creationDate);
              final String _accCreationTime =
                  everyDocument.get(_firestoreFieldConstants.creationTime);
              final String _profilePic =
                  everyDocument.get(_firestoreFieldConstants.profilePic);

              //avoid redownloading profile picture if it has already been downloaded
              late String _downloadedProfilePic;
              final String? _checkIfProfilePicHasBeenDownloaded =
                  await _localDatabase.getParticularFieldDataFromImportantTable(
                      userName: _connectedUserName,
                      getField: GetFieldForImportantDataLocalDatabase
                          .profileImageUrl);

              if (_checkIfProfilePicHasBeenDownloaded == null) {
                final Directory? directory =
                    await getExternalStorageDirectory();

                Directory _profilePicsDirectory =
                    await Directory(directory!.path + '/ProfilePics/').create();
                _downloadedProfilePic =
                    "${_profilePicsDirectory.path}${DateTime.now().toString().split(" ").join("")}.jpg";

                await dio.download(_profilePic, _downloadedProfilePic);
              }

              //insert data of newly connected user or update if the user is already present

              //check if connected user already has data
              final String? _getConnectedUsername =
                  await _localDatabase.getParticularFieldDataFromImportantTable(
                      userName: _connectedUserName,
                      getField: GetFieldForImportantDataLocalDatabase.userName);
              // if username is not found
              if (_getConnectedUsername == null) {
                final bool _newConnectionUserNameInserted =
                    await _localDatabase.insertOrUpdateDataForThisAccount(
                        userName: _connectedUserName,
                        userMail: everyDocument.id,
                        userToken: _token,
                        userAbout: _about,
                        userAccCreationDate: _accCreationDate,
                        userAccCreationTime: _accCreationTime,
                        profileImagePath: _downloadedProfilePic,
                        profileImageUrl: _profilePic);

                // if (usernamesInPendingRequestList
                //     .contains(_connectedUserName)) {
                //   if (mounted) {
                //     setState(() {
                //       pendingRequestList.removeAt(usernamesInPendingRequestList
                //           .indexOf(_connectedUserName));
                //       usernamesInPendingRequestList.removeAt(
                //           usernamesInPendingRequestList
                //               .indexOf(_connectedUserName));
                //       totalPendingRequests - 1;
                //     });
                //   }
                // }
                // if (usernamesInFriendRequestList.contains(_connectedUserName)) {
                //   if (mounted) {
                //     setState(() {
                //       friendRequestList.removeAt(usernamesInFriendRequestList
                //           .indexOf(_connectedUserName));
                //       usernamesInFriendRequestList.removeAt(
                //           usernamesInFriendRequestList
                //               .indexOf(_connectedUserName));
                //       totalFriendRequests - 1;
                //     });
                //   }
                // }

                print(
                    '_newConnectionUserNameInserted $_newConnectionUserNameInserted');
                if (_newConnectionUserNameInserted) {
                  //create table to store connection's messages
                  await _localDatabase.createTableForEveryUser(
                      username: _connectedUserName);
                  if (mounted) {
                    setState(() {
                      _allconnectionsPrimaryInfo.add({
                        _connectedUserName: '$_about/////$_downloadedProfilePic'
                      });
                    });
                  }
                }
              }
              //update if user is already present
              else {
                late String newProfilePicPath;
                String? oldProfilePicPath;

                if (_checkIfProfilePicHasBeenDownloaded != _profilePic) {
                  final Directory? directory =
                      await getExternalStorageDirectory();

                  Directory _profilePicsDirectory =
                      await Directory(directory!.path + '/ProfilePics/')
                          .create();
                  newProfilePicPath =
                      "${_profilePicsDirectory.path}${DateTime.now().toString().split(" ").join("")}.jpg";

                  await dio.download(_profilePic, newProfilePicPath);
                } else {
                  oldProfilePicPath = await _localDatabase
                      .getParticularFieldDataFromImportantTable(
                          userName: _connectedUserName,
                          getField: GetFieldForImportantDataLocalDatabase
                              .profileImagePath);
                }

                await _localDatabase.insertOrUpdateDataForThisAccount(
                    purpose: 'update',
                    userName: _connectedUserName,
                    userMail: everyDocument.id,
                    userToken: _token,
                    userAbout: _about,
                    userAccCreationDate: _accCreationDate,
                    userAccCreationTime: _accCreationTime,
                    profileImagePath:
                        (_checkIfProfilePicHasBeenDownloaded != _profilePic)
                            ? newProfilePicPath
                            : oldProfilePicPath!,
                    profileImageUrl: _profilePic);
              }
            }
          });
        }
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('unable to get connections info from firebase ${e.toString()}');
    }
  }

  // Fetch Real Time Data From Cloud Firestore
  Future<void> _fetchRealTimeDataFromCloudStorage() async {
    final realTimeSnapshot =
        await _cloudStoreDataManagement.fetchRealTimeDataFromFirestore();

    realTimeSnapshot!.listen((querySnapshot) {
      querySnapshot.docs.forEach((queryDocumentSnapshot) async {
        //check  real time changes in the database for only the current user
        if (queryDocumentSnapshot.id ==
            FirebaseAuth.instance.currentUser!.email.toString()) {
          //check the request_collection field for new changes
          _checkingForNewConnection(queryDocumentSnapshot, querySnapshot.docs);
        }
      });
    });
  }

  //get all connections info from local
  Future<void> _getAllConnectionsPrimaryInfo() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      List<ConnectionPrimaryInfo> _allConnectionsPrimaryInfo =
          await _localDatabase.getConnectionPrimaryInfo();

      for (int i = 0; i < _allConnectionsPrimaryInfo.length; i++) {
        final ConnectionPrimaryInfo connectionPrimaryInfo =
            _allConnectionsPrimaryInfo[i];
        if (mounted) {
          setState(() {
            _allconnectionsPrimaryInfo.add({
              connectionPrimaryInfo.connectionUsername:
                  '${connectionPrimaryInfo.connectionAbout}/////${connectionPrimaryInfo.profilePic}'
            });
          });
        }
      }
    } catch (e) {
      print(
          " Error in fetching all connections primary info : ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  //init
  void _init() async {
    _takePermissionForStorage();
    await _getAllConnectionsPrimaryInfo();
    _fetchRealTimeDataFromCloudStorage();
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: kWhite,
          body: LoadingOverlay(
              isLoading: _isLoading,
              child: ListView(shrinkWrap: true, children: [
                Container(
                    color: kWhite,
                    height: 100.0,
                    width: double.maxFinite,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 5.0),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text('Friends',
                                    style: TextStyle(
                                      color: kBlack,
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w600,
                                    )),
                                const SizedBox(width: 105.0),
                                IconButton(
                                    icon: const Icon(
                                        Icons.person_add_alt_rounded,
                                        size: 23.0,
                                        color: kBlack),
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          PageTransition(
                                              type: PageTransitionType.fade,
                                              child: const SearchScreen()));
                                    }),
                                const SizedBox(width: 2.0),
                              ]),
                          _searchFriendsList(),
                        ])),
                ListView(shrinkWrap: true, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _requestButton(
                              text: 'Friend Requests',
                              onTap: () {
                                Navigator.push(
                                    context,
                                    PageTransition(
                                        type: PageTransitionType.fade,
                                        child: RequestScreen(
                                            buttonName: 'Accept',
                                            requestList: friendRequestList,
                                            pageTitle: 'Friend Requests')));
                              },
                              totalRequests: totalFriendRequests,
                              color: kBlue),
                          const SizedBox(width: 15.0),
                          _requestButton(
                              text: 'Pending Requests',
                              onTap: () {
                                Navigator.push(
                                    context,
                                    PageTransition(
                                        type: PageTransitionType.fade,
                                        child: RequestScreen(
                                            buttonName: 'Pending',
                                            requestList: pendingRequestList,
                                            pageTitle: 'Pending Requests')));
                              },
                              totalRequests: totalPendingRequests,
                              color: const Color.fromARGB(255, 216, 116, 8)),
                          const SizedBox(width: 28.0),
                          const Text('Friends: ',
                              style: TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.w600)),
                          _allconnectionsPrimaryInfo.isEmpty
                              ? const Text('0',
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w600))
                              : Text('${_allconnectionsPrimaryInfo.length}',
                                  style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w600))
                        ]),
                  ),
                  _allconnectionsPrimaryInfo.isEmpty
                      ? Container(
                          alignment: Alignment.topCenter,
                          padding: const EdgeInsets.only(top: 155.0),
                          child: const Text(
                            'No Friends yet',
                            style: TextStyle(
                                color: kGrey,
                                fontSize: 18.0,
                                letterSpacing: 1.0),
                          ))
                      : Padding(
                          padding: const EdgeInsets.only(
                              left: 8.0, right: 8.0, top: 10.0),
                          child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _allconnectionsPrimaryInfo.length,
                              itemBuilder: (context, position) {
                                return _connectionTile(
                                  context,
                                  position,
                                );
                              }))
                ])
              ]))),
    );
  }

  //chat tile
  Widget _connectionTile(BuildContext context, int index) {
    return ListTile(
        key: Key('$index'),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ChatScreen(
                      username: _allconnectionsPrimaryInfo[index].keys.first,
                      profilePic: _allconnectionsPrimaryInfo[index]
                          .values
                          .first
                          .split('/////')[1])));
        },
        leading: GestureDetector(
            child: CircleAvatar(
                radius: 25.0,
                backgroundColor: Colors.transparent,
                backgroundImage: FileImage(File(_allconnectionsPrimaryInfo[index]
                    .values
                    .first
                    .split('/////')[1]))),
            onTap: () {
              Navigator.push(
                  context,
                  PageTransition(
                      type: PageTransitionType.fade,
                      child: ImageViewScreen(
                          imageProviderCategory:
                              ImageProviderCategory.fileImage,
                          imagePath: _allconnectionsPrimaryInfo[index]
                              .values
                              .first
                              .split('/////')[1])));
            }),
        title: Text(
            _allconnectionsPrimaryInfo[index].keys.first.length <= 20
                ? _allconnectionsPrimaryInfo[index].keys.first
                : _allconnectionsPrimaryInfo[index].keys.first.replaceRange(
                    20,
                    _allconnectionsPrimaryInfo[index].keys.first.length,
                    '...'), //ensure title length is no more than 18
            style: const TextStyle(
                fontSize: 18.0,
                color: kBlack,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.0)),
        subtitle: Text(
            _allconnectionsPrimaryInfo[index]
                        .values
                        .first
                        .split('/////')[0]
                        .length <=
                    30
                ? _allconnectionsPrimaryInfo[index]
                    .values
                    .first
                    .split('/////')[0]
                : _allconnectionsPrimaryInfo[index]
                    .values
                    .first
                    .split('/////')[0]
                    .replaceRange(
                        30,
                        _allconnectionsPrimaryInfo[index].values.first.length,
                        '...'), //ensure subtitle length is no more than 30
            style: const TextStyle(
              color: kGrey,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              fontStyle: FontStyle.italic,
              fontSize: 13.0,
            )));
  }

  Widget _searchFriendsList() {
    return Container(
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(30.0))),
      child: TextField(
          maxLines: 1,
          controller: _searchFriendsController,
          style: const TextStyle(
              color: kBlack, letterSpacing: 1.0, fontSize: 16.0),
          decoration: InputDecoration(
            constraints: const BoxConstraints(maxHeight: 40.0, maxWidth: 260.0),
            suffixIcon: IconButton(
                icon: const Icon(Icons.search, size: 22.0, color: kGrey),
                onPressed: () {}),
            hintText: 'Search',
            fillColor: const Color.fromARGB(26, 63, 2, 142),
            filled: true,
            focusColor: null,
            hintStyle: const TextStyle(
                color: kGrey, fontSize: 18.0, letterSpacing: 1.0),
            enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(50)),
                borderSide: BorderSide(color: kTransparent)),
            focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(50)),
                borderSide: BorderSide(color: kTransparent)),
          )),
    );
  }

  Widget _requestButton(
      {required String text,
      required Function() onTap,
      required int totalRequests,
      required Color color}) {
    return Badge(
        badgeColor: kRed,
        position: BadgePosition.topEnd(top: -1, end: -7),
        badgeContent: Text('$totalRequests',
            style: const TextStyle(fontSize: 12.0, color: kWhite)),
        child: TextButton(
            style: TextButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0)),
                side: BorderSide(color: color)),
            child: Text(text,
                style: const TextStyle(fontSize: 12.0, color: kWhite)),
            onPressed: onTap));
  }
}
