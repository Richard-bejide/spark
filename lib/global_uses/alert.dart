import 'package:flutter/material.dart';
import 'package:spark/global_uses/constants.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

Future<bool?> alert(
    {required String title,
    String? description,
    required BuildContext context}) {
  return Alert(
      context: context,
      title: title,
      desc: description,
      style: AlertStyle(
          animationType: AnimationType.fromBottom,
          isCloseButton: false,
          overlayColor: Colors.black38,
          backgroundColor: kWhite,
          titleTextAlign: TextAlign.center,
          buttonAreaPadding: const EdgeInsets.all(1.0),
          titleStyle: const TextStyle(
              color: kBlack,
              fontSize: 18.0,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0),
          alertElevation: 1.0,
          isButtonVisible: false,
          isOverlayTapDismiss: false,
          descStyle: const TextStyle(fontWeight: FontWeight.bold),
          descTextAlign: TextAlign.center,
          animationDuration: const Duration(milliseconds: 600),
          alertBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
              side: const BorderSide(
                color: kWhite,
              )))).show();
}
