class CallLog {
  late String username;
  late String dateTime;
  late String isPicked;
  late String isCaller;
  late String profilePic;

  CallLog(
      {required String username,
      required String dateTime,
      required String isPicked,
      required String isCaller,
      required String profilePic}) {
    this.username = username;
    this.dateTime = dateTime;
    this.profilePic = profilePic;
    this.isPicked = isPicked;
    this.isCaller = isCaller;
  }

  factory CallLog.toJson(Map<String, dynamic> map) {
    return CallLog(
        username: map["username"],
        dateTime: map["date_time"],
        isPicked: map["isPicked"],
        isCaller: map["isCaller"],
        profilePic: map["profile_pic"]);
  }
}
