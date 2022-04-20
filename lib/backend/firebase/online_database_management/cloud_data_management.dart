import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:spark/backend/sqlite_management/local_database_management.dart';
import 'package:spark/global_uses/constants.dart';
import 'package:spark/global_uses/enum_generation.dart';
import 'package:spark/models/search.dart';
import 'package:spark/services/notification_service.dart';
import 'package:spark/models/call.dart';

class CloudStoreDataManagement {
  final _collectionName = 'spark_users';
  final SendNotification _sendNotification = SendNotification();
  final LocalDatabase _localDatabase = LocalDatabase();
  final String? currentUserEmail = FirebaseAuth.instance.currentUser!.email;
  //check if username is already present
  Future<bool> checkUsernamePresence({required String username}) async {
    try {
      //Contains the query result of the username field.
      final QuerySnapshot<Map<String, dynamic>> findResults =
          await FirebaseFirestore.instance
              .collection(_collectionName)
              .where('username', isEqualTo: username)
              .get();

      //returns true if the list of all the documents included in the snapshot is empty
      return findResults.docs.isEmpty ? true : false;
    } catch (e) {
      return true;
    }
  }

//register new user with primary information entered
  Future<bool> registerNewUser(
      {required String username,
      required String userAbout,
      required String userEmail,
      required String profilePic}) async {
    try {
      //get user account registration date
      final String currentDate = DateFormat('dd-MM-yy').format(DateTime.now());

      //get user account registration time
      final String currentTime = DateFormat('hh:mm a').format(DateTime.now());

      //Returns the default FCM token for this device.
      final String? _getToken = await FirebaseMessaging.instance.getToken();

      ///set data to the firestore collection [_collectionName], overwriting any existing data
      await FirebaseFirestore.instance.doc('$_collectionName/$userEmail').set({
        "about": userAbout,
        'online_status': "",
        "status": [],
        "connection_request": [],
        "connections": {},
        "creation_date": currentDate,
        "creation_time": currentTime,
        "phone_number": "",
        "profile_pic": profilePic,
        "token": _getToken.toString(),
        "totalconnections": "",
        "username": username,
        "call": {},
      });

      return true;
    } catch (e) {
      //error in registering new user
      return false;
    }
  }

  //check if user has data on firestore
  Future<bool> userRecordPresentOrNot({required String email}) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance.doc('$_collectionName/$email').get();
      return documentSnapshot.exists;
    } catch (e) {
      return false;
    }
  }

