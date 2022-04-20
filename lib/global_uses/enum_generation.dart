
enum EmailSignUpResults {
  signUpCompleted,
  emailAlreadyPresent,
  signUpNotCompleted
}

enum EmailSignInResults {
  signInCompleted,
  emailNotVerified,
  emailOrPasswordInvalid,
  unexpectedError
}

enum GoogleSignInResults {
  signInCompleted,
  signInNotCompleted,
  unexpectedError,
  alreadySignedIn
}

enum StatusMediaType { textActivity, imageActivity }

enum ChatMessageType {
  none,
  image,
  audio,
  document,
  video,
  text
}

enum ImageProviderCategory { fileImage, exactAssetImage, networkImage }

enum ConnectionStateName { connect, pending, accept, connected }

enum ConnectionStateType { buttonNameWidget, 
buttonNameOnly,
buttonBorderColor }

enum OtherConnectionStatus {
  // ignore: constant_identifier_names
  request_pending,
  // ignore: constant_identifier_names
  request_accepted,
  // ignore: constant_identifier_names
  invitation_came,
  // ignore: constant_identifier_names
  invitation_accepted,
  
}


enum GetFieldForImportantDataLocalDatabase {
  userName,
  userEmail,
  token,
  profileImagePath,
  profileImageUrl,
  about,
  wallPaper,
  mobileNumber,
  notification,
  accountCreationDate,
  accountCreationTime,
}

 enum MessageHolderType{
   me,
   connectedUsers
 }

enum PreviousMessageColTypes {
  actualMessage,
  messageDate,
  messageTime,
  messageHolder,
  messageType,
}

