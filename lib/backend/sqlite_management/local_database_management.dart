import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spark/global_uses/enum_generation.dart';
import 'package:spark/models/call_log.dart';
import 'package:spark/models/latest_message_from_connection.dart';
import 'package:spark/models/previous_message.dart';
import 'package:spark/models/connection_primary_info.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
//for important table
  final String _importantTableData = "__Important_table_data__";
//all columns
  final String _colUsername = "Username";
  final String _colUserMail = "User_mail";
  final String _colToken = "Token";
  final String _colProfileImagePath = "Profile_image_path";
  final String _colProfileImageUrl = "Profile_Image_url";
  final String _colAbout = "About";
  final String _colWallpaper = "Chat_wallpaper";
  final String _colNotification = "Notification_status";
  final String _colMobileNumber = "User_mobile_number";
  final String _colAccountCreationDate = "Account_Creation_date";
  final String _colAccountCreationTime = "Account_Creation_time";

//for call logs
  final String _callLogData = "__call_logs__";

//all columns
  final String _colCallLogUsername = "username";
  final String _colCallLogDateTime = "date_time";
  final String _colCallLogIspicked = "isPicked";
   final String _colCallLogIsCaller = "isCaller";
  final String _colCallLogProfilePic = "profile_pic";

  // For chat messages with connection
  final String _colActualMessage = "Message";
  final String _colMessageType = "Message_Type";
  final String _colMessageDate = "Message_Date";
  final String _colMessageTime = "Message_Time";
  final String _colMessageHolder = "Message_Holder";

  // Create Singleton Objects(Only Created once in the whole application)
  static late LocalDatabase _localStorageHelper =
      LocalDatabase._createInstance();
  static late Database _database;

  // Instantiate the obj
  LocalDatabase._createInstance(); //named constructor

  //For accessing the Singleton object
  factory LocalDatabase() {
    _localStorageHelper = LocalDatabase._createInstance();
    return _localStorageHelper;
  }

//getter for taking instance of database
  Future<Database> get database async {
    _database = await initializeDatabase();
    return _database;
  }

  //making a database
  Future<Database> initializeDatabase() async {
    // Get the directory path to store the database
    final String desiredPath = await getDatabasesPath();

    //creates a hidden folder for the databases
    final Directory newDirectory =
        await Directory(desiredPath + "/.Databases/").create();
    final String path = newDirectory.path + "/Spark_local_storage.db";

    // create the database
    final Database getDatabase = await openDatabase(path, version: 1);
    return getDatabase;
  }

  //creae table to store important data using username as primary key
  Future<void> createTableToStoreImportantData() async {
    Database db = await database;

    try {
      await db.execute(
          """CREATE TABLE $_importantTableData($_colUsername TEXT PRIMARY KEY, 
          $_colUserMail TEXT, $_colToken TEXT, $_colProfileImagePath TEXT,
           $_colProfileImageUrl TEXT, $_colAbout TEXT, $_colWallpaper TEXT,
            $_colNotification TEXT, $_colMobileNumber TEXT,
             $_colAccountCreationDate TEXT, $_colAccountCreationTime TEXT)""");
    } catch (e) {
      print("Error in createTableToStoreImportantData: ${e.toString()}");
    }
  }

