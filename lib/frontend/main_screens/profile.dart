import 'dart:async';
import 'dart:io';
import 'package:badges/badges.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:page_transition/page_transition.dart';
import 'package:spark/backend/firebase/online_database_management/cloud_data_management.dart';
import 'package:spark/backend/sqlite_management/local_database_management.dart';
import 'package:spark/frontend/preview/image_preview.dart';
import 'package:spark/global_uses/constants.dart';
import 'package:spark/global_uses/enum_generation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  String username = '';
  String? profilePic;
  String about = '';
  String userMail = '';
  String userToken = '';
  String acctCreationDate = '';
  String acctCreationTime = '';
  final LocalDatabase _localDatabase = LocalDatabase();
  final CloudStoreDataManagement _cloudStoreDataManagement =
      CloudStoreDataManagement();

//CHANGE PROFILE PICTURE
  void _changeProfilePic() async {
    try {
      //select new picture
      final XFile? pickedImage = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      if (pickedImage != null) {
        //upload file and get the remote file path
        final String? downloadedImagePath = await _cloudStoreDataManagement
            .uploadMediaToStorage(File(pickedImage.path),
                reference: 'profilePics/');

        //upload picture data including remote file path to firestore
        if (downloadedImagePath != null) {
          await _cloudStoreDataManagement.uploadProfilePic(
            filePath: downloadedImagePath,
          );

          //save profile pic locally
          await _localDatabase.insertOrUpdateDataForThisAccount(
              purpose: 'update',
              userName: username,
              userMail: userMail,
              userToken: userToken,
              userAbout: about,
              userAccCreationDate: acctCreationDate,
              userAccCreationTime: acctCreationTime,
              profileImagePath: pickedImage.path,
              profileImageUrl: downloadedImagePath);

          showPlatformToast(
              child: const Text('Profile picture has been updated'),
              context: context);
          if (mounted) {
            setState(() {
              profilePic = pickedImage.path;
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("unable to change profile picture ${e.toString()}");
    }
  }

  //
  void _getProfileDetailsFromLocal() async {
    final String? currentUserName = await _localDatabase.getUserNameForAnyUser(
        FirebaseAuth.instance.currentUser!.email.toString());

    String? pic = await _localDatabase.getParticularFieldDataFromImportantTable(
        userName: currentUserName!,
        getField: GetFieldForImportantDataLocalDatabase.profileImagePath);

    String? abt = await _localDatabase.getParticularFieldDataFromImportantTable(
        userName: currentUserName,
        getField: GetFieldForImportantDataLocalDatabase.about);

    String? mail =
        await _localDatabase.getParticularFieldDataFromImportantTable(
            userName: currentUserName,
            getField: GetFieldForImportantDataLocalDatabase.userEmail);

    String? date =
        await _localDatabase.getParticularFieldDataFromImportantTable(
            userName: currentUserName,
            getField:
                GetFieldForImportantDataLocalDatabase.accountCreationDate);
    String? userToken =
        await _localDatabase.getParticularFieldDataFromImportantTable(
            userName: currentUserName,
            getField: GetFieldForImportantDataLocalDatabase.token);

    String? time =
        await _localDatabase.getParticularFieldDataFromImportantTable(
            userName: currentUserName,
            getField:
                GetFieldForImportantDataLocalDatabase.accountCreationTime);

    if (mounted) {
      setState(() {
        username = currentUserName;
        about = abt!;
        userMail = mail!;
        acctCreationDate = date!;
        acctCreationTime = time!;
        profilePic = pic;
        print('profile pic is: $profilePic');
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
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: kWhite,
        body: Padding(
          padding: const EdgeInsets.only(top:12.0),
          child: ListView(
            children: [
              const SizedBox(height: 5.0),
              Row(
                children: [
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context, profilePic);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        size: 22.0,
                        color: kBlack,
                      )),
                  const Text(
                    'Profile',
                    style: TextStyle(color: kBlack, fontSize: 22.0),
                  )
                ],
              ),
              profilePicture(context),
              const SizedBox(
                height: 30.0,
              ),
              otherInformation(
                  leading: Icons.person,
                  title: 'Username',
                  subtitle: username,
                  trailing: Icons.edit),
              otherInformation(
                  leading: Icons.info,
                  title: 'About',
                  subtitle: about,
                  trailing: Icons.edit),
              otherInformation(
                  leading: Icons.mail, title: 'email', subtitle: userMail),
              otherInformation(
                  leading: Icons.timeline,
                  title: 'Account creation date',
                  subtitle:
                      acctCreationDate),
              const SizedBox(height: 10.0),
              _deleteAccountButton(context),
            ],
          ),
        ),
      ),
    );
  }

  //method to display profile picture
  Widget profilePicture(BuildContext context) {
    return Center(
        child: Badge(
            position: BadgePosition.bottomEnd(bottom: -1, end: -2),
            badgeColor: kPrimaryAppColor,
            badgeContent: Container(
                height: 23.0,
                width: 23.0,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimaryAppColor,
                ),
                child: GestureDetector(
                  child: Icon(
                    Icons.camera_alt,
                    color: kWhite,
                    size: MediaQuery.of(context).orientation ==
                            Orientation.portrait
                        ? MediaQuery.of(context).size.height *
                            (1.3 / 8) /
                            3.8 *
                            (3.5 / 6)
                        : MediaQuery.of(context).size.height * (1.3 / 8) / 2,
                  ),
                  onTap: () async {
                    _changeProfilePic();
                  },
                )),
            child: profilePic == null
                ? const CircleAvatar(
                    backgroundImage: AssetImage('assets/images/person.png'),
                    radius: 60.0,
                    backgroundColor: kTransparent,
                  )
                : GestureDetector(
                    child: CircleAvatar(
                        radius: 60,
                        backgroundImage: FileImage(File(profilePic!))),
                    onTap: () {
                      Navigator.push(
                          context,
                          PageTransition(
                              type: PageTransitionType.fade,
                              child: ImageViewScreen(
                                imageProviderCategory:
                                    ImageProviderCategory.fileImage,
                                imagePath: profilePic!,
                              )));
                    })));
  }

//other information in the profile screen
  Widget otherInformation(
      {required IconData leading,
      required String title,
      required String subtitle,
      IconData? trailing}) {
    return ListTile(
        leading: Icon(leading, size: 20.0, color: kGrey),
        title: Text(title,
            style: const TextStyle(
                color: kGrey,
                fontSize: 15.0,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: kBlack, fontSize: 17.0, fontWeight: FontWeight.w500)),
        trailing: Icon(trailing, size: 20.0, color: kPrimaryAppColor));
  }

// delete account
  Widget _deleteAccountButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 70.0, right: 70.0, top: 30.0),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40.0),
            side: const BorderSide(
              color: kRed,
            ),
          ),
        ),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Icon(Icons.delete_outlined, color: kRed, size: 18.0),
          Text(
            ' Delete account',
            style: TextStyle(
              fontSize: 16.0,
              color: kRed,
            ),
          ),
        ]),
        onPressed: () async {
          await _deleteConfirmation();
        },
      ),
    );
  }

//confirm delete
  Future<void> _deleteConfirmation() async {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: kWhite,
              elevation: 5.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40.0),
              ),
              title: const Center(
                child: Text(
                  'Sure to Delete Your Account?',
                  style: TextStyle(
                    color: kRed,
                    fontSize: 18.0,
                  ),
                ),
              ),
              content: SizedBox(
                height: 200.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Center(
                      child: Text(
                        'If You delete this account, your entire data will lost forever...\n\nDo You Want to Continue?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kBlack,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                          child: const Text(
                            'Cancel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.green,
                            ),
                          ),
                          style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40.0),
                            side: const BorderSide(color: Colors.green),
                          )),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        TextButton(
                          child: const Text(
                            'Sure',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                          style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40.0),
                            side: const BorderSide(color: kRed),
                          )),
                          onPressed: () async {
                            Navigator.pop(context);

                            if (mounted) {
                              setState(() {
                                _isLoading = true;
                              });
                            }
                            //  print("Deletion Event");

                            //   await deleteMyGenerationAccount();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ));
  }
}
