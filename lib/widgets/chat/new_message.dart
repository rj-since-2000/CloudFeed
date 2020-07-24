import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class NewMessage extends StatefulWidget {
  NewMessage(this.chatId, this.email, this.chooseImage);
  final chatId;
  final email;
  final Function chooseImage;
  @override
  _NewMessageState createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _controller = new TextEditingController();
  var _enteredMessage = '';
  File _pickedImage;
  //bool isImage = false;

  void _pickImage() async {
    String choice = await widget.chooseImage();
    if (choice == null) return;
    File pickedImageFile = await ImagePicker.pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 100,
      maxWidth: 600,
    );
    if (pickedImageFile == null) return;
    _pickedImage = pickedImageFile;
    showModalBottomSheet<dynamic>(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 5,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10))),
        context: context,
        builder: (ctx) {
          return Container(
            color: Colors.white,
            margin: EdgeInsets.all(10),
            //padding: EdgeInsets.all(20),
            //width: 250,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          //padding: EdgeInsets.all(5),
                          child: Image.file(
                            _pickedImage,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                //SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            return _pickImage();
                          },
                          child: Card(
                              elevation: 5,
                              child: Container(
                                color: Theme.of(context).primaryColor,
                                //width: 120,
                                //margin: EdgeInsets.all(20),
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  'Retake',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ))),
                    ),
                    Expanded(
                      child: InkWell(
                          onTap: () {
                            _sendImage();
                            Navigator.of(context).pop();
                          },
                          child: Card(
                              elevation: 5,
                              child: Container(
                                color: Theme.of(context).primaryColor,
                                //width: 120,
                                //margin: EdgeInsets.all(20),
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  'Send',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ))),
                    ),
                  ],
                )
              ],
            ),
          );
        });
    pickedImageFile = null;
  }

  Future<String> _submitImage(String id) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('chat_images')
        .child(widget.chatId)
        .child(id + '.jpg');
    await ref.putFile(_pickedImage).onComplete;
    final url = await ref.getDownloadURL();
    return url;
  }

  void _sendImage() async {
    final user = await FirebaseAuth.instance.currentUser();
    final userData =
        await Firestore.instance.collection('users').document(user.email).get();
    final docs = await Firestore.instance
        .collection('chats')
        .document(widget.chatId)
        .collection('chat')
        .add({
      'id': '',
      'text': '',
      'isImage': true,
      'createdAt': Timestamp.now(),
      'userId': user.uid,
      'sentTo': widget.chatId,
      'username': userData['username'],
      'userImage': userData['image_url'],
      'time': DateTime.fromMillisecondsSinceEpoch(
                  Timestamp.now().millisecondsSinceEpoch)
              .toString()
              .substring(0, 10) +
          DateTime.fromMillisecondsSinceEpoch(
                  Timestamp.now().millisecondsSinceEpoch)
              .toString()
              .substring(11, 19)
    });
    String id = docs.documentID;
    String url = await _submitImage(id);
    await Firestore.instance
        .collection('chats')
        .document(widget.chatId)
        .collection('chat')
        .document(id)
        .updateData({
      'id': id,
      'text': url,
    });
    var currentUserEmailLength = user.email.toString().length;
    String modifiedCurrentUserEmail =
        user.email.substring(0, currentUserEmailLength - 4);
    var otherUserEmailLength = widget.email.toString().length;
    String modifiedOtherUserEmail =
        widget.email.toString().substring(0, otherUserEmailLength - 4);
    print(modifiedCurrentUserEmail);
    print(modifiedOtherUserEmail);
    var unSeen = await Firestore.instance
        .collection('chats')
        .document(widget.chatId)
        .get();
    int newUnSeen = await unSeen.data['$modifiedOtherUserEmail'];
    await Firestore.instance
        .collection('chats')
        .document(widget.chatId)
        .updateData({
      '$modifiedOtherUserEmail': newUnSeen + 1,
      '$modifiedCurrentUserEmail': 0,
      'last_msg_time': Timestamp.now(),
    });
    Firestore.instance
        .collection('users')
        .document(user.email)
        .collection('contacts')
        .document(widget.chatId)
        .updateData({'last_msg_time': Timestamp.now()});
    await Firestore.instance
        .collection('users')
        .document(widget.email)
        .collection('contacts')
        .document(widget.chatId)
        .updateData({'last_msg_time': Timestamp.now()});
  }

  void _sendMessage() async {
    //FocusScope.of(context).unfocus();
    _controller.clear();
    final message = _enteredMessage.trimLeft().trimRight();
    setState(() {
      _enteredMessage = '';
    });
    final user = await FirebaseAuth.instance.currentUser();
    final userData =
        await Firestore.instance.collection('users').document(user.email).get();
    //final otherUser = await Firestore.instance.collection('users').document(user.email).collection('contacts').document(widget.chatId)
    final docs = await Firestore.instance
        .collection('chats')
        .document(widget.chatId)
        .collection('chat')
        .add({
      'id': '',
      'text': message,
      'isImage': false,
      'createdAt': Timestamp.now(),
      'userId': user.uid,
      'sentTo': widget.email,
      'username': userData['username'],
      'userImage': userData['image_url'],
      'time': DateTime.fromMillisecondsSinceEpoch(
                  Timestamp.now().millisecondsSinceEpoch)
              .toString()
              .substring(0, 10) +
          DateTime.fromMillisecondsSinceEpoch(
                  Timestamp.now().millisecondsSinceEpoch)
              .toString()
              .substring(11, 19)
    });
    String id = docs.documentID;
    await Firestore.instance
        .collection('chats')
        .document(widget.chatId)
        .collection('chat')
        .document(id)
        .updateData({
      'id': id,
    });
    var currentUserEmailLength = user.email.toString().length;
    String modifiedCurrentUserEmail =
        user.email.substring(0, currentUserEmailLength - 4);
    var otherUserEmailLength = widget.email.toString().length;
    String modifiedOtherUserEmail =
        widget.email.toString().substring(0, otherUserEmailLength - 4);
    print(modifiedCurrentUserEmail);
    print(modifiedOtherUserEmail);
    var unSeen = await Firestore.instance
        .collection('chats')
        .document(widget.chatId)
        .get();
    int newUnSeen = await unSeen.data['$modifiedOtherUserEmail'];
    await Firestore.instance
        .collection('chats')
        .document(widget.chatId)
        .updateData({
      '$modifiedOtherUserEmail': newUnSeen + 1,
      '$modifiedCurrentUserEmail': 0,
      'last_msg_time': Timestamp.now(),
    });
    Firestore.instance
        .collection('users')
        .document(user.email)
        .collection('contacts')
        .document(widget.chatId)
        .updateData({'last_msg_time': Timestamp.now()});
    await Firestore.instance
        .collection('users')
        .document(widget.email)
        .collection('contacts')
        .document(widget.chatId)
        .updateData({'last_msg_time': Timestamp.now()});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      //margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.only(left: 10, bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.newline,
              //maxLines: 1,
              maxLines: null,
              minLines: null,
              expands: true,
              cursorColor: Colors.white,
              decoration: InputDecoration(labelText: 'Type a message...'),
              onChanged: (value) {
                setState(() {
                  _enteredMessage = value;
                });
              },
            ),
          ),
          IconButton(
            //color: Theme.of(context).primaryColor,
            icon: Icon(Icons.photo_camera),
            onPressed: _pickImage,
          ),
          IconButton(
            //color: Theme.of(context).primaryColor,
            icon: Icon(
              Icons.send,
            ),
            onPressed: _enteredMessage.trim() == '' ? null : _sendMessage,
          )
        ],
      ),
    );
  }
}
