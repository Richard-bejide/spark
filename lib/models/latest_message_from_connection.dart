import 'package:spark/global_uses/enum_generation.dart';

class LatestMessageFromConnection {
  late String username;
  late String lastestMessage;
  late String messageTime;
  late String messageDate;
  late String messageHolder;
  late ChatMessageType messageType;
  late String profilePic;
  late int? count;

  LatestMessageFromConnection(
      {required String username,
      required String lastestMessage,
      required String messageTime,
      required String messageDate,
      required String messageHolder,
      required String messageType,
      required String profilePic,
      int count = 0}) {
    this.username = username;
    this.lastestMessage = lastestMessage;
    this.messageTime = messageTime;
    this.messageDate = messageDate;
    this.messageHolder = messageHolder;
    this.messageType = _getMessageType(messageType);
    this.profilePic = profilePic;
    this.count = count;
  }

  factory LatestMessageFromConnection.toJson(
      {required String userName, required Map<String, dynamic> map}) {
    return LatestMessageFromConnection(
        username: userName,
        lastestMessage: map["Message"],
        messageTime: map["Message_Time"],
        messageDate: map["Message_Date"],
        messageHolder: map["Message_Holder"],
        messageType: map["Message_Type"],
        profilePic: map["Profile_image_path"]);
  }

  ChatMessageType _getMessageType(String messageType) {
    if (messageType == "ChatMessageType.text") {
      return ChatMessageType.text;
    } else if (messageType == "ChatMessageType.video") {
      return ChatMessageType.video;
    } else if (messageType == "ChatMessageType.image") {
      return ChatMessageType.image;
    } else if (messageType == "ChatMessageType.document") {
      return ChatMessageType.document;
    } else if (messageType == "ChatMessageType.audio") {
      return ChatMessageType.audio;
    } else if (messageType == "ChatMessageType.camera") {
      return ChatMessageType.audio;
    }
    return ChatMessageType.none;
  }
}
