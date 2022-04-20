
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
  request_pending,
  request_accepted,
  invitation_came,
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