//insert or update important data table
  Future<bool> insertOrUpdateDataForThisAccount({
    required String userName,
    required String userMail,
    required String userToken,
    required String userAbout,
    required String profileImagePath,
    required String profileImageUrl,
    String? userAccCreationDate,
    String? userAccCreationTime,
    String chatWallpaper = "",
    String purpose = "insert",
  }) async {
    try {
      final Database db = await database;

      if (purpose != 'insert') {
        final int updateResult = await db.rawUpdate(
            "UPDATE $_importantTableData SET $_colToken = '$userToken', $_colAbout = '$userAbout', $_colProfileImagePath = '$profileImagePath', $_colProfileImageUrl = '$profileImageUrl',  $_colUserMail = '$userMail', $_colAccountCreationDate = '$userAccCreationDate', $_colAccountCreationTime = '$userAccCreationTime' WHERE $_colUsername = '$userName'");

        print('Update Result is: $updateResult');
      } else {
        final Map<String, dynamic> _accountData = <String, dynamic>{};

        _accountData[_colUsername] = userName;
        _accountData[_colUserMail] = userMail;
        _accountData[_colToken] = userToken;
        _accountData[_colProfileImagePath] = profileImagePath;
        _accountData[_colProfileImageUrl] = profileImageUrl;
        _accountData[_colAbout] = userAbout;
        _accountData[_colWallpaper] = chatWallpaper;
        _accountData[_colMobileNumber] = '';
        _accountData[_colNotification] = '1';
        _accountData[_colAccountCreationDate] = userAccCreationDate;
        _accountData[_colAccountCreationTime] = userAccCreationTime;

        await db.insert(_importantTableData, _accountData);
      }

      return true;
    } catch (e) {
      print(
          'Error in Insert or Update operations of important data table: ${e.toString()}');
      return false;
    }
  }

  //create table to store messages for connections
  Future<void> createTableForEveryUser({required String username}) async {
    try {
      final Database db = await database;

      await db.execute(
          "CREATE TABLE $username($_colActualMessage TEXT, $_colMessageType TEXT, $_colMessageHolder TEXT, $_colMessageDate TEXT, $_colMessageTime TEXT, $_colProfileImagePath TEXT)");
    } catch (e) {
      print("Error in Creating Table For Every User: ${e.toString()}");
    }
  }

  //insert messages for conections
  Future<void> insertMessageInUserTable(
      {required String userName,
      required String actualMessage,
      required ChatMessageType chatMessageTypes,
      required MessageHolderType messageHolderType,
      required String messageDateLocal,
      required String messageTimeLocal,
      required String profilePic}) async {
    try {
      final Database db = await database;

      Map<String, String> tempMap = <String, String>{};

      tempMap[_colActualMessage] = actualMessage;
      tempMap[_colMessageType] = chatMessageTypes.toString();
      tempMap[_colMessageHolder] = messageHolderType.toString();
      tempMap[_colMessageDate] = messageDateLocal;
      tempMap[_colMessageTime] = messageTimeLocal;
      tempMap[_colProfileImagePath] = profilePic;

      final int rowAffected = await db.insert(userName, tempMap);
      print('Row Affected: $rowAffected');
    } catch (e) {
      print('Error in Insert Message In User Table: ${e.toString()}');
    }
  }

  //get any field data from the importantTableData using username
  Future<String?> getParticularFieldDataFromImportantTable(
      {required String userName,
      required GetFieldForImportantDataLocalDatabase getField}) async {
    try {
      final Database db = await database;

      final String? _particularSearchField = _getFieldName(getField);

      List<Map<String, Object?>> getResult = await db.rawQuery(
          "SELECT $_particularSearchField FROM $_importantTableData WHERE $_colUsername = '$userName'");

      return getResult[0].values.first.toString();
    } catch (e) {
      print(
          'Error in getParticularFieldDataFromImportantTable: ${e.toString()}');
      return null;
    }
  }

  ////get username for any user from the importantTableData using email
  Future<String?> getUserNameForAnyUser(String userEmail) async {
    try {
      final Database db = await database;

      List<Map<String, Object?>> result = await db.rawQuery(
          "SELECT $_colUsername FROM $_importantTableData WHERE $_colUserMail='$userEmail'");

      return result[0].values.first.toString();
    } catch (e) {
      print('error in getting current user\'s username');
      return null;
    }
  }

  //return field name
  String? _getFieldName(GetFieldForImportantDataLocalDatabase getField) {
    switch (getField) {
      case GetFieldForImportantDataLocalDatabase.userName:
        return _colUsername;
      case GetFieldForImportantDataLocalDatabase.userEmail:
        return _colUserMail;
      case GetFieldForImportantDataLocalDatabase.token:
        return _colToken;
      case GetFieldForImportantDataLocalDatabase.profileImagePath:
        return _colProfileImagePath;
      case GetFieldForImportantDataLocalDatabase.profileImageUrl:
        return _colProfileImageUrl;
      case GetFieldForImportantDataLocalDatabase.about:
        return _colAbout;
      case GetFieldForImportantDataLocalDatabase.wallPaper:
        return _colWallpaper;
      case GetFieldForImportantDataLocalDatabase.mobileNumber:
        return _colMobileNumber;
      case GetFieldForImportantDataLocalDatabase.notification:
        return _colNotification;
      case GetFieldForImportantDataLocalDatabase.accountCreationDate:
        return _colAccountCreationDate;
      case GetFieldForImportantDataLocalDatabase.accountCreationTime:
        return _colAccountCreationTime;
    }
  }

  //get all conections username and about
  Future<List<String>> extractAllConnectionsUsernames() async {
    try {
      final Database db = await database;

      List<String> allConnectionsUsernames = [];
      //extract all usernames excluding the current users's
      List<Map<String, Object?>> result = await db.rawQuery(
          """SELECT $_colUsername FROM $_importantTableData WHERE $_colUserMail != "${FirebaseAuth.instance.currentUser!.email.toString()}" """);

      for (int i = 0; i < result.length; i++) {
        allConnectionsUsernames.add(result[i].values.first.toString());
      }
      return allConnectionsUsernames;
    } catch (e) {
      print('error in getting all connectons usernames : ${e.toString()}');
      return [];
    }
  }

  //get all conections username and about
  Future<List<String>> extractAllUsernamesIncludingCurrentUser() async {
    try {
      final Database db = await database;

      List<String> allUsernames = [];
      //extract all usernames including the current users's
      List<Map<String, Object?>> result = await db
          .rawQuery("""SELECT $_colUsername FROM $_importantTableData """);

      for (int i = 0; i < result.length; i++) {
        allUsernames.add(result[i].values.first.toString());
      }
      return allUsernames;
    } catch (e) {
      print('error in getting all usernames : ${e.toString()}');
      return [];
    }
  }

  //get all conections username and about
  Future<List<ConnectionPrimaryInfo>> getConnectionPrimaryInfo() async {
    try {
      final Database db = await database;

      List<ConnectionPrimaryInfo> allConnectionsPrimaryInfo = [];
      //extract all usernames and about excluding the current users's
      List<Map<String, Object?>> result = await db.rawQuery(
          """SELECT $_colUsername, $_colAbout, $_colProfileImagePath FROM $_importantTableData WHERE $_colUserMail != "${FirebaseAuth.instance.currentUser!.email.toString()}" """);

      for (int i = 0; i < result.length; i++) {
        Map<String, dynamic> tempMap = result[i];
        allConnectionsPrimaryInfo.add(ConnectionPrimaryInfo.toJson(tempMap));
      }
      return allConnectionsPrimaryInfo;
    } catch (e) {
      print(
          'error in getting all connectons primary info from local : ${e.toString()}');
      return [];
    }
  }

  //get all prevoius messages for a particular connection
  Future<List<PreviousMessageStructure>> getAllPreviousMessages(
      String connectionUserName) async {
    try {
      final Database db = await database;

      final List<Map<String, Object?>> result =
          await db.rawQuery("SELECT * from $connectionUserName");

      List<PreviousMessageStructure> takePreviousMessages = [];

      for (int i = 0; i < result.length; i++) {
        Map<String, dynamic> tempMap = result[i];
        takePreviousMessages.add(PreviousMessageStructure.toJson(tempMap));
      }

      return takePreviousMessages;
    } catch (e) {
      print("Error in getAllPreviousMessages: ${e.toString}");
      return [];
    }
  }

  //get last sent messages from connections
  Future<List<LatestMessageFromConnection>>
      getLatestMessageFromConnections() async {
    try {
      final Database db = await database;

      List<LatestMessageFromConnection> lastestMessageFromConnections = [];

      List<Map<String, Object?>> getUsernames = await db.rawQuery(
          """SELECT $_colUsername FROM $_importantTableData WHERE $_colUserMail != "${FirebaseAuth.instance.currentUser!.email.toString()}" """);
      //WHERE $_colMessageHolder == "${MessageHolderType.connectedUsers.toString()}"
      if (getUsernames.isNotEmpty) {
        for (int i = 0; i < getUsernames.length; i++) {
          List<Map<String, Object?>> result = await db.rawQuery(
              """SELECT * FROM ${getUsernames[i].values.first.toString()} """);

          if (result.isNotEmpty) {
            Map<String, dynamic> tempMap = result[result.length - 1];
            lastestMessageFromConnections.add(
                LatestMessageFromConnection.toJson(
                    userName: getUsernames[i].values.first.toString(),
                    map: tempMap));
          }
        }
      }

      return lastestMessageFromConnections;
    } catch (e) {
      print(
          'error in getting last messages from connections : ${e.toString()}');
      return [];
    }
  }

  // Table for call log
  Future<bool> createTableForCallLogs() async {
    try {
      final Database db = await database;

      await db.execute(
          """CREATE TABLE $_callLogData($_colCallLogUsername Text, $_colCallLogProfilePic TEXT, $_colCallLogDateTime TEXT, $_colCallLogIspicked TEXT, $_colCallLogIsCaller TEXT )""");
      return true;
    } catch (e) {
      print(
          "Error in Local Storage Table creation For call logs: ${e.toString()}");
      return false;
    }
  }

  /// Insert data in call logs Table
  Future<bool> insertDataInCallLogsTable(
      {required String username,
      required String dateTime,
      required String profilePic,
      required bool isCaller,
      required bool isPicked}) async {
    try {
      final Database db = await database;
      final Map<String, dynamic> _callLogMap = <String, dynamic>{};

      _callLogMap[_colCallLogUsername] = username;
      _callLogMap[_colCallLogDateTime] = dateTime;
      _callLogMap[_colCallLogProfilePic] = profilePic;
       _callLogMap[_colCallLogIsCaller] = isCaller.toString();
      _callLogMap[_colCallLogIspicked] = isPicked.toString();

      await db.insert(_callLogData, _callLogMap);

      return true;
    } catch (e) {
      print("Error: call logs Table Data insertion Error: ${e.toString()}");
      return false;
    }
  }

  //get call logs
  Future<List<CallLog>> getCallLogs() async {
    try {
      final Database db = await database;

      List<CallLog> takeCallLogs = [];

    final List<Map<String, Object?>> result =
          await db.rawQuery("SELECT * from $_callLogData");

      if (result.isNotEmpty) {
        for (int i = 0; i < result.length; i++) {
          Map<String, dynamic> tempMap = result[i];
          takeCallLogs.add(CallLog.toJson(tempMap));
        }
      }

      return takeCallLogs;
    } catch (e) {
      print("Error in getting call logs: ${e.toString()}");
      return [];
    }
  }















