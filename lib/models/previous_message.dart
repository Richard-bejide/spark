import 'package:spark/global_uses/enum_generation.dart';

class PreviousMessageStructure {
  late String actualMessage;
  late String messageDate;
  late String messageTime;
  late String messageHolder;
  late ChatMessageType messageType;

  PreviousMessageStructure(
      {required String actualMessage,
      required String messageType,
      required String messageDate,
      required String messageTime,
      required String messageHolder}) {
    this.actualMessage = actualMessage;
    this.messageType = _getMessageType(messageType);
    this.messageTime = messageTime;
    this.messageDate = messageDate;
    this.messageHolder = messageHolder;
  }

  factory PreviousMessageStructure.toJson(Map<String, dynamic> map) {
    return PreviousMessageStructure(
        actualMessage: map["Message"],
        messageType: map["Message_Type"],
        messageDate: map["Message_Date"],
        messageTime: map["Message_Time"],
        messageHolder: map["Message_Holder"]);
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
