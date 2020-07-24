import 'package:chatapp2/providers/messages_delete.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:chatapp2/widgets/chat/messages.dart';
import 'package:chatapp2/widgets/chat/new_message.dart';

class ChatScreen extends StatefulWidget {
  static const routeName = '/messages';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  BuildContext ctx;
  var isInit = true;
  String choice;
  FocusScopeNode currentFocus;

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
          .collection('chats')
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
    //final deleteData = Provider.of<MessagesDelete>(context, listen: false);
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
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
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
                            CircleAvatar(
                              radius: 25,
                              backgroundImage: NetworkImage(args['image_url']),
                            )
                          ],
                        ),
                        title: Text(
                          args['username'],
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        trailing: Consumer<MessagesDelete>(
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
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text('Cancel')),
                                            FlatButton(
                                                onPressed: () {
                                                  delete(args['chatId']);
                                                  Navigator.of(context).pop();
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
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: GestureDetector(
                    onTap: () {
                      currentFocus = FocusScope.of(context);

                      if (!currentFocus.hasPrimaryFocus) {
                        currentFocus.unfocus();
                      }
                    },
                    child:
                        Messages(args['chatId'], args['email'], getMessageId)),
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
                  child: NewMessage(args['chatId'], args['email'], chooseImage))
            ],
          ),
        ),
      ),
    );
  }
}
