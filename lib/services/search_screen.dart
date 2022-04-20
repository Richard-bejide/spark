import 'package:flutter/material.dart';
import 'package:spark/backend/firebase/online_database_management/cloud_data_management.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spark/frontend/preview/image_preview.dart';
import 'package:spark/global_uses/constants.dart';
import 'package:spark/global_uses/enum_generation.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:spark/models/search.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Search> _allUsers = [];
  List<Search> _allSearchedUsers = [];
  List<dynamic> _myConnectionRequestCollection = [];
  bool _isLoading = false;
  TextEditingController searchController = TextEditingController();
  final CloudStoreDataManagement _cloudStoreDataManagement =
      CloudStoreDataManagement();

  //
  Future<void> _initialDataFetchAndCheckUp() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final List<Search> allUsersList =
        await _cloudStoreDataManagement.getAllUsersList(
            currentUserEmail:
                FirebaseAuth.instance.currentUser!.email.toString());

    final List<Search> _allSearchedUsersList = [];

    if (mounted) {
      setState(() {
        allUsersList.forEach((element) {
          if (mounted) {
            setState(() {
              _allSearchedUsersList.add(element);
            });
          }
        });
      });
    }

    final List<dynamic> _connectionRequestList =
        await _cloudStoreDataManagement.currentUserConnectionRequestList(
            email: FirebaseAuth.instance.currentUser!.email.toString());

    if (mounted) {
      setState(() {
        _allUsers = allUsersList;
        _allSearchedUsers = _allSearchedUsersList;
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
    _initialDataFetchAndCheckUp();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: kWhite,
        body: LoadingOverlay(
            isLoading: _isLoading,
            child: ListView(children: [
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Column(children: [
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
                      const Text(
                        'Search',
                        style: TextStyle(color: kBlack, fontSize: 22.0),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  _search(),
                ]),
              ),
              searchController.text.isEmpty
                  ? Container(
                      padding: const EdgeInsets.only(top: 80.0),
                      alignment: Alignment.center,
                      child: Image.asset('assets/images/search.PNG',
                          height: 180.0, width: 220.0))
                  : ListView(shrinkWrap: true, children: [
                      const SizedBox(height: 20.0),
                      const Center(
                        child: Text(
                          'Search result:',
                          style: TextStyle(color: kBlack, fontSize: 20.0),
                        ),
                      ),
                      Container(
                          width: double.maxFinite,
                          margin: const EdgeInsets.only(
                              top: 20.0, bottom: 20.0),
                          child: ListView.builder(
                              itemCount: _allSearchedUsers.length,
                              shrinkWrap: true,
                              itemBuilder: (connectionContext, index) =>
                                  _showAvailableUser(index)))
                    ])
            ])));
  }

  //available user
  Widget _showAvailableUser(int index) {
    return Container(
      height: 80.0,
      width: double.maxFinite,
      padding: const EdgeInsets.all(6.0),
      child: ListTile(
        tileColor: kWhite,
        leading: GestureDetector(
            child: CircleAvatar(
                backgroundImage: NetworkImage(
                  _allSearchedUsers[index].profilePic,
                ),
                radius: 23.0,
                backgroundColor: kTransparent),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ImageViewScreen(
                            imageProviderCategory:
                                ImageProviderCategory.networkImage,
                            imagePath: _allSearchedUsers[index].profilePic,
                          )));
            }),
        title: Text(_allSearchedUsers[index].userName,
            style: const TextStyle(
                color: kBlack, letterSpacing: 1.0, fontSize: 17.0)),
        subtitle: Text(_allSearchedUsers[index].about,
            style: const TextStyle(
                color: kGrey, letterSpacing: 1.0, fontSize: 14.0)),
        trailing: TextButton(
            style: TextButton.styleFrom(
                backgroundColor: _getRelevantButtonConfig(
                    connectionStateType: ConnectionStateType.buttonBorderColor,
                    index: index),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40.0)),
                side: BorderSide(
                    color: _getRelevantButtonConfig(
                        connectionStateType:
                            ConnectionStateType.buttonBorderColor,
                        index: index))),
            child: _getRelevantButtonConfig(
                connectionStateType: ConnectionStateType.buttonNameWidget,
                index: index),
            onPressed: () {
              _onConnectionStateButtonPressed(index);
            }),
      ),
    );
  }

  //onPressed action of connection state button
  void _onConnectionStateButtonPressed(int index) async {
    final String buttonName = _getRelevantButtonConfig(
        connectionStateType: ConnectionStateType.buttonNameOnly, index: index);

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    //CONNECTING WITH A NEW USER

    if (buttonName == ConnectionStateName.connect.toString()) {
      if (mounted) {
        setState(() {
          //for Current User
          //add opposite user mail to _myconnectionRequestCollection and save it has pending
          _myConnectionRequestCollection.add({
            _allSearchedUsers[index].email:
                OtherConnectionStatus.request_pending.toString(),
          });
        });
      }

      //for opposite user
      //save invitation on opposite user acct on firestore
      await _cloudStoreDataManagement.changeConnectionStatus(
          oppositeUserMail: _allSearchedUsers[index].email,
          currentUserMail: FirebaseAuth.instance.currentUser!.email.toString(),
          connectionUpdatedStatus:
              OtherConnectionStatus.invitation_came.toString(),
          //save updated Connection Request Collection to firestore for current user
          currentUserUpdatedConnectionRequest: _myConnectionRequestCollection);
    }

    //ACCEPTING CONNECTION REQUEST
    else if (buttonName == ConnectionStateName.accept.toString()) {
      if (mounted) {
        setState(() {
          _myConnectionRequestCollection.forEach((element) {
            if (element.keys.first.toString() ==
                _allSearchedUsers[index].email) {
              _myConnectionRequestCollection[
                  _myConnectionRequestCollection.indexOf(element)] = {
                _allSearchedUsers[index].email:
                    OtherConnectionStatus.invitation_accepted.toString()
              };
            }
          });
        });
      }

      await _cloudStoreDataManagement.changeConnectionStatus(
          storeDataAlsoInConnections: true,
          oppositeUserMail: _allSearchedUsers[index].email,
          currentUserMail: FirebaseAuth.instance.currentUser!.email.toString(),
          connectionUpdatedStatus:
              OtherConnectionStatus.request_accepted.toString(),
          //save updated Connection Request Collection to firestore for current user
          currentUserUpdatedConnectionRequest: _myConnectionRequestCollection);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Connection State button
  dynamic _getRelevantButtonConfig(
      {required ConnectionStateType connectionStateType, required int index}) {
    bool _isUserPresent = false;
    String _storeStatus = '';

    _myConnectionRequestCollection.forEach((element) {
      if (element.keys.first.toString() == _allSearchedUsers[index].email) {
        _isUserPresent = true;
        _storeStatus = element.values.first.toString();
      }
    });

    if (_isUserPresent) {
      //  print('User Present in Connection List');

      if (_storeStatus == OtherConnectionStatus.request_pending.toString() ||
          _storeStatus == OtherConnectionStatus.invitation_came.toString()) {
        if (connectionStateType == ConnectionStateType.buttonNameWidget) {
          return Text(
            _storeStatus == OtherConnectionStatus.request_pending.toString()
                ? ConnectionStateName.pending
                    .toString()
                    .split(".")[1]
                    .toString()
                : ConnectionStateName.accept
                    .toString()
                    .split(".")[1]
                    .toString(),
            style: const TextStyle(color: kWhite, fontSize: 12.0),
          );
        } else if (connectionStateType == ConnectionStateType.buttonNameOnly) {
          return _storeStatus ==
                  OtherConnectionStatus.request_pending.toString()
              ? ConnectionStateName.pending.toString()
              : ConnectionStateName.accept.toString();
        }

        return const Color.fromARGB(255, 216, 116, 8);
      } else {
        if (connectionStateType == ConnectionStateType.buttonNameWidget) {
          return Text(
            ConnectionStateName.connected.toString().split(".")[1].toString(),
            style: const TextStyle(color: kWhite, fontSize: 12.0),
          );
        } else if (connectionStateType == ConnectionStateType.buttonNameOnly) {
          return ConnectionStateName.connected.toString();
        }

        return kGreen;
      }
    } else {
      if (connectionStateType == ConnectionStateType.buttonNameWidget) {
        return Text(
          ConnectionStateName.connect.toString().split(".")[1].toString(),
          style: const TextStyle(color: kWhite, fontSize: 12.0),
        );
      } else if (connectionStateType == ConnectionStateType.buttonNameOnly) {
        return ConnectionStateName.connect.toString();
      }

      return kBlue;
    }
  }

// search field
  Widget _search() {
    return TextField(
        maxLines: 1,
        onChanged: (text) {
          if (mounted) {
            setState(() {
              _isLoading = true;
            });
          }

          if (mounted) {
            setState(() {
              searchController.text = text;
              _allSearchedUsers.clear();

              print('Available searched Users: $_allSearchedUsers');

              _allUsers.forEach((element) {
                if (element.userName
                    .toLowerCase()
                    .startsWith(text.toLowerCase())) {
                  _allSearchedUsers.add(element);
                }
              });
            });
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
        style:
            const TextStyle(color: kBlack, letterSpacing: 1.0, fontSize: 14.0),
        decoration: const InputDecoration(
            constraints: BoxConstraints(
              maxWidth: 220.0,
              maxHeight: 40.0,
            ),
            hintText: 'Search username...',
            fillColor: Color.fromARGB(26, 63, 2, 142),
            filled: true,
            focusColor: null,
            hintStyle:
                TextStyle(color: kGrey, fontSize: 16.0, letterSpacing: 1.0),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(50)),
                borderSide: BorderSide(color: kWhite)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(50)),
                borderSide: BorderSide(color: kBlue))));
  }
}
