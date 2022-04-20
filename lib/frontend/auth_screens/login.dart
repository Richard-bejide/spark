import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:spark/backend/firebase/auth/email_and_password_auth.dart';
import 'package:spark/backend/firebase/auth/google_auth.dart';
import 'package:spark/backend/firebase/online_database_management/cloud_data_management.dart';
import 'package:spark/frontend/main_screens/main_screen.dart';
import 'package:spark/frontend/new_user_entry_screen/new_user_entry.dart';
import 'package:spark/global_uses/constants.dart';
import 'package:spark/frontend/auth_screens/sign_up.dart';
import 'package:spark/global_uses/enum_generation.dart';
import 'package:spark/global_uses/reg_exp.dart';
import 'package:spark/global_uses/alert.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool obscureText = true; //password visibility
  bool _isLoading = false;
  final EmailAndPasswordAuth _emailAndPasswordAuth = EmailAndPasswordAuth();
  final GoogleAuthentication _googleAuthentication = GoogleAuthentication();

  final TextEditingController _email =
      TextEditingController(); //input in the email field
  final TextEditingController _password =
      TextEditingController(); //input in the password field

  final GlobalKey<FormState> _loginKey =
      GlobalKey<FormState>(); //uniquely identify the login elements

  @override
  Widget build(BuildContext context) {
          return Scaffold(
              backgroundColor: kWhite,
              body: LoadingOverlay(
                isLoading: _isLoading,
                child: Padding(
                  padding: const EdgeInsets.only(top:12.0),
                  child: ListView(shrinkWrap: true, children: <Widget>[
                    _loginText(),
                    _loginForm(),
                    _loginButton(),
                    _forgotPasswordText(),
                    //   _orContinueWithSocialMediaText(),
                    //  _socialMediaIntegrationButtons(),
                    _switchToSignupPage()
                  ]),
                ),
));
    
  }

//Methods

//some common TextFormFields
  Widget _commonTextFormField(
      {required String hintText,
      required String labelText,
      required IconData icon,
      required TextInputType textInputType,
      required bool isPassword,
      required String? Function(String?)? validator,
      required TextEditingController textEditingController}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 35.0),
      child: TextFormField(
          obscureText: isPassword ? obscureText : false,
          obscuringCharacter: '*',
          keyboardType: textInputType,
          controller: textEditingController,
          validator: validator,
          style: const TextStyle(color: kBlack),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(10.0),
            errorStyle:
                const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            prefixIcon: Icon(icon, color: kPrimaryAppColor, size: 15.0),
            // suffix: isPassword ? _showPassword() : null,
            labelText: labelText,
            labelStyle: const TextStyle(
                color: kBlack, letterSpacing: 1.0, fontWeight: FontWeight.w500),
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 1.0),
            filled: true,
            fillColor: const Color.fromARGB(26, 63, 2, 142),
            enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(50)),
                borderSide: BorderSide(color: kPrimaryAppColor)),
            focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(50)),
                borderSide: BorderSide(color: kPrimaryAppColor)),
                errorBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(50)),
                borderSide: BorderSide(color: kPrimaryAppColor)),
                 focusedErrorBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(50)),
                borderSide: BorderSide(color: kPrimaryAppColor)),
          )),
    );
  }

// //button to show user's password
//   Widget _showPassword() {
//     return obscureText
//         ? IconButton(
//             icon: const FaIcon(FontAwesomeIcons.solidEyeSlash,
//                 color: kWhite, size: 14.0),
//             onPressed: () {
//               setState(() {
//                 obscureText = false;
//               });
//             })
//         : IconButton(
//             icon: const FaIcon(FontAwesomeIcons.solidEye,
//                 color: kWhite, size: 14.0),
//             onPressed: () {
//               setState(() {
//                 obscureText = true;
//               });
//             });
//   }

//heading
  Widget _loginText() {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0, bottom: 18.0, left: 30.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Image.asset(
            "assets/images/login.jpg",
            height: 200.0,
            width: 500.0,
          ),
        ),
        const Text('Login',
            style: TextStyle(
                color: kBlack,
                fontSize: 30.0,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700)),
        const Text('Please sign in to continue',
            style: TextStyle(
                color: kGrey,
                fontSize: 14.0,
                letterSpacing: 1.0,
                fontStyle: FontStyle.italic)),
      ]),
    );
  }

//login form
  Widget _loginForm() {
    return Form(
      key: _loginKey,
      child: Column(
        children: <Widget>[
          _commonTextFormField(
              hintText: 'enter email',
              labelText: 'Email',
              icon: Icons.email,
              textInputType: TextInputType.emailAddress,
              isPassword: false,
              validator: (inputValue) {
                if (!emailRegex.hasMatch(inputValue.toString())) {
                  return 'incorrect email format';
                }
                return null;
              },
              textEditingController: _email),
          _commonTextFormField(
              hintText: 'enter password',
              labelText: 'Password',
              icon: Icons.lock,
              textInputType: TextInputType.visiblePassword,
              isPassword: true,
              validator: (String? inputValue) {
                if (inputValue!.length < 6) {
                  return 'Password must be atleast 6 characters';
                }
                return null;
              },
              textEditingController: _password),
        ],
      ),
    );
  }

