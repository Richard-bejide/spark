import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:spark/global_uses/enum_generation.dart';
import 'package:http/http.dart';

class SendNotification {
  //
  Future<void> messageNotificationClassifier({
    required ChatMessageType messageType,
    required Map<String, Map<String, String>> messageData,
    required String connectionToken,
    required String connectionAccountUsername,
    String textMsg = "",
  }) async {
    switch (messageType) {
      case ChatMessageType.none:
        break;
      case ChatMessageType.image:
        await sendNotification(
            token: connectionToken,
            title:
                "$connectionAccountUsername: sent an image",
            body: textMsg);
        break;
      case ChatMessageType.text:
        await sendNotification(
            token: connectionToken,
            title:
                "$connectionAccountUsername: ${_messageToDisplay(messageType: ChatMessageType.text, messageData: messageData)} ",
            body: textMsg);
        break;
      case ChatMessageType.video:
        await sendNotification(
            token: connectionToken,
            title:
                "$connectionAccountUsername: sent a video",
            body: textMsg);
        break;
      case ChatMessageType.document:
        await sendNotification(
            token: connectionToken,
            title:
                "$connectionAccountUsername: sent a document",
            body: textMsg);
        break;
      case ChatMessageType.audio:
        await sendNotification(
            token: connectionToken,
            title:
                "$connectionAccountUsername: sent an audio",
            body: textMsg);
        break;
     
    }
  }

  //
  Future<int> sendNotification(
      {required String token,
      required String title,
      required String body}) async {
    try {
      const String _serverKey =
          'AAAAwvor2bY:APA91bEsIN1a9XJIrEez-m4oVezb6pNDvd3u0c4I6KAc_JG8kM5J5khSTGN6Fgp_cNUnjp0OcxhS-2jfSR143HzHBRzYwk_k5oG7KhLBI5faLhkgxjz4BiUwGDGaqbKz6N7RkJXomSwg';

      final Response response = await post(
          Uri.parse("https://fcm.googleapis.com/fcm/send"),
          headers: <String, String>{
            "Content-Type": "application/json",
            "Authorization": "key=$_serverKey"
          },
          body: jsonEncode(<String, dynamic>{
            "notification": <String, dynamic>{"body": body, title: title},
            "priority": "high",
            "data": <String, dynamic>{
              "click": "FLUTTER_NOTIFICATION_CLICK",
              "id": 1,
              "status": "done",
              "collapse_key": "type_a"
            },
            "to": token
          }));

      print(" response is : ${response.statusCode} ${response.body}");
      return response.statusCode;
    } catch (e) {
      print("error in sending notification ${e.toString()}");
      return 404;
    }
  }

  Widget _messageToDisplay(
      {required ChatMessageType messageType, Map? messageData}) {
    switch (messageType) {
      case ChatMessageType.text:
        return messageData!.values.first.keys.first.length <= 20
            ? messageData.values.first.keys.first
            : messageData.values.first.keys.first.replaceRange(
                20, messageData.values.first.keys.first.length, '...');
      case ChatMessageType.image:
        return const Icon(Icons.image);
      case ChatMessageType.video:
        return const Icon(Icons.video_camera_back);
      case ChatMessageType.document:
        return const Icon(Entypo.doc);
      case ChatMessageType.audio:
        return const Icon(Icons.audiotrack);
      case ChatMessageType.none:
        return const Icon(Icons.image);
    }
  }
}
