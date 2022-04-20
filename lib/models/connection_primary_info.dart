class ConnectionPrimaryInfo {
  late String connectionUsername;
  late String connectionAbout;
  late String profilePic;

  ConnectionPrimaryInfo({
    required String connectionUsername,
    required String connectionAbout,
    required String profilePic
  }) {
    this.connectionUsername = connectionUsername;
    this.connectionAbout = connectionAbout;
    this.profilePic = profilePic;
  }

  factory ConnectionPrimaryInfo.toJson(Map<String, dynamic> map) {
    return ConnectionPrimaryInfo(
        connectionUsername: map["Username"], 
        connectionAbout: map["About"],
        profilePic: map["Profile_image_path"]);
  }
}
