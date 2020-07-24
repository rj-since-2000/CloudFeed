import 'package:chatapp2/providers/messages_delete.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chatapp2/screens/chat_screen.dart';
import 'package:chatapp2/screens/image_view.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class Chats extends StatefulWidget {
  @override
  _ChatsState createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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
              .orderBy('last_msg_time', descending: true)
              .snapshots(),
          //  .orderBy(
          //    'createdAt',
          //    descending: true,
          //  )
          //  .snapshots(),
          builder: (ctx, chatSnapshot) {
            if (chatSnapshot.connectionState == ConnectionState.waiting) {
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
            return ContactList(chatDocs, futureSnapshot);
          },
        );
      },
    );
  }
}

class ContactList extends StatefulWidget {
  final List<dynamic> chatDocs;
  final futureSnapshot;
  ContactList(this.chatDocs, this.futureSnapshot);
  @override
  _ContactListState createState() => _ContactListState(chatDocs, chatDocs);
}

class _ContactListState extends State<ContactList> {
  _ContactListState(this.dummyList, this.chatDocs);
  TextEditingController _controller;
  List<dynamic> searchList = [];
  List<dynamic> dummyList;
  List<dynamic> chatDocs;

  @override
  Widget build(BuildContext context) {
    return CupertinoScrollbar(
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            automaticallyImplyLeading: false,
            floating: true,
            //backgroundColor: Colors.white,
            title: TextField(
              textInputAction: TextInputAction.search,
              showCursor: false,
              keyboardType: TextInputType.emailAddress,
              maxLines: 1,
              decoration: InputDecoration(
                labelText: 'Search Contacts',
                suffixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (value) {
                searchList.clear();
                //widget.chatDocs.clear();
                if (value != null && value != '') {
                  dummyList.forEach((item) {
                    if (item['username'].contains(value) ||
                        item['email'].contains(value)) {
                      searchList.add(item);
                    }
                  });
                  setState(() {
                    chatDocs = searchList;
                  });
                  return;
                } else {
                  setState(() {
                    chatDocs = dummyList;
                  });
                }
              },
              controller: _controller,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, index) {
                if (index == chatDocs.length) return SizedBox(height: 80);
                String imageUrl = widget.chatDocs[index]['image_url'];
                return InkWell(
                  onTap: () => Navigator.of(context, rootNavigator: true)
                      .pushNamed(ChatScreen.routeName, arguments: {
                    'chatId': chatDocs[index]['chatId'],
                    'username': chatDocs[index]['username'],
                    'email': chatDocs[index]['email'],
                    'image_url': imageUrl,
                  }),
                  child: Column(
                    children: <Widget>[
                      if (index == 0) SizedBox(height: 8),
                      ListTile(
                        key: ValueKey(chatDocs[index]['email']),
                        dense: true,
                        leading: InkWell(
                          onTap: () => showDialog(
                              context: context,
                              child: AlertDialog(
                                elevation: 10,
                                contentPadding: EdgeInsets.all(0),
                                titlePadding: EdgeInsets.all(0),
                                //title: Text('New Contact'),
                                content: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.75,
                                  height:
                                      MediaQuery.of(context).size.width * 0.75 +
                                          40,
                                  child: Card(
                                    margin: EdgeInsets.all(0),
                                    child: Column(
                                      children: <Widget>[
                                        Stack(
                                          alignment: Alignment.topCenter,
                                          children: <Widget>[
                                            Container(
                                              width: double.infinity,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.75,
                                              child: InkWell(
                                                onTap: () {
                                                  Navigator.of(context).pop();
                                                  Navigator.of(context)
                                                      .pushNamed(
                                                          ImageView.routeName,
                                                          arguments: imageUrl);
                                                },
                                                child: Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Container(
                                                padding: EdgeInsets.all(10),
                                                color: Colors.black54,
                                                height: 40,
                                                width: double.infinity,
                                                child: Text(
                                                  chatDocs[index]['username'],
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ))
                                          ],
                                        ),
                                        Container(
                                          padding: EdgeInsets.only(bottom: 10),
                                          color: Theme.of(context).primaryColor,
                                          height: 40,
                                          width: double.infinity,
                                          child: IconButton(
                                              icon: Icon(Icons.message),
                                              iconSize: 30,
                                              color:
                                                  Theme.of(context).accentColor,
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                Navigator.of(context).pushNamed(
                                                    ChatScreen.routeName,
                                                    arguments: {
                                                      'chatId': chatDocs[index]
                                                          ['chatId'],
                                                      'username':
                                                          chatDocs[index]
                                                              ['username'],
                                                      'email': chatDocs[index]
                                                          ['email'],
                                                      'image_url': imageUrl,
                                                    });
                                              }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )),
                          child: CircleAvatar(
                            radius: 25,
                            backgroundImage: NetworkImage(imageUrl),
                          ),
                        ),
                        title: Text(
                          chatDocs[index]['username'],
                          style: TextStyle(fontSize: 18),
                        ),
                        subtitle: Text(chatDocs[index]['email']),
                        trailing: Container(
                          alignment: Alignment.topRight,
                          //color: Colors.white10,
                          constraints:
                              BoxConstraints(maxWidth: 70, maxHeight: 60),
                          child: StreamBuilder(
                              stream: Firestore.instance
                                  .collection('chats')
                                  .document(chatDocs[index]['chatId'])
                                  .snapshots(),
                              builder: (ctx, chatDataSnapshot) {
                                if (chatDataSnapshot.connectionState ==
                                    ConnectionState.waiting)
                                  return Container(
                                    width: 0,
                                  );
                                if (chatDataSnapshot.error != null) return null;
                                try {
                                  int countUnSeen = chatDataSnapshot.data[widget
                                      .futureSnapshot.data.email
                                      .toString()
                                      .substring(
                                          0,
                                          widget.futureSnapshot.data.email
                                                  .toString()
                                                  .length -
                                              4)];
                                  Timestamp datetimeINtimestamp =
                                      chatDataSnapshot.data['last_msg_time'];
                                  DateTime datetime =
                                      DateTime.fromMillisecondsSinceEpoch(
                                          datetimeINtimestamp
                                              .millisecondsSinceEpoch);
                                  Duration difference =
                                      datetime.difference(datetime);
                                  String newDateTime;
                                  if (DateTime.now().day - datetime.day == 1 &&
                                      DateTime.now().month == datetime.month &&
                                      DateTime.now().year == datetime.year)
                                    newDateTime = 'Yesterday';
                                  else if (difference.inHours < 24 &&
                                      DateTime.now().day == datetime.day &&
                                      DateTime.now().month == datetime.month &&
                                      DateTime.now().year == datetime.year)
                                    newDateTime = DateFormat('HH:mm')
                                        .format(datetime)
                                        .toString();
                                  else
                                    newDateTime = DateFormat('dd/MM/yy')
                                        .format(datetime)
                                        .toString();
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        newDateTime,
                                        style: TextStyle(
                                            color: countUnSeen > 0
                                                ? Theme.of(context).accentColor
                                                : Colors.grey,
                                            fontSize: 13),
                                      ),
                                      SizedBox(height: 5),
                                      if (countUnSeen <= 99 && countUnSeen > 0)
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor:
                                              Theme.of(context).accentColor,
                                          child: Text(
                                            '$countUnSeen',
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      else if (countUnSeen > 0)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor:
                                                  Theme.of(context).accentColor,
                                              child: Text(
                                                '99',
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: Theme.of(context)
                                                  .scaffoldBackgroundColor,
                                              child: Text(
                                                '+',
                                                style: TextStyle(
                                                    fontSize: 22,
                                                    color: Theme.of(context)
                                                        .accentColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  );
                                } catch (err) {
                                  return Container(width: 0);
                                }
                              }),
                        ),
                      ),
                      const Divider(
                        indent: 80,
                      ),
                    ],
                  ),
                );
              },
              childCount: chatDocs.length + 1,
            ),
          ),
        ],
      ),
    );
  }
}