//get account creation date,time and device token from cloud firestore
  Future<Map<String, dynamic>> getDataFromCloudFireStore(
      {required String email}) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance.doc('$_collectionName/$email').get();

      final Map<String, dynamic> importantData = <String, dynamic>{};

      importantData['token'] = documentSnapshot.data()!['token'];
      importantData['date'] = documentSnapshot.data()!['creation_date'];
      importantData['time'] = documentSnapshot.data()!['creating_time'];

      return importantData;
    } catch (e) {
      print('error in getting token from cloud firestore: ${e.toString()}');
      return {};
    }
  }

  //get a list of all users on firestore
  Future<List<Search>> getAllUsersList(
      {required String currentUserEmail}) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> _querySnapshot =
          await FirebaseFirestore.instance.collection(_collectionName).get();

      List<Search> _usersDataCollection = [];

      _querySnapshot.docs.forEach((queryDocumentSnapshot) {
        //exclude current user data from query result
        if (currentUserEmail != queryDocumentSnapshot.id) {
          _usersDataCollection.add(Search(
              email: queryDocumentSnapshot.id,
              userName: queryDocumentSnapshot.get("username"),
              profilePic: queryDocumentSnapshot.get("profile_pic"),
              about: queryDocumentSnapshot.get("about")));
        }
      });

      // print(_usersDataCollection);
      return _usersDataCollection;
    } catch (e) {
      print('Error in getting All Users List: ${e.toString()}');
      return [];
    }
  }

  //returns current user connection request list
  Future<List<dynamic>> currentUserConnectionRequestList(
      {required String email}) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> currentUserDocumentSnapshot =
          await FirebaseFirestore.instance.doc('$_collectionName/$email').get();

      final Map<String, dynamic>? currentUserMap =
          currentUserDocumentSnapshot.data();

      final List<dynamic> _connectionRequestCollection =
          currentUserMap!["connection_request"];
      return _connectionRequestCollection;
    } catch (e) {
      print('Error in current user collection list : ${e.toString()}');
      return [];
    }
  }

  //update connection status for both current user and opposite user
  Future<void> changeConnectionStatus(
      {required String oppositeUserMail,
      required String currentUserMail,
      required String connectionUpdatedStatus,
      required List<dynamic> currentUserUpdatedConnectionRequest,
      bool? storeDataAlsoInConnections}) async {
    try {
      //OPPOSITE USER CONNECTION DATABASE UPDATE
      final DocumentSnapshot<Map<String, dynamic>>
          oppositeUserDocumentSnapshot = await FirebaseFirestore.instance
              .doc('$_collectionName/$oppositeUserMail')
              .get();

      Map<String, dynamic>? oppositeUserMap =
          oppositeUserDocumentSnapshot.data();

      //store the connection request list
      List<dynamic> oppositeConnection = oppositeUserMap!['connection_request'];

      int index = -1;

      oppositeConnection.forEach((element) {
        if (element.keys.toString() == currentUserMail) {
          //get the index of the current user  in the connection request list
          index = oppositeConnection.indexOf(element);
        }
      });

      if (index > -1) {
        //delete the current user connection request from the connection request list
        oppositeConnection.removeAt(index);
      }
      //print('opposite connections : $oppositeConnection');

      //add the updated current user's connection status
      oppositeConnection.add({currentUserMail: connectionUpdatedStatus});

      // print("connection_request : $oppositeConnection");

      oppositeUserMap["connection_request"] = oppositeConnection;

      await FirebaseFirestore.instance
          .doc('$_collectionName/$oppositeUserMail')
          .update(oppositeUserMap);

      //CURRENT USER CONNECTION DATABASE UPDATE

      final DocumentSnapshot<Map<String, dynamic>> currentUserDocumentSnapshot =
          await FirebaseFirestore.instance
              .doc('$_collectionName/$currentUserMail')
              .get();

      final Map<String, dynamic>? currentUserMap =
          currentUserDocumentSnapshot.data();

      currentUserMap!["connection_request"] =
          currentUserUpdatedConnectionRequest;

      await FirebaseFirestore.instance
          .doc('$_collectionName/$currentUserMail')
          .update(currentUserMap);
    } catch (e) {
      //print('error in updating connection status : ${e.toString()});
    }
  }

  //fetch real time data from firestore
  Future<Stream<QuerySnapshot<Map<String, dynamic>>>?>
      fetchRealTimeDataFromFirestore() async {
    try {
      return FirebaseFirestore.instance.collection(_collectionName).snapshots();
    } catch (e) {
      print('Error in Fetching Real Time Data : ${e.toString()}');
      return null;
    }
  }

  //fetch real time messages from
  Future<Stream<DocumentSnapshot<Map<String, dynamic>>>?>
      fetchRealTimeMessages() async {
    try {
      return FirebaseFirestore.instance
          .doc(
              '$_collectionName/${FirebaseAuth.instance.currentUser!.email.toString()}')
          .snapshots();
    } catch (e) {
      print('Error in Fetch Real Time Data : ${e.toString()}');
      return null;
    }
  }

