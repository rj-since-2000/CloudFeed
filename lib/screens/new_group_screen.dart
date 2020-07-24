import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

class NewGroupScreen extends StatefulWidget {
  static const routeName = '/new-group-screen';

  @override
  _NewGroupScreenState createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  var pageSelection = 1;
  File image;
  final _controller = new TextEditingController();
  var groupName = '';
  final _key = GlobalKey<FormState>();

  List<Map<String, dynamic>> participants = [];

  void addParticipant(String email, String username, String imageUrl) {
    participants.add({
      'email': email,
      'username': username,
      'imageUrl': imageUrl,
    });
  }

  void removeParticipant(String email) {
    participants.removeWhere((item) => item['email'] == email);
  }

  void getImage(File image) {
    this.image = image;
  }

  @override
  Widget build(BuildContext context) {
    return pageSelection == 1
        ? Scaffold(
            appBar: AppBar(
              title: Text('Add Participants'),
            ),
            floatingActionButton: CircleAvatar(
              radius: 25,
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                  color: Colors.white,
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () {
                    if (participants.length == 0)
                      showDialog(
                        context: context,
                        child: AlertDialog(
                          title: Text('No Participants!'),
                          content: Text('Add a participant to continue'),
                          actions: <Widget>[
                            FlatButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Okay'),
                            )
                          ],
                        ),
                      );
                    if (participants.length != 0)
                      setState(() {
                        pageSelection = pageSelection + 1;
                      });
                  }),
            ),
            body: FutureBuilder(
              future: FirebaseAuth.instance.currentUser(),
              builder: (ctx, futureSnapshot) {
                if (futureSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return StreamBuilder(
                  stream: Firestore.instance
                      .collection('users')
                      .document(futureSnapshot.data.email)
                      .collection('contacts')
                      .snapshots(),
                  builder: (ctx, chatSnapshot) {
                    if (chatSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final chatDocs = chatSnapshot.data.documents;
                    if (chatDocs.length == 0)
                      return Container(
                        alignment: Alignment.center,
                        child: Text('You have no contacts!'),
                      );
                    return Scrollbar(
                      child: ListView.builder(
                        //reverse: true,
                        itemCount: chatDocs.length,
                        itemBuilder: (ctx, index) => FutureBuilder(
                          future: Firestore.instance
                              .collection('users')
                              .document(chatDocs[index]['email'])
                              .get(),
                          builder: (ctx, snapShot) {
                            if (snapShot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                height: 80,
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            var imageUrl = snapShot.data['image_url'];
                            return Column(
                              children: <Widget>[
                                if (index == 0) SizedBox(height: 7),
                                CheckList(
                                    imageUrl,
                                    chatDocs[index]['username'],
                                    chatDocs[index]['email'],
                                    addParticipant,
                                    removeParticipant),
                                const Divider(
                                  indent: 80,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        : Scaffold(
            appBar: AppBar(title: Text('Add Group Info')),
            body: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SizedBox(height: 20),
                        GroupImageEdit(getImage),
                        SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Form(
                            key: _key,
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Group Name',
                                suffixIcon: Icon(Icons.edit),
                              ),
                              controller: _controller,
                              textInputAction: TextInputAction.done,
                              onChanged: (value) {
                                groupName = value;
                              },
                              validator: (value) {
                                if (value == '' || value == null)
                                  return 'Add a group name';
                                if (value.length < 4)
                                  return 'Group name should be atleast 4 characters long';
                                return null;
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        SelectedContacts(participants),
                      ],
                    ),
                  ),
                ),
                if (pageSelection == 3)
                  Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    color: Colors.black54,
                    child: Center(
                      child: Card(
                        elevation: 5,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15),
                          margin: EdgeInsets.all(5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text(
                                'Creating Group',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            floatingActionButton: CircleAvatar(
              radius: 25,
              child: IconButton(
                icon: Icon(Icons.done),
                onPressed: pageSelection == 3
                    ? null
                    : () async {
                        _key.currentState.save();
                        FocusScope.of(context).requestFocus(new FocusNode());
                        var check = _key.currentState.validate();
                        if (check == true && image == null) {
                          check = false;
                          showDialog(
                              context: context,
                              child: AlertDialog(
                                content:
                                    Text('Please add a group profile image'),
                              ));
                        }
                        if (check == true) {
                          setState(() {
                            pageSelection++;
                          });
                          final currentUser =
                              await FirebaseAuth.instance.currentUser();
                          final docRef = await Firestore.instance
                              .collection('groups')
                              .document()
                              .get();
                          final docId = docRef.documentID;

                          final ref = FirebaseStorage.instance
                              .ref()
                              .child('group_images')
                              .child(docId + '.jpg');
                          await ref.putFile(image).onComplete;
                          final url = await ref.getDownloadURL();
                          await Firestore.instance
                              .collection('groups')
                              .document(docId)
                              .setData({
                            'group_name': groupName,
                            'image_url': url,
                            'id': docId,
                            'msg_count': 0,
                            'last_msg_time': DateTime.now(),
                          });
                          final userdocref = await Firestore.instance
                              .collection('users')
                              .document(currentUser.email)
                              .get();
                          Firestore.instance
                              .collection('groups')
                              .document(docId)
                              .collection('members')
                              .document(currentUser.email)
                              .setData({
                            'username': userdocref.data['username'],
                            'email': currentUser.email
                          });

                          for (int i = 0; i < participants.length; i++) {
                            await Firestore.instance
                                .collection('groups')
                                .document(docId)
                                .collection('members')
                                .document(participants[i]['email'])
                                .setData({
                              'username': participants[i]['username'],
                              'email': participants[i]['email']
                            });
                          }
                          await Firestore.instance
                              .collection('users')
                              .document(currentUser.email)
                              .collection('groups')
                              .document(docId)
                              .setData({
                            'group_name': groupName,
                            'id': docId,
                            'image_url': url,
                            'seen': 0,
                          });
                          for (int i = 0; i < participants.length; i++) {
                            var contactEmail = participants[i]['email'];
                            await Firestore.instance
                                .collection('users')
                                .document(contactEmail)
                                .collection('groups')
                                .document(docId)
                                .setData({
                              'group_name': groupName,
                              'id': docId,
                              'image_url': url,
                              'seen': 0,
                            });
                          }
                          Navigator.of(context).pop();
                        }
                      },
              ),
            ),
          );
  }
}

class CheckList extends StatefulWidget {
  final imageUrl;
  final username;
  final email;
  final Function add;
  final Function remove;
  CheckList(this.imageUrl, this.username, this.email, this.add, this.remove);
  @override
  _CheckListState createState() => _CheckListState();
}

class _CheckListState extends State<CheckList> {
  var checkValue = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(widget.imageUrl),
      ),
      title: Text(
        widget.username,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      subtitle: Text(widget.email),
      trailing: Checkbox(
          checkColor: Theme.of(context).primaryColorDark,
          value: checkValue,
          onChanged: (value) {
            setState(() {
              value == true
                  ? widget.add(widget.email, widget.username, widget.imageUrl)
                  : widget.remove(widget.email);
              checkValue = value;
            });
          }),
    );
  }
}

class GroupImageEdit extends StatefulWidget {
  final Function getImage;
  GroupImageEdit(this.getImage);
  @override
  _GroupImageEditState createState() => _GroupImageEditState();
}

class _GroupImageEditState extends State<GroupImageEdit> {
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
    setState(() {
      _pickedImage = pickedImageFile;
    });
    widget.getImage(_pickedImage);
    //  final user = await FirebaseAuth.instance.currentUser();
    //  final uid = user.uid;
    //  final newref =
    //      FirebaseStorage.instance.ref().child('user_image').child(uid + '.jpg');
    //  await newref.putFile(_pickedImage).onComplete;
    //  final url = await newref.getDownloadURL();
    //  await Firestore.instance
    //      .collection('users')
    //      .document(user.email)
    //      .updateData({'image_url': url});
    //  imageUrl = url;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Stack(alignment: Alignment.center, children: <Widget>[
            CircleAvatar(
              radius: 106,
              backgroundColor: Theme.of(context).accentColor,
            ),
            CircleAvatar(
              radius: 104,
              backgroundColor: Colors.white,
            ),
            if (_pickedImage != null)
              CircleAvatar(
                radius: 100,
                backgroundImage: FileImage(_pickedImage),
              ),
          ]),
          SizedBox(height: 10),
          FlatButton.icon(
            onPressed: _pickImage,
            icon: Icon(Icons.add_a_photo),
            label: Text('Add Group Image'),
          ),
        ],
      ),
    );
  }
}

class SelectedContacts extends StatefulWidget {
  final List<Map<String, dynamic>> participants;
  SelectedContacts(this.participants);
  @override
  _SelectedContactsState createState() => _SelectedContactsState();
}

class _SelectedContactsState extends State<SelectedContacts> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Scrollbar(
        child: ListView.builder(
            itemCount: widget.participants.length,
            itemBuilder: (ctx, index) => ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(
                      widget.participants[index]['imageUrl'],
                    ),
                  ),
                  title: Text(widget.participants[index]['username']),
                  subtitle: Text(widget.participants[index]['email']),
                )),
      ),
    );
  }
}
