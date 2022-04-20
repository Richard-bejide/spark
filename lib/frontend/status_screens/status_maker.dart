import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:spark/backend/firebase/online_database_management/cloud_data_management.dart';
import 'package:spark/backend/sqlite_management/local_database_management.dart';
import 'package:spark/global_uses/constants.dart';


class StatusMaker extends StatefulWidget {
  final XFile pickedImage;
  const StatusMaker({Key? key, required this.pickedImage}) : super(key: key);

  @override
  State<StatusMaker> createState() => _StatusMakerState();
}

class _StatusMakerState extends State<StatusMaker> {
  final LocalDatabase _localDatabase = LocalDatabase();
  final CloudStoreDataManagement _cloudStoreDataManagement =
      CloudStoreDataManagement();

  bool _isLoading = false;

  TextEditingController _controller = TextEditingController();

  //upload status
  void _uploadStatus() async {
    SystemChannels.textInput
        .invokeMethod('TextInput.hide'); //hides the keyboard
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }


      final String _statusTime =
          "${DateTime.now().hour}:${DateTime.now().minute}";

      final String? _currentUsername =
          await _localDatabase.getUserNameForAnyUser(
              FirebaseAuth.instance.currentUser!.email.toString());

      //upload file and get the remote file path
      final String? downloadedImagePath = await _cloudStoreDataManagement
          .uploadMediaToStorage(File(widget.pickedImage.path), reference: 'statusImages/');

      //upload status data including remote file path to firestore
      if (downloadedImagePath != null) {
        await _cloudStoreDataManagement.uploadStatusData(
          filePath: downloadedImagePath,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      Navigator.pop(context);
    } catch (e) {
      print("unable to add new status ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: LoadingOverlay(
        isLoading: _isLoading,
        color: kWhite,
        child: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
                  fit: BoxFit.cover,
                  image: FileImage(File(widget.pickedImage.path)))),
          child: Stack(
            children: [
              Container(
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 25.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30.0))),
                          child: TextField(
                              maxLines: 1,
                              // maxLength: 30,
                              controller: _controller,
                              style: const TextStyle(
                                  color: kWhite,
                                  letterSpacing: 1.0,
                                  fontSize: 16.0),
                              decoration: const InputDecoration(
                                constraints: BoxConstraints(
                                    maxHeight: 65.0, maxWidth: 260.0),
                                hintText: 'Caption',
                                fillColor: Colors.black45,
                                filled: true,
                                focusColor: null,
                                hintStyle: TextStyle(
                                    color: kGrey,
                                    fontSize: 18.0,
                                    letterSpacing: 1.0),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(50)),
                                    borderSide:
                                        BorderSide(color: kTransparent)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(50)),
                                    borderSide:
                                        BorderSide(color: kTransparent)),
                              )),
                        ),
                        const SizedBox(width: 12.0),
                        Container(
                          decoration: const BoxDecoration(
                              gradient: kGradient, shape: BoxShape.circle),
                          child: IconButton(
                              onPressed: _uploadStatus,
                              icon: const Icon(
                                Icons.send,
                                color: kWhite,
                                size: 26.0,
                              )),
                        ),
                      ]))
            ],
          ),
        ),
      ),
    );
  }
}
