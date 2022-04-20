import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:spark/backend/firebase/online_database_management/cloud_data_management.dart';
import 'package:spark/backend/sqlite_management/local_database_management.dart';
import 'package:spark/frontend/main_screens/main_screen.dart';
import 'package:spark/global_uses/constants.dart';
import 'package:spark/global_uses/alert.dart';
import 'package:image_picker/image_picker.dart';

class TakePrimaryUserData extends StatefulWidget {
  const TakePrimaryUserData({Key? key}) : super(key: key);

  @override
  _TakePrimaryUserDataState createState() => _TakePrimaryUserDataState();
}

class _TakePrimaryUserDataState extends State<TakePrimaryUserData> {
  bool _isLoading = false;
  String? profilePic;

  final CloudStoreDataManagement _cloudStoreDataManagement =
      CloudStoreDataManagement();

  final LocalDatabase _localDatabase = LocalDatabase();

  final TextEditingController _username =
      TextEditingController(); //input of the username field

  final TextEditingController _userAbout =
      TextEditingController(); //input of the userAbout field

  final GlobalKey<FormState> _userPrimaryInformationFormKey =
      GlobalKey<FormState>(); //uniquely identify the login elements

  @override
  Widget build(BuildContext context) {
     return Scaffold(
        backgroundColor: kWhite,
        body: LoadingOverlay(
     isLoading: _isLoading,
     child: Padding(
       padding: const EdgeInsets.only(top:12.0),
       child: ListView(
         shrinkWrap: true,
         children: <Widget>[
           _heading(),
           _userPrimaryInformationform(),
           _saveUserPrimaryInformation()
         ],
       ),
     ),
        ),
      );
    
  }

//heading of the user entry screen
  Widget _heading() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 70.0, left: 30.0),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('Almost there',
            style: TextStyle(
                color: kBlack,
                fontSize: 30.0,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700)),
        Text('Please fill in the input below',
            style: TextStyle(
                color: kGrey,
                fontSize: 14.0,
                letterSpacing: 1.0,
                fontStyle: FontStyle.italic)),
      ]),
    );
  }

//some common textformField
  Widget _commonTextFormField(
      {required String hintText,
      required String labelText,
      required TextInputType textInputType,
      required String? Function(String?)? validator,
      required TextEditingController textEditingController}) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 35.0),
        child: TextFormField(
            keyboardType: textInputType,
            controller: textEditingController,
            validator: validator,
            style: const TextStyle(color: kBlack, letterSpacing: 1.0),
            decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(10.0),
                errorStyle: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
                labelText: labelText,
                labelStyle: const TextStyle(
                    color: kBlack,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w500),
                hintText: hintText,
                hintStyle:
                    const TextStyle(color: Colors.grey, letterSpacing: 1.0),
                filled: true,
                fillColor: Colors.white38,
                enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                    borderSide: BorderSide(color: kPrimaryAppColor)),
                focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                    borderSide: BorderSide(color: kPrimaryAppColor)),
                errorBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                    borderSide: BorderSide(color: kPrimaryAppColor)),
                focusedErrorBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                    borderSide: BorderSide(color: kPrimaryAppColor)))));
  }