//   Future<void> insertProfilePictureInImportant(
//       {required String imagePath,
//       required String imageUrl,
//       required String mail}) async {
//     try {
//       final Database db = await this.database;

//       final int result = await db.rawUpdate(
//           """UPDATE $_allImportantDataStore 3SET $_colProfileImagePath = "$imagePath", $_colProfileImageUrl = "$imageUrl" WHERE $_colAccountUserMail = "$mail" """);

//       result == 1
//           ? print("Success: New Profile Picture Update Successful")
//           : print("Failed: New Profile Picture Update Fail");
//     } catch (e) {
//       print("Insert Profile Picture to Local Database Error: ${e.toString()}");
//     }
//   }

// //   Future<void> updateImportantTableExtraData(
// //       {String userName = "",
// //       String userMail = "",
// //       bool allUpdate = false,
// //       required ExtraImportant extraImportant,
// //       required String updatedVal}) async {
// //     try {
// //       final Database db = await this.database;

// //       if (!allUpdate && userName == "")
// //         userName =
// //             await extractImportantDataFromThatAccount(userMail: userMail);

// //       final String _query =
// //           identifyExtraImportantData(extraImportant: extraImportant);

// //       int result;

// //       if (allUpdate) {
// //         result = await db.rawUpdate(
// //             """UPDATE $_allImportantDataStore SET $_query = "$updatedVal" """);
// //       } else {
// //         result = await db.rawUpdate(
// //             """UPDATE $_allImportantDataStore SET $_query = "$updatedVal" WHERE $_colAccountUserName = "$userName" """);
// //       }

