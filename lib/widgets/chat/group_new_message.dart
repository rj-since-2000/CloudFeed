import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';


class GroupNewMessage extends StatefulWidget {
  GroupNewMessage(this.chatId, this.chooseImage);
  final chatId;
  final Function chooseImage;
  @override
  _GroupNewMessageState createState() => _GroupNewMessageState();
}

class _GroupNewMessageState extends State<GroupNewMessage> {
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
                                color: Theme.of(context).accentColor,
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
                                color: Theme.of(context).accentColor,
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
        .collection('groups')
        .document(widget.chatId)
        .collection('chat')
        .add({
      'id': '',
      'chatId': widget.chatId,
      'text': '',
      'isImage': true,
      'createdAt': Timestamp.now(),
      'userId': user.uid,
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
        .collection('groups')
        .document(widget.chatId)
        .collection('chat')
        .document(id)
        .updateData({
      'id': id,
      'text': url,
    });
    final groupInfo = await Firestore.instance
        .collection('groups')
        .document(widget.chatId)
        .get();
    final msgCount = groupInfo.data['msg_count'];
    await Firestore.instance
        .collection('groups')
        .document(widget.chatId)
        .updateData(
            {'msg_count': msgCount + 1, 'last_msg_time': Timestamp.now()});
    final userSeen = await Firestore.instance
        .collection('users')
        .document(user.email)
        .collection('groups')
        .document(widget.chatId)
        .get();
    final seenCount = userSeen.data['seen'];
    await Firestore.instance
        .collection('users')
        .document(user.email)
        .collection('groups')
        .document(widget.chatId)
        .updateData({'seen': seenCount + 1});
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
    final docs = await Firestore.instance
        .collection('groups')
        .document(widget.chatId)
        .collection('chat')
        .add({
      'id': '',
      'chatId': widget.chatId,
      'text': message,
      'isImage': false,
      'createdAt': Timestamp.now(),
      'userId': user.uid,
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
        .collection('groups')
        .document(widget.chatId)
        .collection('chat')
        .document(id)
        .updateData({
      'id': id,
    });
    final groupInfo = await Firestore.instance
        .collection('groups')
        .document(widget.chatId)
        .get();
    final msgCount = groupInfo.data['msg_count'];
    await Firestore.instance
        .collection('groups')
        .document(widget.chatId)
        .updateData(
            {'msg_count': msgCount + 1, 'last_msg_time': Timestamp.now()});
    final userSeen = await Firestore.instance
        .collection('users')
        .document(user.email)
        .collection('groups')
        .document(widget.chatId)
        .get();
    final seenCount = userSeen.data['seen'];
    await Firestore.instance
        .collection('users')
        .document(user.email)
        .collection('groups')
        .document(widget.chatId)
        .updateData({'seen': seenCount + 1});
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