//new user entry form
  Widget _userPrimaryInformationform() {
    return Form(
      key: _userPrimaryInformationFormKey,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 30.0),
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  final XFile? pickedImage = await ImagePicker()
                      .pickImage(source: ImageSource.gallery, imageQuality: 50);
                  if (pickedImage != null) {
                    setState(() {
                      profilePic = pickedImage.path;
                    });
                  }
                },
                child: profilePic == null
                    ? CircleAvatar(
                        radius: 50,
                        backgroundColor: kPrimaryAppColor,
                        child: Image.asset(
                          "assets/images/add_pic.png",
                          height: 80.0,
                          width: 60.0,
                        ))
                    : CircleAvatar(
                        radius: 50,
                        backgroundImage: FileImage(File(profilePic!)),
                      ),
              ),
            ),
          ),
          _commonTextFormField(
              hintText: 'enter username',
              labelText: 'Username',
              textInputType: TextInputType.text,
              validator: (inputUserName) {
                //Regular expression
                final RegExp _messageRegex = RegExp(r'[a-zA-Z0-9]');
                if (inputUserName!.length < 6) {
                  return 'username must have atleast 6 characters';
                } else if (inputUserName.contains(' ') ||
                    inputUserName.contains('@')) {
                  return 'space or @ not allowed';
                } else if (!_messageRegex.hasMatch(inputUserName)) {
                  return 'Emoji not supported';
                }
                return null;
              },
              textEditingController: _username),
          _commonTextFormField(
              hintText: 'enter about',
              labelText: 'About',
              textInputType: TextInputType.text,
              validator: (String? inputValue) {
                if (inputValue!.length < 6) {
                  return 'About must be atleast 6 characters';
                }
                return null;
              },
              textEditingController: _userAbout),
        ],
      ),
    );
  }

  //button to save user primary info to firestore
  Widget _saveUserPrimaryInformation() {
    return Padding(
      padding: const EdgeInsets.only(
          top: 12.0, bottom: 10.0, left: 100.0, right: 100.0),
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(100.0, 50.0),
              primary: kPrimaryAppColor,
              elevation: 0.0,
              padding:
                  const EdgeInsets.symmetric(vertical: 7.0, horizontal: 20.0),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(40.0)))),
          child: const Text('Save',
              style: TextStyle(
                  color: kWhite, fontSize: 16.0, fontWeight: FontWeight.w800)),
          onPressed: () async {
            if (_userPrimaryInformationFormKey.currentState!.validate()) {
              SystemChannels.textInput
                  .invokeMethod('TextInput.hide'); //hides the keyboard

              profilePic == null
                  ? showPlatformToast(
                      child: const Text(
                        'Please, select profile picture',
                        style: TextStyle(color: kBlack, fontSize: 20.0),
                      ),
                      context: context)
                  : _onpressedActionOfSaveInfoButton();
            }
          }),
    );
  }

  //
  void _onpressedActionOfSaveInfoButton() async {
    try {
      // display loading overlay
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      String msg = '';

      ///call [checkUserPresence] and pass username
      final bool canRegisterNewUser = await _cloudStoreDataManagement
          .checkUsernamePresence(username: _username.text);

      //user name already exists
      if (!canRegisterNewUser) {
        msg = 'Username already present';
         //display appropriate alert message
       alert(title: msg, context: context);
       Timer(const Duration(seconds: 2), () => Navigator.pop(context));
       SystemChannels.textInput.invokeMethod('TextInput.hide');
     
      }

      ///if username does not exist call [registerNewUser]

      else {
        //upload profile pic file and get the remote file path
        final String? downloadedImagePath = await _cloudStoreDataManagement
            .uploadMediaToStorage(File(profilePic!), reference: 'profilePics/');

        print('uploaded image path : $downloadedImagePath');

        final bool _userEntryResponse =
            await _cloudStoreDataManagement.registerNewUser(
                username: _username.text,
                userAbout: _userAbout.text,
                userEmail: FirebaseAuth.instance.currentUser!.email.toString(),
                profilePic: downloadedImagePath!);

        ///if user data entry is successful, navigate to [Homepage]
        if (_userEntryResponse) {

          //get account creation date,time and device token from cloud firestore
          final Map<String, dynamic> _getImportantDataFromFireStore =
              await _cloudStoreDataManagement.getDataFromCloudFireStore(
                  email: FirebaseAuth.instance.currentUser!.email.toString());
        
          ///calling [LocalDatabase] methods to create and insert new user data into a table

          //creates table for important primary user data
          await _localDatabase.createTableToStoreImportantData();
          //creates call logs table
          await _localDatabase.createTableForCallLogs();

          //inserts data into the table
          await _localDatabase.insertOrUpdateDataForThisAccount(
              userName: _username.text,
              userMail: FirebaseAuth.instance.currentUser!.email.toString(),
              userToken: _getImportantDataFromFireStore['token'],
              userAbout: _userAbout.text,
              userAccCreationDate: _getImportantDataFromFireStore['date'],
              userAccCreationTime: _getImportantDataFromFireStore['time'],
              profileImagePath: profilePic!,
              profileImageUrl: downloadedImagePath);

          //navigate to MainScreen
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false);
        } else {
          msg = 'user data entry not successful';
           //display appropriate alert message
         alert(title: msg, context: context);
         Timer(const Duration(seconds: 2), () => Navigator.pop(context));
         SystemChannels.textInput.invokeMethod('TextInput.hide');
     
        }
      }


      //remove laoding overlay
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("error in saving user primary info : ${e.toString}");
    }
  }
}