// //       print(
// //           "Update Important Data Store Result : ${result > 0 ? true : false}");
// //     } catch (e) {
// //       print("Update Important Table Extra Data Error: ${e.toString()}");
// //     }
// //   }

// //   Future<dynamic> extractImportantTableData({
// //     String userName = "",
// //     String userMail = "",
// //     required ExtraImportant extraImportant,
// //   }) async {
// //     try {
// //       final Database db = await this.database;

// //       if (userName == "")
// //         userName =
// //             await extractImportantDataFromThatAccount(userMail: userMail);

// //       final String _query =
// //           identifyExtraImportantData(extraImportant: extraImportant);

// //       final List<Map<String, Object?>> result = await db.rawQuery(
// //           """SELECT $_query FROM $_allImportantDataStore WHERE $_colAccountUserName = "$userName" """);

// //       final String take = result[0][_query]!.toString();

// //       if (take == "1" || take == "0") return take == "1" ? true : false;

// //       return take;
// //     } catch (e) {
// //       print("Extract Important Table Data: ${e.toString()}");
// //     }
// //   }

// //   /// Actually Doing Update as for delete, entire row will be rejected from table
// //   Future<void> deleteParticularUpdatedImportantData({
// //     required ExtraImportant extraImportant,
// //     required String shouldBeDeleted,
// //     bool allUpdateStatus = true,
// //     String userName = "",
// //   }) async {
// //     try {
// //       final Database db = await this.database;

// //       final String query =
// //           identifyExtraImportantData(extraImportant: extraImportant);

// //       int result;

// //       if (allUpdateStatus)
// //         result = await db.rawUpdate(
// //             """UPDATE $_allImportantDataStore SET $query = "" WHERE $query = "$shouldBeDeleted" """);
// //       else
// //         result = await db.rawUpdate(
// //             """UPDATE $_allImportantDataStore SET $query = "" WHERE $query = "$shouldBeDeleted" AND $_colAccountUserName = "$userName" """);

// //       print(result > 0
// //           ? "Particular Important Data Deletion Successful"
// //           : "Error: Particular Data Deletion Failed");
// //     } catch (e) {
// //       print(
// //           "Error: Delete Particular Updated Important Data Error: ${e.toString()}");
// //     }
// //   }

// //   String identifyExtraImportantData({required ExtraImportant extraImportant}) {
// //     switch (extraImportant) {
// //       case ExtraImportant.ChatWallpaper:
// //         return this._colChatWallPaper;

// //       case ExtraImportant.BGNStatus:
// //         return this._colParticularBGNStatus;

// //       case ExtraImportant.FGNStatus:
// //         return this._colParticularFGNStatus;

// //       case ExtraImportant.MobileNumber:
// //         return this._colMobileNumber;

// //       case ExtraImportant.CreationDate:
// //         return this._colCreationDate;

// //       case ExtraImportant.CreationTime:
// //         return this._colCreationTime;

// //       case ExtraImportant.About:
// //         return this._colAbout;
// //     }
// //   }

// //   Future<String> extractImportantDataFromThatAccount(
// //       {String userName = "", String userMail = ""}) async {
// //     final Database db = await this.database;

// //     List<Map<String, Object?>> result = [];

// //     if (userMail != "")
// //       result = await db.rawQuery(
// //           """SELECT $_colAccountUserName FROM $_allImportantDataStore WHERE $_colAccountUserMail = "$userMail" """);
// //     else
// //       result = await db.rawQuery(
// //           """SELECT $_colAccountUserMail FROM $_allImportantDataStore WHERE $_colAccountUserName = "$userName" """);

// //     return result[0].values.first!.toString();
// //   }

// //   Future<Map<String, String>>
// //       extractUserNameAndProfilePicFromImportant() async {
// //     final Database db = await this.database;

// //     final List<Map<String, Object?>> result = await db.rawQuery(
// //         """SELECT $_colAccountUserName,$_colProfileImagePath FROM $_allImportantDataStore""");

// //     final Map<String, String> tempMap = Map<String, String>();

// //     result.forEach((userData) {
// //       tempMap[userData[_colAccountUserName].toString()] =
// //           userData[_colProfileImagePath].toString();
// //     });

// //     return tempMap;
// //   }

// //   Future<String> extractToken(
// //       {String userMail = "", String userName = ""}) async {
// //     final Database db = await this.database;

// //     List<Map<String, Object?>> result;

// //     if (userMail != "")
// //       result = await db.rawQuery(
// //           """SELECT $_colToken FROM $_allImportantDataStore WHERE $_colAccountUserMail = "$userMail" """);
// //     else
// //       result = await db.rawQuery(
// //           """SELECT $_colToken FROM $_allImportantDataStore WHERE $_colAccountUserName = "$userName" """);

