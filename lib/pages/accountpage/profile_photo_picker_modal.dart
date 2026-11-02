import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:chuckler/state/session_service.dart';
import 'package:chuckler/data/users.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../CustomReusableWidgets/profile_photo.dart';
class ProfilePhotoPickerModal extends StatelessWidget {
  final String username;
  final String? img;

  ProfilePhotoPickerModal({super.key, required this.username, this.img});
  FirebaseAuth auth = FirebaseAuth.instance;
  @override
  build(context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    FirebaseFirestore firestore = Provider.of<FirebaseFirestore>(context, listen: false);
    return InkWell(
        onTap: () async {
          SessionService sessionService = Provider.of<SessionService>(context, listen: false);
          //TODO ENSURE THAT IMAGE PICKER HAS PROPER RIGHTS FOR ANDROID AND IOS
          ImagePicker imagePicker = ImagePicker();
          XFile? file =
              await imagePicker.pickImage(source: ImageSource.gallery);

          if (file == null) {
            return;
          }

          Reference referenceRoot = FirebaseStorage.instance.ref();
          Reference referenceDir = referenceRoot.child('ProfilePhotos');
          //Create a universal unique id for the file

          Reference imageToUpload = referenceDir.child(auth.currentUser!.uid);
          try {
            //TODO MAKE SURE THAT AUTHOR IS ADDED TO META DATA AND ONLY THE AUTHOR CAN EDIT
            await imageToUpload.putFile(File(file.path));
            String pfp =await imageToUpload.getDownloadURL();
            if(pfp != sessionService.loggedInUser!.profilePicture) {
              sessionService.setUserProfilePicture(pfp);
              updateProfilePhoto(firestore, pfp, auth.currentUser!.uid);
            }
          } catch (error) {}
        },
        child:ProfilePhoto(username: username, img: img, radius: 50,));
  }
}
