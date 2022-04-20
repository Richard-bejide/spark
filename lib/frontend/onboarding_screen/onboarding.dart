import 'package:flutter/material.dart';
import 'package:spark/frontend/auth_screens/login.dart';
import 'package:spark/global_uses/constants.dart';
import 'package:flutter_overboard/flutter_overboard.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final pages = [
    PageModel(
        color: kWhite,
        titleColor: kBlack,
        bodyColor: kGrey,
        imageAssetPath: 'assets/images/onboarding1.jpg',
        title: 'Chat anytime, anywhere',
        body:
            'passing information to friends and family is made simple',
        doAnimateImage: true),
    PageModel(
        color: kWhite,
        titleColor: kBlack,
        bodyColor: kGrey,
        imageAssetPath: 'assets/images/onboarding2.jpg',
        title: 'Make video and audio calls',
        body: 'experience a lag-free video and audio chat connection',
        doAnimateImage: true),
    PageModel(
        color: kWhite,
        titleColor: kBlack,
        bodyColor: kGrey,
        imageAssetPath: 'assets/images/onboarding3.jpg',
        title: 'Make new friends with ease',
        body: 'Meet and connect with people, all over the world',
        doAnimateImage: true),
  ];

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
        backgroundColor: kWhite,
        body: Padding(
          padding: const EdgeInsets.only(top:12.0),
          child: OverBoard(
    pages: pages,
    showBullets: true,
    buttonColor: kPrimaryAppColor,
    skipText: 'SKIP',
    nextText: 'NEXT',
    activeBulletColor: kPrimaryAppColor,
    inactiveBulletColor: kGrey,
    finishText: 'GOT IT',
    skipCallback: () {
      Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginPage()));
    },
    finishCallback: () {
      Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginPage()));
    },
          ),
        ),
      );
    
  }
}