// //     return _encryptionMaker.decryptionMaker(result[0].values.first.toString());
// //   }

// //   Future<String> extractProfileImageLocalPath(
// //       {String userMail = "", String userName = ""}) async {
// //     final Database db = await this.database;

// //     List<Map<String, Object?>> result;

// //     if (userMail != "")
// //       result = await db.rawQuery(
// //           """SELECT $_colProfileImagePath FROM $_allImportantDataStore WHERE $_colAccountUserMail = "$userMail" """);
// //     else
// //       result = await db.rawQuery(
// //           """SELECT $_colProfileImagePath FROM $_allImportantDataStore WHERE $_colAccountUserName = "$userName" """);

// //     return result[0].values.first == null
// //         ? ""
// //         : result[0].values.first.toString();
// //   }

// //   Future<String> extractProfilePicUrl({required String userName}) async {
// //     final Database db = await this.database;

// //     final List<Map<String, Object?>>? result = await db.rawQuery(
// //         """SELECT $_colProfileImageUrl FROM $_allImportantDataStore WHERE $_colAccountUserName = "$userName" """);

// //     if (result != null) return result[0].values.first.toString();
// //     return "";
// //   }

// //   Future<List<Map<String, Object?>>> extractAllUsersName(
// //       {bool thisAccountAllowed = false}) async {
// //     try {
// //       Database db = await this.database;
// //       List<Map<String, Object?>> result = [];

// //       if (!thisAccountAllowed)
// //         result = await db.rawQuery(
// //             """SELECT $_colAccountUserName FROM $_allImportantDataStore WHERE $_colAccountUserMail != "${FirebaseAuth.instance.currentUser!.email.toString()}" """);
// //       else
// //         result = await db.rawQuery(
// //             """SELECT $_colAccountUserName FROM $_allImportantDataStore""");
// //       return result;
// //     } catch (e) {
// //       print("User Name Extraction Error: ${e.toString()}");
// //       return [];
// //     }
// //   }

// //   /// Extract Status from Table Name
// //   Future<List<Map<String, dynamic>>?>? extractActivityForParticularUserName(
// //       String tableName) async {
// //     try {
// //       final Database db = await this.database;
// //       final List<Map<String, Object?>>? tables =
// //           await db.rawQuery("SELECT * FROM ${tableName}_status");
// //       return tables == null ? [] : tables;
// //     } catch (e) {
// //       print("Extract USer Name Activity Exception: ${e.toString()}");
// //       return null;
// //     }
// //   }

// //   /// Delete Particular Activity record From Activity Container
// //   Future<void> deleteParticularActivity(
// //       {required String tableName, required String activity}) async {
// //     try {
// //       final Database db = await this.database;

// //       print("Here in Delete Particular Activity: $tableName   $activity");

// //       final int result = await db.rawDelete(
// //           """DELETE FROM ${tableName}_status WHERE $_colActivity = "$activity" """);

// //       print("Deletion Result: $result");
// //     } catch (e) {
// //       print("Delete Activity From Database Error: ${e.toString()}");
// //     }
// //   }

// //   /// Update Particular Activity
// //   Future<void> updateTableActivity(
// //       {required String tableName,
// //       required String oldActivity,
// //       required String newAddition}) async {
// //     try {
// //       final Database db = await this.database;

// //       final int _updateResult = await db.rawUpdate(
// //           """UPDATE ${tableName}_status SET $_colActivity = "$oldActivity[[[question]]]$newAddition" WHERE $_colActivity = "$oldActivity" """);

// //       print("Update Result is: $_updateResult");
// //     } catch (e) {
// //       print("Update Table Activity Error: ${e.toString()}");
// //     }
// //   }

// //   /// For Debugging Purpose
// //   Future<void> showParticularUserAllActivity(
// //       {required String tableName}) async {
// //     try {
// //       final Database db = await this.database;
// //       var take = await db.rawQuery("""SELECT * FROM ${tableName}_status""");

// //       print("All Activity: $take");
// //     } catch (e) {
// //       print("showParticularUserAllActivity Error: ${e.toString()}");
// //     }
// //   }

// //   /// Count Total Statuses for particular Table Name
// //   Future<int> countTotalActivitiesForParticularUserName(
// //       String tableName) async {
// //     final Database db = await this.database;
// //     final List<Map<String, Object?>> countTotalStatus =
// //         await db.rawQuery("""SELECT COUNT(*) FROM ${tableName}_status""");

// //     return int.parse(countTotalStatus[0].values.first.toString());
// //   }

// //   /// All Chat Messages Manipulation will done here
// //   /// Message Store and customization following by the following functions
// //   /// Table Name same as User Name

// //   /// For make a table
// //   Future<bool> createTableForUserName(String tableName) async {
// //     Database db = await this.database;
// //     try {
// //       await db.execute(
// //           """CREATE TABLE $tableName($_colMessages TEXT, $_colReferences INTEGER, $_colMediaType TEXT, $_colDate TEXT, $_colTime TEXT)""");
// //       return true;
// //     } catch (e) {
// //       print(
// //           "Error in Local Storage Create Table For User Name: ${e.toString()}");
// //       return false;
// //     }
// //   }

// //   /// Count total Messages for particular Table Name
// //   Future<int> _countTotalMessagesUnderATable(String _tableName) async {
// //     final Database db = await this.database;

