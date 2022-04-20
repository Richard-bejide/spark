class Call {
  late String callerId;
  late String callerPic;
  late String callerName;
  late String receiverId;
  late String receiverPic;
  late String receiverName;
  late String channeId;

  Call(
      {required String callerId,
      required String callerName,
      required String callerPic,
      required String receiverId,
      required String receiverName,
      required String receiverPic,
      required String channeId}) {
    this.callerId = callerId;
    this.callerName = callerName;
    this.callerPic = callerPic;
    this.channeId = channeId;
    this.receiverId = receiverId;
    this.receiverPic = receiverPic;
    this.receiverName = receiverName;
  }

//to map
  static Map<String, dynamic> toMap(Call call) {
    Map<String, dynamic> callMap = {};
    callMap["caller_id"] = call.callerId;
    callMap["caller_name"] = call.callerName;
    callMap["caller_pic"] = call.callerPic;
    callMap["receiver_id"] = call.receiverId;
    callMap["receiver_name"] = call.receiverName;
    callMap["receiver_pic"] = call.receiverPic;
    callMap["channel_id"] = call.channeId;
    return callMap;
  }

  //from map
  Call.fromMap(Map callMap) {
    callerId = callMap["caller_id"];
    callerName = callMap["caller_name"];
    callerPic = callMap["caller_pic"];
    receiverId = callMap["receiver_id"];
    receiverName = callMap["receiver_name"];
    receiverPic = callMap["receiver_pic"];
    channeId = callMap["channel_id"];
  }
}
