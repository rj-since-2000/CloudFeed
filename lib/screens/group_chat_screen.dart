import 'package:chatapp2/providers/messages_delete.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp2/widgets/chat/group_messages.dart';
import 'package:chatapp2/widgets/chat/group_new_message.dart';
import 'package:provider/provider.dart';

class GroupChatScreen extends StatefulWidget {
  static const routeName = '/group-messages';

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  BuildContext ctx;

  String choice;
  var isInit = true;
  String _enteredEmail;

  final _controller = new TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration.zero).then((_) {
      Provider.of<MessagesDelete>(context, listen: false).reset();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isInit) {
      //final Map<String, dynamic> args =
      //    ModalRoute.of(context).settings.arguments;
      final fbm = FirebaseMessaging();
      fbm.requestNotificationPermissions();
      fbm.configure(onMessage: (msg) {
        print(msg);
        return;
      }, onLaunch: (msg) {
        print(msg);
        return;
      }, onResume: (msg) {
        print(msg);
        return;
      });
      isInit = false;
    }
  }

  Future<String> chooseImage() async {
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

  List<String> _messageId = [];

  void getMessageId(String messageId, bool add) {
    if (add == true) {
      _messageId.add(messageId);
      Provider.of<MessagesDelete>(context, listen: false).setCount();
    } else {
      _messageId.remove(messageId);
      Provider.of<MessagesDelete>(context, listen: false).decreaseCount();
    }
  }

  Future<void> delete(String chatId) async {
    if (_messageId == null) return;
    _messageId.forEach((message) {
      Firestore.instance
          .collection('groups')
          .document(chatId)
          .collection('chat')
          .document(message)
          .updateData({'text': 'This message was deleted', 'isImage': false});
    });
    Provider.of<MessagesDelete>(context, listen: false).reset();
    _messageId.clear();
  }

  @override
  Widget build(BuildContext context) {
    ctx = context;
    final Map<String, dynamic> args = ModalRoute.of(context).settings.arguments;
    return WillPopScope(
      onWillPop: () async {
        await Navigator.of(context).pushReplacementNamed('/main');
        return false;
      },
      child: Scaffold(
        body: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    color: Theme.of(context).primaryColor,
                    height: MediaQuery.of(context).padding.top,
                    width: double.infinity,
                  ),
                  Container(
                    color: Theme.of(context).primaryColor,
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.all(0),
                      color: Theme.of(context).primaryColor,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.all(5),
                        leading: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            await Navigator.of(context)
                                .pushReplacementNamed('/main');
                          },
                        ),
                        title: Text(
                          args['group_name'],
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Consumer<MessagesDelete>(
                              builder: (ctx, messagesDelete, ch) => IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: messagesDelete.msgCount == 0 ||
                                          messagesDelete.msgCount < 0
                                      ? Colors.grey
                                      : Colors.white,
                                ),
                                onPressed: messagesDelete.msgCount == 0 ||
                                        messagesDelete.msgCount < 0
                                    ? null
                                    : () {
                                        showDialog(
                                            context: context,
                                            child: AlertDialog(
                                              actions: <Widget>[
                                                FlatButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: Text('Cancel')),
                                                FlatButton(
                                                    onPressed: () {
                                                      delete(args['chatId']);
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: Text('Delete'))
                                              ],
                                              title: Text(
                                                  'Delete ${Provider.of<MessagesDelete>(context, listen: false).msgCount} message(s)?'),
                                            ));
                                      },
                              ),
                              child: CircularProgressIndicator(),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.person_add,
                                color: Colors.white,
                              ),
                              onPressed: () => showDialog(
                                context: context,
                                child: AlertDialog(
                                  title: Text('New Member'),
                                  content: TextField(
                                    controller: _controller,
                                    decoration: InputDecoration(
                                      labelText: "Enter member's contact email",
                                    ),
                                    onChanged: (val) {
                                      _enteredEmail = val;
                                    },
                                  ),
                                  actions: <Widget>[
                                    FlatButton(
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                          final checkExistence = await Firestore
                                              .instance
                                              .collection('users')
                                              .document(_enteredEmail)
                                              .get();
                                          if (!checkExistence.exists ||
                                              checkExistence == null) {
                                            return showDialog(
                                                context: context,
                                                child: AlertDialog(
                                                  title: Text(
                                                    'ERROR',
                                                    style: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                  content: Text(
                                                      'User does not exist\nPlease check your credentials'),
                                                ));
                                          }
                                          final checkGroupExistence =
                                              await Firestore.instance
                                                  .collection('groups')
                                                  .document(args['chatId'])
                                                  .collection('members')
                                                  .document(_enteredEmail)
                                                  .get();

                                          if (checkGroupExistence.exists) {
                                            return showDialog(
                                                context: context,
                                                child: AlertDialog(
                                                  title: Text(
                                                    'ERROR',
                                                    style: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                  content: Text(
                                                      'User is already a member of this group'),
                                                ));
                                          } else {
                                            await Firestore.instance
                                                .collection('users')
                                                .document(_enteredEmail)
                                                .collection('groups')
                                                .document(args['chatId'])
                                                .setData({
                                              'group_name': args['group_name'],
                                              'id': args['chatId'],
                                              'image_url': args['image_url'],
                                            });
                                            final newMemberDocs =
                                                await Firestore.instance
                                                    .collection('users')
                                                    .document(_enteredEmail)
                                                    .get();
                                            await Firestore.instance
                                                .collection('groups')
                                                .document(args['chatId'])
                                                .collection('members')
                                                .document(_enteredEmail)
                                                .setData({
                                              'email': _enteredEmail,
                                              'username': newMemberDocs
                                                  .data['username'],
                                            });
                                            final docs = await Firestore
                                                .instance
                                                .collection('groups')
                                                .document(args['chatId'])
                                                .collection('chat')
                                                .add({
                                              'id': '',
                                              'text': _enteredEmail,
                                              'isImage': false,
                                              'createdAt': Timestamp.now(),
                                              'userId': '',
                                              'username': newMemberDocs
                                                  .data['username'],
                                              'userImage': '',
                                              'time': DateTime.fromMillisecondsSinceEpoch(
                                                          Timestamp.now()
                                                              .millisecondsSinceEpoch)
                                                      .toString()
                                                      .substring(0, 10) +
                                                  DateTime.fromMillisecondsSinceEpoch(
                                                          Timestamp.now()
                                                              .millisecondsSinceEpoch)
                                                      .toString()
                                                      .substring(11, 19)
                                            });
                                            String id = docs.documentID;
                                            await Firestore.instance
                                                .collection('groups')
                                                .document(args['chatId'])
                                                .collection('chat')
                                                .document(id)
                                                .updateData({
                                              'id': id,
                                            });
                                          }
                                        },
                                        child: Text('Add'))
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    FocusScopeNode currentFocus = FocusScope.of(context);

                    if (!currentFocus.hasPrimaryFocus) {
                      currentFocus.unfocus();
                    }
                  },
                  child: GroupMessages(args['chatId'], getMessageId),
                ),
              ),
              Consumer<MessagesDelete>(
                builder: (ctx, messagesDelete, _) => messagesDelete.msgCount > 0
                    ? Container(
                        padding: EdgeInsets.only(left: 20),
                        alignment: Alignment.centerLeft,
                        color: Theme.of(context).primaryColor,
                        width: double.infinity,
                        child: Row(
                          children: <Widget>[
                            Text(
                                '${messagesDelete.msgCount} message(s) selected'),
                            Spacer(),
                            FlatButton(
                                onPressed: () {
                                  Provider.of<MessagesDelete>(context,
                                          listen: false)
                                      .reset();
                                  setState(() {
                                    _messageId.clear();
                                  });
                                },
                                child: Text('CANCEL'))
                          ],
                        ),
                      )
                    : Container(height: 0),
              ),
              Container(
                  constraints: BoxConstraints(maxHeight: 80),
                  child: GroupNewMessage(args['chatId'], chooseImage))
            ],
          ),
        ),
      ),
    );
  }
}
