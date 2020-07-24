import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chatapp2/screens/new_group_screen.dart';

import 'package:chatapp2/screens/edit_profile_screen.dart';
import 'package:chatapp2/widgets/chats.dart';
import 'package:chatapp2/widgets/groups.dart';

class ContactsScreen extends StatefulWidget{
  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _controller = new TextEditingController();

  var _enteredEmail;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 0)).then((_) {
      while (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
    _saveDeviceToken();
  }

  
  /// Get the token, save it to the database for current user
  _saveDeviceToken() async {
    final Firestore _db = Firestore.instance;
    final FirebaseMessaging _fcm = FirebaseMessaging();
    // Get the current user
    final user = await FirebaseAuth.instance.currentUser();
    final email = user.email;
    var token = '0';
    // FirebaseUser user = await _auth.currentUser();

    // Get the token for this device
    String fcmToken = await _fcm.getToken();
    //var token = _fcm.onTokenRefresh;
    // Save it to Firestore
    if (fcmToken != null) {
      var tokens = _db
          .collection('users')
          .document(email)
          .collection('tokens')
          .document(fcmToken);

      await tokens.setData({
        'token': fcmToken,
        'createdAt': FieldValue.serverTimestamp(), // optional
        'platform': Platform.operatingSystem // optional
      });
    }
  }

  void alertBox(String msg) {
    showDialog(
        context: context,
        child: AlertDialog(
          title: Text(
            'ERROR',
            style: TextStyle(color: Colors.red),
          ),
          content: Text(msg),
        ));
  }

  Future<void> addNewContact() async {
    if (_enteredEmail == null) return;
    final snapShot = await Firestore.instance
        .collection('users')
        .document(_enteredEmail)
        .get();
    if (!snapShot.exists || snapShot == null) {
      alertBox('User does not exist!\nCheck your credentials');
      return;
    }
    final currentuser = await FirebaseAuth.instance.currentUser();
    if (_enteredEmail == currentuser.email) {
      alertBox('Sorry! You cannot add yourself');
      return;
    }
    final checkIfNewUser = await Firestore.instance
        .collection('users')
        .document(currentuser.email)
        .collection('contacts')
        .getDocuments();
    if (!checkIfNewUser.documents.isEmpty) {
      final userContacts = await Firestore.instance
          .collection('users')
          .document(currentuser.email)
          .collection('contacts')
          .where('email', isEqualTo: _enteredEmail)
          .getDocuments();
      final foundNot = userContacts.documents.isEmpty;
      if (!foundNot) {
        alertBox('User already exists in your contacts!');
        return;
      }
    }
    //final check = await userContacts.data.documents
    //    .forEach((contact) => contact['email'] == _enteredEmail);
    final userDocs = await Firestore.instance
        .collection('users')
        .document(currentuser.email)
        .get();
    final newUserDocs = await Firestore.instance
        .collection('users')
        .document(_enteredEmail)
        .get();
    final add = await Firestore.instance
        .collection('users')
        .document(_enteredEmail)
        .collection('contacts')
        .add({
      'username': userDocs['username'],
    });
    final id = add.documentID;
    await Firestore.instance
        .collection('users')
        .document(currentuser.email)
        .collection('contacts')
        .document(id)
        .setData({
      'username': newUserDocs['username'],
      'chatId': id,
      'email': _enteredEmail,
      'image_url': newUserDocs['image_url'],
      'last_msg_time': Timestamp.now(),
    });
    await Firestore.instance
        .collection('users')
        .document(_enteredEmail)
        .collection('contacts')
        .document(id)
        .setData({
      'chatId': id,
      'username': userDocs['username'],
      'email': currentuser.email,
      'image_url': userDocs['image_url'],
      'last_msg_time': Timestamp.now(),
    });
    var currentUserEmailLength = currentuser.email.length;
    var otherUserEmailLength = _enteredEmail.toString().length;

    await Firestore.instance.collection('chats').document(id).setData(
      {
        '${currentuser.email.substring(0, currentUserEmailLength - 4)}': 0,
        '${_enteredEmail.toString().substring(0, otherUserEmailLength - 4)}': 0,
        'last_msg_time': Timestamp.now(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).primaryColor,
            bottom: TabBar(tabs: [
              Tab(
                text: 'CHATS',
              ),
              Tab(text: 'GROUPS'),
            ]),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Cloud',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                  textAlign: TextAlign.center,
                ),
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                  child: Text(
                    'Feed',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      letterSpacing: 0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
            actions: [
              DropdownButton(
                underline: Container(height: 0),
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).primaryIconTheme.color,
                ),
                items: [
                  DropdownMenuItem(
                    child: Container(
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.exit_to_app),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                    value: 'logout',
                  ),
                  DropdownMenuItem(
                    child: Container(
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.account_circle),
                          SizedBox(width: 8),
                          Text('Profile'),
                        ],
                      ),
                    ),
                    value: 'profile',
                  ),
                  DropdownMenuItem(
                    child: Container(
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.group_add),
                          SizedBox(width: 8),
                          Text('New Group'),
                        ],
                      ),
                    ),
                    value: 'new group',
                  )
                ],
                onChanged: (itemIdentifier) {
                  if (itemIdentifier == 'logout') {
                    FirebaseAuth.instance.signOut();
                  }
                  if (itemIdentifier == 'profile') {
                    Navigator.of(context)
                        .pushNamed(EditProfileScreen.routeName);
                  }
                  if (itemIdentifier == 'new group') {
                    Navigator.of(context).pushNamed(NewGroupScreen.routeName);
                  }
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Theme.of(context).primaryColor,
            child: Icon(
              Icons.add,
              size: 25,
              color: Theme.of(context).accentColor,
            ),
            onPressed: () => showDialog(
              context: context,
              child: AlertDialog(
                title: Text('New Contact'),
                content: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Enter contact email',
                  ),
                  onChanged: (val) {
                    _enteredEmail = val;
                  },
                ),
                actions: <Widget>[
                  FlatButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await addNewContact();
                      },
                      child: Text('Add'))
                ],
              ),
            ),
          ) /*CircleAvatar(
            radius: 25,
            backgroundColor: Theme.of(context).primaryColor,
            child: IconButton(
              color: Colors.white,
              icon: Icon(Icons.add),
              onPressed: () => showDialog(
                  context: context,
                  child: AlertDialog(
                    title: Text('New Contact'),
                    content: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: 'Enter contact email',
                      ),
                      onChanged: (val) {
                        _enteredEmail = val;
                      },
                    ),
                    actions: <Widget>[
                      FlatButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await addNewContact();
                          },
                          child: Text('Add'))
                    ],
                  )),
              tooltip: 'New Contact',
            ),
          ),*/
          ,
          body: TabBarView(
            children: [
              Chats(),
              Groups(),
            ],
          ),
        ),
      ),
    );
  }
}