// //     final List<Map<String, Object?>> countTotalMessagesWithOneAdditionalData =
// //         await db.rawQuery("""SELECT COUNT(*) FROM $_tableName""");

// //     return int.parse(
// //         countTotalMessagesWithOneAdditionalData[0].values.first.toString());
// //   }

// //   /// Insert New Messages to Table
// //   Future<int> insertNewMessages(String _tableName, String _newMessage,
// //       MediaTypes _currMediaType, int _ref, String _time,
// //       {String? incomingMessageDate}) async {
// //     Database db = await this.database; // DB Reference
// //     Map<String, dynamic> _helperMap =
// //         Map<String, dynamic>(); // Map to insert data

// //     print("Incoming Date: $incomingMessageDate");

// //     /// Current Date
// //     DateTime now = incomingMessageDate == null
// //         ? DateTime.now()
// //         : DateTime.parse(incomingMessageDate);
// //     DateFormat formatter = DateFormat("dd-MM-yyyy");
// //     String _dateIS = formatter.format(now);

// //     /// Insert Data to Map
// //     _helperMap[_colMessages] = _newMessage;
// //     _helperMap[_colReferences] = _ref;
// //     _helperMap[_colMediaType] = _currMediaType.toString();
// //     _helperMap[_colDate] = _dateIS;
// //     _helperMap[_colTime] = _time;

// //     /// Result Insert to DB
// //     var result = await db.insert(_tableName, _helperMap);
// //     print(result);

// //     return result;
// //   }

// //   /// Extract Message from table
// //   Future<List<Map<String, dynamic>>> extractMessageData(
// //       String _tableName) async {
// //     final Database db = await this.database; // DB Reference

// //     final List<Map<String, Object?>> result = await db.rawQuery(
// //         "SELECT $_colMessages, $_colTime, $_colReferences, $_colMediaType, $_colDate FROM $_tableName");

// //     return result;
// //   }

// //   /// Delete Particular Message
// //   Future<bool> deleteChatMessage(
// //     String _tableName, {
// //     required String message,
// //     String? time,
// //     int? reference,
// //     required String mediaType,
// //     multipleMediaDeletion = false,
// //   }) async {
// //     try {
// //       final Database db = await this.database;

// //       print("Message: $message");
// //       print("Time: $time");
// //       print("Reference: $reference");
// //       print("MediaType: $mediaType");

// //       int result;

// //       if (multipleMediaDeletion)
// //         result = await db.rawDelete(
// //             """DELETE FROM $_tableName WHERE $_colMessages = "${_encryptionMaker.encryptionMaker(message)}" AND $_colMediaType = "$mediaType" """);
// //       else
// //         result = await db.rawDelete(
// //             """DELETE FROM $_tableName WHERE $_colMessages = "${_encryptionMaker.encryptionMaker(message)}" AND $_colTime = "${_encryptionMaker.encryptionMaker(time!)}" AND $_colReferences = $reference AND $_colMediaType = "$mediaType" """);

// //       if (result == 0) {
// //         print("Result: $result");
// //         return false;
// //       } else {
// //         print("Delete From Chat Message Result: $result");
// //         return true;
// //       }
// //     } catch (e) {
// //       print("Delete From Chat Message Error: ${e.toString()}");
// //       return false;
// //     }
// //   }

// //   /// Fetch Latest Message
// //   Future<Map<String, String>?> fetchLatestMessage(String _tableName) async {
// //     final Database db = await this.database;

// //     final int totalMessages = await _countTotalMessagesUnderATable(_tableName);

// //     if (totalMessages == 0) return null;

// //     final List<Map<String, Object?>>? result = await db.rawQuery(
// //         """SELECT $_colMessages, $_colMediaType, $_colTime, $_colDate FROM $_tableName LIMIT 1 OFFSET ${totalMessages - 1}""");

// //     print("Result is: $result");
// //     final Map<String, String> map = Map<String, String>();

// //     if (result != null && result.length > 0) {
// //       final String _time = _encryptionMaker
// //           .decryptionMaker(result[0][_colTime].toString())
// //           .split("+")[0];

// //       print("Now: $_time");

// //       map.addAll({
// //         result[0][_colMessages].toString():
// //             "${_encryptionMaker.encryptionMaker(_time)}+${result[0][_colMediaType]}+localDb+${result[0][_colDate]}",
// //       });
// //     }

// //     print("Map is: $map");

// //     return map;
// //   }

// //   Future<List<Map<String, Object?>>> fetchAllHistoryData(
// //       String _tableName) async {
// //     try {
// //       final Database db = await this.database;

// //       final List<Map<String, Object?>> result = await db.rawQuery(
// //           """SELECT $_colMessages, $_colReferences, $_colMediaType, $_colTime, $_colDate FROM $_tableName""");

// //       return result;
// //     } catch (e) {
// //       print("Fetch all History Data Error: ${e.toString()}");
// //       return [];
// //     }
// //   }

// //   Future<List<Map<String, String>>> extractParticularChatMediaByRequirement(
// //       {required String tableName, required MediaTypes mediaType}) async {
// //     try {
// //       final Database db = await this.database;

// //       List<Map<String, Object?>> result;

