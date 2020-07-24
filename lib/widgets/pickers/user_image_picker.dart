import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserImagePicker extends StatefulWidget {
  UserImagePicker(this.imagePickFn);

  final void Function(File pickedImage) imagePickFn;

  @override
  _UserImagePickerState createState() => _UserImagePickerState();
}

class _UserImagePickerState extends State<UserImagePicker> {
  File _pickedImage;
  var choice;

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
      maxWidth: 400,
    );
    setState(() {
      _pickedImage = pickedImageFile;
    });
    widget.imagePickFn(pickedImageFile);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        CircleAvatar(
          radius: 40,
          //backgroundColor: Colors.grey,
          backgroundImage:
              _pickedImage != null ? FileImage(_pickedImage) : null,
        ),
        FlatButton.icon(
          //textColor: Theme.of(context).primaryColor,
          onPressed: _pickImage,
          icon: Icon(Icons.image),
          label: Text('Add Image'),
        ),
      ],
    );
  }
}
