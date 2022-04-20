import 'package:flutter/material.dart';
import 'package:spark/global_uses/constants.dart';
import 'package:story_viewer/story_viewer.dart';
import 'package:flutter/services.dart';

class StoryView extends StatelessWidget {
  final String profilePic;
  final String username;
  final List<StoryItemModel> stories;

  
  const StoryView(
      {required this.profilePic,
      required this.stories,
      required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: StoryViewer(
      padding: const EdgeInsets.all(8.0),
      backgroundColor: kBlack,
      progressColor: kWhite,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: kTransparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      ratio: StoryRatio.r9_16,
      stories: stories,
      userModel: UserModel(
        username: username,
        profilePicture: NetworkImage(profilePic),
      ),
    ));
  }
}