// //       if (mediaType != MediaTypes.Video)
// //         result = await db.rawQuery(
// //             """SELECT $_colMessages FROM $tableName WHERE $_colMediaType= "$mediaType" """);
// //       else
// //         result = await db.rawQuery(
// //             """SELECT $_colMessages, $_colTime FROM $tableName WHERE $_colMediaType= "$mediaType" """);

// //       final List<Map<String, String>> _container = [];

// //       result.reversed.toList().forEach((element) async {
// //         int _fileSize = await File(_encryptionMaker
// //                 .decryptionMaker(element.values.first.toString()))
// //             .length();

// //         print(
// //             "PAth now: ${_encryptionMaker.decryptionMaker(element[_colMessages].toString())}");

// //         _container.add({
// //           mediaType != MediaTypes.Video
// //                   ? _encryptionMaker
// //                       .decryptionMaker(element[_colMessages].toString())
// //                   : "${_encryptionMaker.decryptionMaker(element[_colMessages].toString())}+${_encryptionMaker.decryptionMaker(element[_colTime].toString()).split("+")[2]}":
// //               "${_formatBytes(_fileSize.toDouble())}",
// //         });
// //       });

// //       return _container;
// //     } catch (e) {
// //       print("Error: Extract Particular Chat All Media Error: ${e.toString()}");
// //       return [];
// //     }
// //   }

// //   /// Convert bytes of kb, mb, gb
// //   String _formatBytes(double bytes) {
// //     double kb = bytes / 1000;

// //     if (kb >= 1024.00) {
// //       double mb = bytes / (1000 * 1024);
// //       if (mb >= 1024.00)
// //         return "${(bytes / (1000 * 1024 * 1024)).toStringAsFixed(1)} gb";
// //       else
// //         return "${mb.toStringAsFixed(1)} mb";
// //     } else
// //       return "${kb.toStringAsFixed(1)} kb";
// //   }

// //   /// For Multiple Connection Media Send, store links in the following containing table
// //   /// for 24 hrs after send message.... These links will delete after 24hrs
// //   Future<void> createTableForRemainingLinks() async {
// //     final Database db = await this.database;

// //     await db.transaction((txn) async {
// //       return await txn.rawQuery(
// //           """CREATE TABLE $_allRemainingLinksToDeleteFromFirebaseStorage($_colLinks TEXT, $_colTime TEXT)""");
// //     });
// //   }

// //   Future<void> insertNewLinkInLinkRemainingTable({required String link}) async {
// //     try {
// //       final Database db = await this.database;

// //       final Map<String, String> map = Map<String, String>();
// //       map[_colLinks] = _encryptionMaker.encryptionMaker(link);
// //       map[_colTime] =
// //           _encryptionMaker.encryptionMaker(DateTime.now().toString());

// //       int result =
// //           await db.insert(_allRemainingLinksToDeleteFromFirebaseStorage, map);

// //       print("Insert New Link Result : $result");
// //     } catch (e) {
// //       print("Insert Remaining Links Error: ${e.toString()}");
// //       await createTableForRemainingLinks();
// //       await insertNewLinkInLinkRemainingTable(link: link);
// //     }
// //   }

// //   /// For Debugging purpose
// //   Future<void> showAll() async {
// //     final Database db = await this.database;

// //     final List<Map<String, Object?>> result = await db.rawQuery(
// //         """SELECT * from $_allRemainingLinksToDeleteFromFirebaseStorage""");

// //     print("Storage Result is: $result");
// //   }

// //   /// Remaining Links extract to delete
// //   Future<Map<String, String>> extractRemainingLinks() async {
// //     try {
// //       final Database db = await this.database;

// //       final List<Map<String, Object?>> result = await db.rawQuery(
// //           """SELECT * FROM $_allRemainingLinksToDeleteFromFirebaseStorage""");

// //       final Map<String, String> map = Map<String, String>();

// //       result.forEach((everyResult) {
// //         map.addAll({
// //           _encryptionMaker.decryptionMaker(everyResult[_colLinks].toString()):
// //               _encryptionMaker
// //                   .decryptionMaker(everyResult[_colTime].toString()),
// //         });
// //       });

// //       return map;
// //     } catch (e) {
// //       print("Extract Links Error: ${e.toString()}");
// //       return Map<String, String>();
// //     }
// //   }

// //   Future<void> deleteRemainingLinksFromLocalStore(
// //       {required String link}) async {
// //     try {
// //       final Database db = await this.database;

// //       await db.rawDelete(
// //           """DELETE FROM $_allRemainingLinksToDeleteFromFirebaseStorage WHERE $_colLinks = "${_encryptionMaker.encryptionMaker(link)}" """);
// //     } catch (e) {
// //       print("Remaining Links Deletion Exception: ${e.toString()}");
// //     }
// //   }

// //   Future<void> deleteTheExistingDatabase() async {
// //     try {
// //       final Directory? directory = await getExternalStorageDirectory();
// //       print("Directory Path: ${directory!.path}");

// //       final Directory newDirectory =
// //           await Directory(directory.path + "/.Databases/").create();
// //       final String path = newDirectory.path + "/generation_local_storage.db";

// //       // delete the database
// //       await deleteDatabase(path);

// //       print("After Delete Database");
// //     } catch (e) {
// //       print("Delete Database Exception: ${e.toString()}");
// //     }
// //   }

