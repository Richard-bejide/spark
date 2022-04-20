import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:spark/backend/firebase/online_database_management/cloud_data_management.dart';
import 'package:spark/global_uses/constants.dart';
import 'package:spark/global_uses/enum_generation.dart';
import 'package:spark/models/request_model.dart';

class RequestScreen extends StatefulWidget {
  final List<RequestModel> requestList;
  final String buttonName;
  final String pageTitle;
  const RequestScreen(
      {required this.requestList,
      required this.buttonName,
      required this.pageTitle,
      Key? key})
      : super(key: key);

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final CloudStoreDataManagement _cloudStoreDataManagement =
      CloudStoreDataManagement();
  List<dynamic> _myConnectionRequestCollection = [];
  bool _isLoading = false;
  late List<RequestModel> requestList;
  //
  Future<void> _initialDataFetch() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    final List<dynamic> _connectionRequestList =
        await _cloudStoreDataManagement.currentUserConnectionRequestList(
            email: FirebaseAuth.instance.currentUser!.email.toString());

    if (mounted) {
      setState(() {
        _myConnectionRequestCollection = _connectionRequestList;
      });
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    requestList = widget.requestList;
    _initialDataFetch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
          body: Column(children: [
        const SizedBox(
          height: 10.0,
        ),
        Row(
          children: [
            IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 22.0,
                  color: kBlack,
                )),
            Text(
              widget.pageTitle,
              style: const TextStyle(color: kBlack, fontSize: 22.0),
            )
          ],
        ),
        const SizedBox(
          height: 10.0,
        ),
        requestList.isEmpty
            ? const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Text('No requests',
                    style: TextStyle(color: kGrey, fontSize: 14.0)))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: requestList.length,
                itemBuilder: (context, index) => _requestListTile(index: index))
      ])),
    ));
  }

  ListTile _requestListTile({required index}) {
    return ListTile(
      tileColor: kWhite,
      leading: GestureDetector(
          child: CircleAvatar(
              backgroundImage: NetworkImage(
                requestList[index].profilePic,
              ),
              radius: 23.0,
              backgroundColor: kTransparent),
          onTap: () {
            //     Navigator.push(
            // context,
            // MaterialPageRoute(
            //     builder: (_) => ImageViewScreen(
            //       imageProviderCategory: ImageProviderCategory.networkImage,
            //         imagePath: profilePic,
            //        )));
          }),
      title: Text(requestList[index].userName,
          style: const TextStyle(
              color: kBlack, letterSpacing: 1.0, fontSize: 17.0)),
      subtitle: Text(requestList[index].about,
          style: const TextStyle(
              color: kGrey, letterSpacing: 1.0, fontSize: 14.0)),
      trailing: TextButton(
          style: TextButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 216, 116, 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40.0)),
              side: const BorderSide(
                color: Color.fromARGB(255, 216, 116, 8),
              )),
          child: Text(widget.buttonName,
              style: const TextStyle(fontSize: 12.0, color: kWhite)),
          onPressed: () async {
            try {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }

              if (mounted) {
                setState(() {
                  _myConnectionRequestCollection.forEach((element) {
                    if (element.keys.first.toString() ==
                        requestList[index].email) {
                      _myConnectionRequestCollection[
                          _myConnectionRequestCollection.indexOf(element)] = {
                        requestList[index].email:
                            OtherConnectionStatus.invitation_accepted.toString()
                      };
                    }
                  });
                });
              }

              await _cloudStoreDataManagement.changeConnectionStatus(
                  storeDataAlsoInConnections: true,
                  oppositeUserMail: requestList[index].email,
                  currentUserMail:
                      FirebaseAuth.instance.currentUser!.email.toString(),
                  connectionUpdatedStatus:
                      OtherConnectionStatus.request_accepted.toString(),
                  //save updated Connection Request Collection to firestore for current user
                  currentUserUpdatedConnectionRequest:
                      _myConnectionRequestCollection);

              if (mounted) {
                setState(() {
                  requestList.removeAt(index);
                });
              }

              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            } catch (e) {
              print('error in accepting friend request ${e.toString()}');
            }
          }),
    );
  }
}
