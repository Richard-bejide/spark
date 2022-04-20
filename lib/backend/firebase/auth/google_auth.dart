import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:spark/global_uses/enum_generation.dart';

class GoogleAuthentication {
  //Initializes global sign-in configuration settings.
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  //sign in with google
  Future<GoogleSignInResults> signInWithGoogle() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        return GoogleSignInResults.alreadySignedIn;
      } else {
        final GoogleSignInAccount? _googleSignInAccount =
            await _googleSignIn.signIn();
        if (_googleSignInAccount == null) {
          return GoogleSignInResults.signInNotCompleted;
        } else {
          final GoogleSignInAuthentication _googleSignInAuthentication =
              await _googleSignInAccount.authentication;
              //Create a new [GoogleAuthCredential] from a provided [accessToken].
          final OAuthCredential _oAuthCredential =
              GoogleAuthProvider.credential(
                  accessToken: _googleSignInAuthentication.accessToken,
                  idToken: _googleSignInAuthentication.idToken);
          final UserCredential userCredential = await FirebaseAuth.instance
              .signInWithCredential(_oAuthCredential);

          if (userCredential.user!.email != null) {
            return GoogleSignInResults.signInCompleted;
          } else {
            return GoogleSignInResults.unexpectedError;
          }
        }
      }
    } catch (e) {
      return GoogleSignInResults.unexpectedError;
    }
  }

//google sign out
  Future<bool> logOut() async {
    try {
      await _googleSignIn.disconnect();
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      return true;
    } catch (e) {
      return false;
    }
  }
}
