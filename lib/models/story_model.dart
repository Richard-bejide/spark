class StoryModel {
  StoryModel(
      {required this.stories,
      required this.userName,
      required this.imageUrl,
      });

  final List<Story> stories;
  final String userName;
  final String imageUrl;
  
}

class Story {
  Story({required this.storyData});
  final Map storyData;
  
}
