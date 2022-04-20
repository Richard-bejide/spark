import 'package:firebase_auth/firebase_auth.dart';
import 'package:spark/global_uses/enum_generation.dart';

class EmailAndPasswordAuth {
  EmailAndPasswordAuth();

  //sign up authentication
  Future<EmailSignUpResults> signUpAuth(
      {required String email, required String password}) async {
    try {
      //create a new user with given email and password
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      //if given email is not null send email verification message
      if (userCredential.user!.email != null) {
        await userCredential.user!.sendEmailVerification();
        return EmailSignUpResults.signUpCompleted;
      }

      //if sign up is not completed for some reasons
      return EmailSignUpResults.signUpNotCompleted;
    } catch (e) {
      //if email already exists
      return EmailSignUpResults.emailAlreadyPresent;
    }
  }

  //login authentication
  Future<EmailSignInResults> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      //sign in user with email and password
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      //if email has been verified
      if (userCredential.user!.emailVerified) {
        return EmailSignInResults.signInCompleted;
      }

      //if email has not been verified
      else {
        final bool logOutResponse = await logOut();
        if (logOutResponse) {
          return EmailSignInResults.emailNotVerified;
        } else {
          return EmailSignInResults.unexpectedError;
        }
      }
    } catch (e) {
      //error in email and password authentication
      return EmailSignInResults.emailOrPasswordInvalid;
    }
  }

  //log user out of their acct
  Future<bool> logOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      return true;
    } catch (e) {
      return false;
    }
  }
}
