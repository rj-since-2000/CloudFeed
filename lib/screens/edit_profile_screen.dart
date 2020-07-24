import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:chatapp2/screens/image_view.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  static const routeName = '/edit-profile-screen';
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  var imageUrl;
  File newProfileImage;
  var username;
  var email;

  Future<void> getImage() async {
    var user = await FirebaseAuth.instance.currentUser();
    var userDocs =
        await Firestore.instance.collection('users').document(user.email).get();
    username = await userDocs.data['username'];
    email = user.email.toString();
    setState(() {});
    var url = await userDocs.data['image_url'];
    setState(() {
      imageUrl = url;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getImage();
  }

  void newImage(File image) {
    setState(() {
      newProfileImage = image;
    });
  }

  var choice;
  File _pickedImage;

  Future<String> chooseImage(BuildContext ctx) async {
    choice = null;
    await showDialog(
        context: ctx,
        child: AlertDialog(
          title: Text('Choose image from'),
          actions: <Widget>[
            FlatButton.icon(
                label: Text('gallery'),
                icon: Icon(Icons.photo_library),
                //tooltip: 'gallery',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  choice = 'gallery';
                }),
            FlatButton.icon(
                label: Text('camera'),
                icon: Icon(Icons.add_a_photo),
                //tooltip: 'camera',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  choice = 'camera';
                })
          ],
        ));
    return choice;
  }

  void _pickImage() async {
    var choice = await chooseImage(context);
    if (choice == null) return;
    final pickedImageFile = await ImagePicker.pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 100,
      maxWidth: 600,
    );
    _pickedImage = pickedImageFile;
    newImage(_pickedImage);
    final user = await FirebaseAuth.instance.currentUser();
    final uid = user.uid;
    final userDocs =
        await Firestore.instance.collection('users').document(user.email).get();
    final oldurl = await userDocs.data['image_url'];
    final ref = await FirebaseStorage.instance.getReferenceFromUrl(oldurl);

    await ref.delete();

    final newref =
        FirebaseStorage.instance.ref().child('user_image').child(uid + '.jpg');
    await newref.putFile(_pickedImage).onComplete;
    final url = await newref.getDownloadURL();
    await Firestore.instance
        .collection('users')
        .document(user.email)
        .updateData({'image_url': url});
    imageUrl = url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Stack(alignment: Alignment.center, children: <Widget>[
              CircleAvatar(
                radius: MediaQuery.of(context).size.width * 0.35,
                backgroundColor: Theme.of(context).accentColor,
              ),
              CircleAvatar(
                radius: MediaQuery.of(context).size.width * 0.35 - 2,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
              if (imageUrl != null)
                InkWell(
                  borderRadius: BorderRadius.circular(150),
                  onTap: () => Navigator.of(context).pushNamed(
                    ImageView.routeName,
                    arguments: imageUrl,
                  ),
                  child: Hero(
                    tag: imageUrl,
                    child: CircleAvatar(
                      radius: MediaQuery.of(context).size.width * 0.35 - 8,
                      backgroundImage: newProfileImage == null
                          ? NetworkImage(imageUrl)
                          : FileImage(newProfileImage),
                    ),
                  ),
                ),
            ]),
            SizedBox(height: 15),
            FlatButton.icon(
              onPressed: imageUrl == null ? null : _pickImage,
              icon: Icon(Icons.add_a_photo),
              label: Text('Change Profile Image'),
            ),
            SizedBox(height: 20),
            Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9),
              padding: EdgeInsets.all(5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'username',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  username != null
                      ? Text(
                          username,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        )
                      : Text('[username]'),
                ],
              ),
            ),
            Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9),
              padding: EdgeInsets.all(5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'email',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  email != null
                      ? Text(
                          email,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        )
                      : Text('[email]'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