// //   /// For Notification Controlling Data Store
// //   /// All Notification Settings Will store here
// //   /// For Future Use
// //   Future<void> createTableForNotificationGlobalConfig() async {
// //     final Database db = await this.database;

// //     try {
// //       await db.execute(
// //           """CREATE TABLE $_notificationGlobalConfig($_colBgNotify INTEGER, $_colFGNotify INTEGER, $_colRemoveBirthNotification INTEGER, $_colAnonymousRemoveNotification INTEGER)""");
// //     } catch (e) {
// //       print("Notification Table Make Error: ${e.toString()}");
// //     }
// //   }

// //   Future<void> insertDataForNotificationGlobalConfig() async {
// //     final Database db = await this.database;

// //     try {
// //       final Map<String, Object> map = Map<String, Object>();

// //       map[_colBgNotify] = 1;
// //       map[_colFGNotify] = 1;
// //       map[_colRemoveBirthNotification] = 0;
// //       map[_colAnonymousRemoveNotification] = 0;

// //       await db.insert(_notificationGlobalConfig, map);
// //     } catch (e) {
// //       print("Notification Global Config Data Insertion Error: ${e.toString()}");
// //     }
// //   }

// //   Future<void> updateDataForNotificationGlobalConfig(
// //       {required NConfigTypes nConfigTypes,
// //       required bool updatedNotifyCondition}) async {
// //     final Database db = await this.database;

// //     try {
// //       final String _argumentNotify = _findBestMatch(nConfigTypes);

// //       await db.rawUpdate(
// //           """UPDATE $_notificationGlobalConfig SET $_argumentNotify = ${updatedNotifyCondition ? 1 : 0}""");
// //     } catch (e) {
// //       print(
// //           "Exception: Update in Notification Global Config Error: ${e.toString()}");
// //     }
// //   }

// //   String _findBestMatch(NConfigTypes nConfigTypes) {
// //     switch (nConfigTypes) {
// //       case NConfigTypes.BgNotification:
// //         return this._colBgNotify;

// //       case NConfigTypes.FGNotification:
// //         return this._colFGNotify;

// //       case NConfigTypes.RemoveBirthNotification:
// //         return this._colRemoveBirthNotification;

// //       case NConfigTypes.RemoveAnonymousNotification:
// //         return this._colAnonymousRemoveNotification;
// //     }
// //   }

// //   Future<bool> extractDataForNotificationConfigTable(
// //       {required NConfigTypes nConfigTypes}) async {
// //     try {
// //       final Database db = await this.database;

// //       final String _argument = _findBestMatch(nConfigTypes);

// //       final List<Map<String, Object?>> result = await db
// //           .rawQuery("""SELECT $_argument FROM $_notificationGlobalConfig""");

// //       print("Notification Extract Result: $result");

// //       return result[0].values.first.toString() == "1" ? true : false;
// //     } catch (e) {
// //       print(
// //           "Error: Extract Data From Notification Table Error: ${e.toString()}");
// //       return true;
// //     }
// //   }

// //   /// For Call Log Data Management

// //   Future<void> createTableForConnectionCallLogs(String tableName) async {
// //     try {
// //       final Database db = await this.database;

// //       await db.rawQuery(
// //           """CREATE TABLE ${tableName}_callHistory($_colCallDate TEXT, $_colCallTime TEXT, $_colCallType TEXT)""");
// //     } catch (e) {
// //       print("Error: Create Table For Call Logs: ${e.toString()}");
// //     }
// //   }

// //   Future<void> insertDataForCallLog(String tableName,
// //       {required String callDate,
// //       required String callTime,
// //       CallTypes callTypes = CallTypes.AudioCall}) async {
// //     try {
// //       final Database db = await this.database;

// //       final Map<String, Object> tempMap = Map<String, Object>();

// //       tempMap[_colCallDate] = callDate;
// //       tempMap[_colCallTime] = callTime;
// //       tempMap[_colCallType] = callTypes.toString();

// //       final int result = await db.insert("${tableName}_callHistory", tempMap);

// //       print("Call Log data insertion Result: $result ");
// //     } catch (e) {
// //       print("Error: Insert data in Call Log Error: ${e.toString()}");
// //     }
// //   }

// //   Future<dynamic> countOrExtractTotalCallLogs(String tableName,
// //       {String purpose = "COUNT"}) async {
// //     try {
// //       final Database db = await this.database;

// //       final List<Map<String, Object?>>? result = await db.rawQuery(
// //           """SELECT ${purpose == "COUNT" ? "COUNT(*)" : "*"} FROM ${tableName}_callHistory""");

// //       print("Result is: $result");

// //       if (purpose == "COUNT")
// //         return result == null
// //             ? 0
// //             : int.parse(result[0].values.first.toString());

// //       return result == null ? [] : result;
// //     } catch (e) {
// //       print("Error: Count total Call Logs Error: ${e.toString()}");
// //       return purpose == "COUNT" ? 0 : [];
// //     }
// //   }

// //   Future<void> deleteParticularConnectionAllCallLogs(String tableName) async {
// //     try {
// //       final Database db = await this.database;

// //       final int result =
// //           await db.rawDelete("""DELETE FROM "${tableName}_callHistory" """);

// //       print("Call Log Deletion Result is: $result");
// //     } catch (e) {
// //       print("Error: Delete Particular Call Log: ${e.toString()}");
// //     }
// //   }
// // }
}