//button to login
  Widget _loginButton() {
    return Padding(
      padding: const EdgeInsets.only(
          top: 12.0, bottom: 10.0, left: 100.0, right: 100.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            minimumSize: const Size(100.0, 50.0),
            primary: kPrimaryAppColor,
            elevation: 0.0,
            padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(40.0)))),
        child: const Text('LOGIN',
            style: TextStyle(
                color: kWhite,
                letterSpacing: 1.0,
                fontSize: 18.0,
                fontWeight: FontWeight.w500)),
        onPressed: () async {
          if (_loginKey.currentState!.validate()) {
            //hides the keyboard
            SystemChannels.textInput.invokeMethod('TextInput.hide');

            //display laoding overlay
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }

            //call signInWithEmailAndPassword()
            final EmailSignInResults emailSignInResults =
                await _emailAndPasswordAuth.signInWithEmailAndPassword(
                    email: _email.text, password: _password.text);

            //alert message to show
            String msg = '';

            //if email and password signin is complete
            if (emailSignInResults == EmailSignInResults.signInCompleted) {
              //check if user has data on firestore or not
              final bool isDataPresent = await CloudStoreDataManagement()
                  .userRecordPresentOrNot(
                      email:
                          FirebaseAuth.instance.currentUser!.email.toString());

              ///navigate to [MainScreen] if data is present or  [TakePrimaryUserData] otherwise
              isDataPresent
                  ? Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const MainScreen()))
                  : Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TakePrimaryUserData()));
            }

            //if email has not been verified
            else if (emailSignInResults ==
                EmailSignInResults.emailNotVerified) {
              msg = 'Email not verified \nPlease verify your email and retry';
            }
            //if email or password is incorrect
            else if (emailSignInResults ==
                EmailSignInResults.emailOrPasswordInvalid) {
              msg = 'Email or pasword is invalid';
            }
            // if error occurs
            else {
              msg = "sign in not completed";
            }

            //display Alert message
            if (msg != '') {
              alert(title: msg, context: context);
              Timer(const Duration(seconds: 2), () => Navigator.pop(context));
               //hides the keyboard
              SystemChannels.textInput.invokeMethod('TextInput.hide');
            }
          }

          //remove loading overlay
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      ),
    );
  }

  Widget _forgotPasswordText() {
    return const Center(
      child: Text('Forgot password?',
          style: TextStyle(fontSize: 16.0, color: kPrimaryAppColor)),
    );
  }

  Widget _orContinueWithSocialMediaText() {
    return const Center(
      child: Text(
        '--  or continue with  --',
        style: TextStyle(color: kWhite, fontSize: 14.0),
      ),
    );
  }

//google and facebook sign in buttons
  Widget _socialMediaIntegrationButtons() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      width: double.maxFinite,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
              onTap: () async {
                //display laoding overlay
                if (mounted) {
                  setState(() {
                    _isLoading = true;
                  });
                }

                //call google signin method
                final GoogleSignInResults _googleSignInResults =
                    await _googleAuthentication.signInWithGoogle();

                //message to dislay on snacbar
                String msg = "";

                //if google signin is complete
                if (_googleSignInResults ==
                    GoogleSignInResults.signInCompleted) {
                  msg = 'Sign in completed';
                }
                //if google sign in is not completed for some reasons e.g user taps the back button
                else if (_googleSignInResults ==
                    GoogleSignInResults.signInCompleted) {
                  msg = 'Sign in not completed';
                }
                //if user is already signd in with google
                else if (_googleSignInResults ==
                    GoogleSignInResults.alreadySignedIn) {
                  msg = 'Already signed in with google';
                }
                //error occurs
                else {
                  msg = 'Unexpected error occured';
                }

                //displays alert message
                alert(title: msg, context: context);
                Timer(const Duration(seconds: 2), () => Navigator.pop(context));
                 //hides the keyboard
            SystemChannels.textInput.invokeMethod('TextInput.hide');
                //ScaffoldMessenger.of(context).showSnackBar(snackBar(msg));

                //if google sign in is complete
                if (_googleSignInResults ==
                    GoogleSignInResults.signInCompleted) {
                  //check if user has data on firestore or not
                  final bool isDataPresent = await CloudStoreDataManagement()
                      .userRecordPresentOrNot(
                          email: FirebaseAuth.instance.currentUser!.email
                              .toString());

                  ///navigate to [MainScreen] if data is present or  [TakePrimaryUserData] otherwise
                  isDataPresent
                      ? Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const MainScreen()))
                      : Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TakePrimaryUserData()));
                }

                //remove loading overlay
                if (mounted) {
                  setState(() {
                    _isLoading = true;
                  });
                }
              },
              child: Image.asset('assets/images/google.jpg', width: 50.0)),
          const SizedBox(width: 19.0),
          GestureDetector(
            onTap: () {},
            child: Image.asset('assets/images/facebook.jpg', width: 70.0),
          )
        ],
      ),
    );
  }

//button to switch to signup page
  Widget _switchToSignupPage() {
    return Padding(
      padding: const EdgeInsets.only(top: 70.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Don\'t have an account?  ',
            style: TextStyle(
                color: kGrey, fontStyle: FontStyle.italic, fontSize: 17.0),
          ),
          GestureDetector(
            child: const Text('Sign up',
                style: TextStyle(color: kPrimaryAppColor, fontSize: 18.0)),
            onTap: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const SignUpPage()));
            },
          )
        ],
      ),
    );
  }
}
