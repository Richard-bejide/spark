import 'dart:io';
import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:spark/backend/sqlite_management/local_database_management.dart';
import 'package:spark/frontend/preview/image_preview.dart';
import 'package:spark/global_uses/constants.dart';
import 'package:spark/global_uses/enum_generation.dart';
import 'package:spark/models/call_log.dart';
import 'package:page_transition/page_transition.dart';

class CallLogCollection extends StatefulWidget {
  const CallLogCollection({Key? key}) : super(key: key);

  @override
  State<CallLogCollection> createState() => _CallLogCollectionState();
}

class _CallLogCollectionState extends State<CallLogCollection> {
  bool _isLoading = false;
  final LocalDatabase _localDatabase = LocalDatabase();

  ///[LoadingOverlay] isLoading value
  //connections that have been called
  List<CallLog> _callDetails = [];

  TextEditingController _searchCallLogsController = TextEditingController();
  
  
  
  //load call logs from local
  void _getCallLogsFromLocal() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      List<CallLog> _callLogs = await _localDatabase.getCallLogs();

      for (int i = 0; i < _callLogs.length; i++) {
        final CallLog callLog = _callLogs[i];
        if (mounted) {
          setState(() {
            _callDetails.add(CallLog(
                username: callLog.username,
                profilePic: callLog.profilePic,
                dateTime: callLog.dateTime,
                isPicked: callLog.isPicked,
                isCaller: callLog.isCaller));
          });
        }
      }
    } catch (e) {
      print("error in loading call logs from local: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    _getCallLogsFromLocal();
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
                                  const Text('Calls',
                                      style: TextStyle(
                                        color: kBlack,
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.w600,
                                      )),
                                  const SizedBox(width: 115.0),
                                  IconButton(
                                      icon: const Icon(Icons.more_vert_outlined,
                                          size: 21.0, color: kBlack),
                                      onPressed: () {}),
                                  const SizedBox(width: 2.0),
                                ]),
                            _searchCallLogs(),
                          ])),
                  _callDetails.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(top: 175.0),
                          child: Center(
                            child: Text(
                              'No logs yet',
                              style: TextStyle(
                                  color: kGrey,
                                  fontSize: 18.0,
                                  letterSpacing: 1.0),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _callDetails.length,
                          itemBuilder: (upperContext, index) =>
                              _connectionCallHistory(index))
                ]))));
  }

//connection call history tile
  Widget _connectionCallHistory(int index) {
    return ListTile(
        key: Key('$index'),
        onTap: () {},
        //animation container
        leading: GestureDetector(
            child: CircleAvatar(
                radius: 25.0,
                backgroundColor: Colors.transparent,
                backgroundImage:
                    FileImage(File(_callDetails[index].profilePic))),
            onTap: () {
              Navigator.push(
                  context,
                  PageTransition(
                      type: PageTransitionType.fade,
                      child: ImageViewScreen(
                        imagePath: _callDetails[index].profilePic,
                        imageProviderCategory: ImageProviderCategory.fileImage,
                      )));
            }),
        title: Text(
            _callDetails[index].username.length <= 18
                ? _callDetails[index].username
                : _callDetails[index].username.replaceRange(
                    18,
                    _callDetails[index].username.length,
                    '...'), //ensure title length is no more than 18
            style: const TextStyle(
                fontSize: 18.0,
                color: kBlack,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.0)),
        subtitle: Row(
          children: [
            _callDetails[index].isCaller == "true"
                ? _callDetails[index].isPicked == "true"
                    ? const Icon(
                        Icons.call_made,
                        size: 15.0,
                        color: Colors.green,
                      )
                    : const Icon(
                        Icons.call_missed,
                        size: 15.0,
                        color: kRed,
                      )
                : _callDetails[index].isPicked == "true"
                    ? const Icon(
                        Icons.call_received,
                        size: 15.0,
                        color: Colors.green,
                      )
                    : const Icon(
                        Icons.call_missed,
                        size: 15.0,
                        color: kRed,
                      ),
            Text(
              _callDetails[index].dateTime,
              style: const TextStyle(
                  color: kGrey,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  fontSize: 13.0),
            )
          ],
        ),
        trailing: IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.call,
              size: 22.0,
              color: kPrimaryAppColor,
            )));
  }

  Widget _searchCallLogs() {
    return Container(
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(30.0))),
      child: TextField(
          maxLines: 1,
          controller: _searchCallLogsController,
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
}