//sending current user's messages to connection
  Future<void> sendMessageToConnection(
      {required String connectionUserName,
      required Map<String, Map<String, String>> sendMessageData,
      required ChatMessageType chatMessageType}) async {
    try {
      final String? currentUserEmail = FirebaseAuth.instance.currentUser!.email;

      //get connected user's mail from the importDataTable record using their username
      final String? _getConnectedUserEmail =
          await _localDatabase.getParticularFieldDataFromImportantTable(
              userName: connectionUserName,
              getField: GetFieldForImportantDataLocalDatabase.userEmail);

      //document snaphot of connected user
      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .doc("$_collectionName/$_getConnectedUserEmail")
              .get();

      final Map<String, dynamic>? connectedUserData = documentSnapshot.data();

      //get list of all previous messages from current user
      List<dynamic>? getOldMessages =
          connectedUserData![FirestoreFieldConstants().connections]
              [currentUserEmail.toString()];

      //if there are no previous messages
      if (getOldMessages == null) {
        getOldMessages = [];
      }

      getOldMessages.add(sendMessageData);

      connectedUserData[FirestoreFieldConstants().connections]
          [currentUserEmail.toString()] = getOldMessages;

      // print("Data checking:  ${connectedUserData[FirestoreFieldConstants().connections]}");

      await FirebaseFirestore.instance
          .doc("$_collectionName/$_getConnectedUserEmail")
          .update({
        FirestoreFieldConstants().connections:
            connectedUserData[FirestoreFieldConstants().connections],
      }).whenComplete(() async {
        print('Data Sent');

        //extract connection's token
        final String? connectionToken =
            await _localDatabase.getParticularFieldDataFromImportantTable(
                userName: connectionUserName,
                getField: GetFieldForImportantDataLocalDatabase.token);

        //extract current user's username
        final String? currentAccountUserName =
            await _localDatabase.getUserNameForAnyUser(
                FirebaseAuth.instance.currentUser!.email.toString());

        //send message notification
        await _sendNotification.messageNotificationClassifier(
            messageType: chatMessageType,
            messageData: sendMessageData,
            connectionToken: connectionToken ?? "",
            connectionAccountUsername: connectionUserName);
      });
    } catch (e) {
      // print('error in Sending Data: ${e.toString()}');
    }
  }

  //remove all previous messages of connection from current user's acct
  Future<void> removeOldMessages({required String connectionEmail}) async {
    try {
      final String? currentUserEmail = FirebaseAuth.instance.currentUser!.email;

      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .doc("$_collectionName/$currentUserEmail")
              .get();

      final Map<String, dynamic>? connectedUserData = documentSnapshot.data();

      connectedUserData![FirestoreFieldConstants().connections]
          [connectionEmail.toString()] = [];

      await FirebaseFirestore.instance
          .doc("$_collectionName/$currentUserEmail")
          .update({
        FirestoreFieldConstants().connections:
            connectedUserData[FirestoreFieldConstants().connections],
      }).whenComplete(() {
        print('Data Deleted');
      });
    } catch (e) {
      print('error in  removeOldMessages: ${e.toString()}');
    }
  }

  //sending media files to connection
  Future<String?> uploadMediaToStorage(File filePath,
      {required String reference}) async {
    try {
      String? downLoadUrl;

      final String fileName =
          '${FirebaseAuth.instance.currentUser!.uid}${DateTime.now().day}${DateTime.now().month}${DateTime.now().year}${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}${DateTime.now().millisecond}';

      final Reference firebaseStorageRef =
          FirebaseStorage.instance.ref(reference).child(fileName);

      print('Firebase Storage Reference: $firebaseStorageRef');

      final UploadTask uploadTask = firebaseStorageRef.putFile(filePath);

      await uploadTask.whenComplete(() async {
        print("Media Uploaded");
        downLoadUrl = await firebaseStorageRef.getDownloadURL();
        print("Download Url: $downLoadUrl}");
      });

      return downLoadUrl!;
    } catch (e) {
      print("Error: Firebase Storage Exception is: ${e.toString()}");
      return null;
    }
  }

  //fetch real time call data
  Future<Stream<DocumentSnapshot<Map<String, dynamic>>>?> callStream(
      {required String connectionEmail}) async {
    try {
      return FirebaseFirestore.instance
          .doc('$_collectionName/$connectionEmail')
          .snapshots();
    } catch (e) {
      print('Error in Fetching Real Time Data : ${e.toString()}');
      return null;
    }
  }

//set data in the call map
  Future<bool> makeCall(Call call) async {
    try {
      Map<String, dynamic> callMap = Call.toMap(call);

      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .doc('$_collectionName/$currentUserEmail')
              .get();

      final Map<String, dynamic>? currentUserData = documentSnapshot.data();

      currentUserData![FirestoreFieldConstants().call] = callMap;

      await FirebaseFirestore.instance
          .doc("$_collectionName/$currentUserEmail")
          .update({
        FirestoreFieldConstants().call:
            currentUserData[FirestoreFieldConstants().call],
      }).whenComplete(() async {
        print('call has been made');
      });
      return true;
    } catch (e) {
      print('error in making call ${e.toString()}');
      return false;
    }
  }

//delete data in the call map
  Future<bool> endCall({required Call call}) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .doc("$_collectionName/$currentUserEmail")
              .get();

      final Map<String, dynamic>? callData = documentSnapshot.data();

      callData!["call"] = {};

      await FirebaseFirestore.instance
          .doc("$_collectionName/$currentUserEmail")
          .update({
        "call": callData["call"],
      });

      return true;
    } catch (e) {
      print('error in ending call ${e.toString()}');
      return false;
    }
  }

  //upload status
  Future<void> uploadStatusData({required String filePath}) async {
    try {
      final String? currentUserEmail = FirebaseAuth.instance.currentUser!.email;

      //document snaphot
      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .doc("$_collectionName/$currentUserEmail")
              .get();

      final Map<String, dynamic>? currentUserData = documentSnapshot.data();

      List<dynamic> getStatusList =
          currentUserData![FirestoreFieldConstants().status];

      getStatusList
          .add({filePath: "${DateTime.now().hour}:${DateTime.now().minute}"});

      currentUserData[FirestoreFieldConstants().status] = getStatusList;

      await FirebaseFirestore.instance
          .doc("$_collectionName/$currentUserEmail")
          .update({
        FirestoreFieldConstants().status:
            currentUserData[FirestoreFieldConstants().status],
      }).whenComplete(() async {
        print('Status has been uploaded');
      });
    } catch (e) {
      print('error in Sending Data: ${e.toString()}');
    }
  }

  //upload profile picture
  Future<void> uploadProfilePic({required String filePath}) async {
    try {
      final String? currentUserEmail = FirebaseAuth.instance.currentUser!.email;

      //document snaphot
      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .doc("$_collectionName/$currentUserEmail")
              .get();

      final Map<String, dynamic>? currentUserData = documentSnapshot.data();

      currentUserData![FirestoreFieldConstants().profilePic] = filePath;

      await FirebaseFirestore.instance
          .doc("$_collectionName/$currentUserEmail")
          .update({
        FirestoreFieldConstants().profilePic:
            currentUserData[FirestoreFieldConstants().profilePic],
      }).whenComplete(() async {
        print('profile pic has been uploaded');
      });
    } catch (e) {
      print('error in uploading profile pic: ${e.toString()}');
    }
  }

  //change user online status
  Future<void> changeUserOnlineStatus({required String status}) async {
    try {
      final String? currentUserEmail = FirebaseAuth.instance.currentUser!.email;
      //document snaphot
      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .doc("$_collectionName/$currentUserEmail")
              .get();

      final Map<String, dynamic>? currentUserData = documentSnapshot.data();

      currentUserData!['online_status'] = status;

      await FirebaseFirestore.instance
          .doc("$_collectionName/$currentUserEmail")
          .update({
        'online_status': currentUserData['online_status'],
      }).whenComplete(() async {
        print('user online Status has been changed');
      });
    } catch (e) {
      print('error in changing user online status : ${e.toString()}');
    }
  }
}
