import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:chatapp2/screens/group_chat_screen.dart';
import 'package:chatapp2/screens/image_view.dart';

class Groups extends StatefulWidget {
  @override
  _GroupsState createState() => _GroupsState();
}

class _GroupsState extends State<Groups> {
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
              .collection('groups')
              .snapshots(),
          builder: (ctx, groupsSnapshot) {
            if (groupsSnapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            final groupsDocs = groupsSnapshot.data.documents;

            if (groupsDocs.length == 0)
              return Container(
                alignment: Alignment.center,
                child: Text('You have no groups!'),
              );
            /* DateTime currentTime = DateTime.now();
                      for (int i = 0; i < groupsDocs.length; i++) {
                        Duration min = currentTime.difference(groupsDocs[i]['last_msg_time']);
                        int position = i;
                        for (int j = i + 1; j < groupsDocs.length; j++) {
                          if (currentTime.difference(groupsDocs[j]['last_msg_time']) < min){
                            min = groupsDocs[j]['last_msg_time'];
                            position = j;
                          }
                        }
                        var temp = groupsDocs[i];
                        groupsDocs[i] = groupsDocs[position];
                        groupsDocs[position] = temp;  
                      }*/
            return GroupList(futureSnapshot, groupsDocs);
          },
        );
      },
    );
  }
}

class GroupList extends StatefulWidget {
  final groupsDocs;
  final futureSnapshot;
  GroupList(this.futureSnapshot, this.groupsDocs);
  @override
  _GroupListState createState() => _GroupListState(groupsDocs, groupsDocs);
}

class _GroupListState extends State<GroupList> {
  _GroupListState(this.groupsDocs, this.dummyList);
  TextEditingController _controller;
  List<dynamic> searchList = [];
  List<dynamic> dummyList;
  List<dynamic> groupsDocs;

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
                labelText: 'Search Groups',
                suffixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (value) {
                searchList.clear();
                //widget.chatDocs.clear();
                if (value != null && value != '') {
                  dummyList.forEach((item) {
                    if (item['group_name'].contains(value)) {
                      searchList.add(item);
                    }
                  });
                  setState(() {
                    groupsDocs = searchList;
                  });
                  return;
                } else {
                  setState(() {
                    groupsDocs = dummyList;
                  });
                }
              },
              controller: _controller,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, index) {
                if (index == groupsDocs.length) return SizedBox(height: 80);
                return InkWell(
                  onTap: () => Navigator.of(context)
                      .pushNamed(GroupChatScreen.routeName, arguments: {
                    'chatId': groupsDocs[index]['id'],
                    'group_name': groupsDocs[index]['group_name'],
                    'image_url': groupsDocs[index]['image_url'],
                  }),
                  child: Column(
                    children: <Widget>[
                      if (index == 0) SizedBox(height: 8),
                      ListTile(
                        key: ValueKey(groupsDocs[index]['id']),
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
                                                          arguments: groupsDocs[
                                                                  index]
                                                              ['image_url']);
                                                },
                                                child: Image.network(
                                                  groupsDocs[index]
                                                      ['image_url'],
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
                                                  groupsDocs[index]
                                                      ['group_name'],
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
                                          child: Row(children: <Widget>[
                                            Expanded(
                                              child: IconButton(
                                                  icon: Icon(Icons.info),
                                                  iconSize: 30,
                                                  color: Theme.of(context)
                                                      .accentColor,
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    showDialog(
                                                        context: context,
                                                        child: AlertDialog(
                                                          contentPadding:
                                                              EdgeInsets.all(5),
                                                          title: Text(
                                                            'Group Members',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400),
                                                          ),
                                                          titlePadding:
                                                              EdgeInsets
                                                                  .symmetric(
                                                                      vertical:
                                                                          10,
                                                                      horizontal:
                                                                          10),
                                                          content: Container(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.9,
                                                            height: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height *
                                                                0.4,
                                                            child:
                                                                FutureBuilder(
                                                              future: Firestore
                                                                  .instance
                                                                  .collection(
                                                                      'groups')
                                                                  .document(
                                                                      groupsDocs[
                                                                              index]
                                                                          [
                                                                          'id'])
                                                                  .collection(
                                                                      'members')
                                                                  .getDocuments(),
                                                              builder: (ctx,
                                                                  dataSnapShot) {
                                                                if (dataSnapShot
                                                                        .connectionState ==
                                                                    ConnectionState
                                                                        .waiting)
                                                                  return Center(
                                                                      child:
                                                                          CircularProgressIndicator());
                                                                var memberDocs =
                                                                    dataSnapShot
                                                                        .data
                                                                        .documents;
                                                                return ListView
                                                                    .builder(
                                                                  //reverse: true,
                                                                  itemCount:
                                                                      memberDocs
                                                                          .length,
                                                                  itemBuilder: (ctx,
                                                                          index) =>
                                                                      FutureBuilder(
                                                                    future: Firestore
                                                                        .instance
                                                                        .collection(
                                                                            'users')
                                                                        .document(memberDocs[index]
                                                                            [
                                                                            'email'])
                                                                        .get(),
                                                                    builder: (ctx,
                                                                        snapShot) {
                                                                      if (snapShot
                                                                              .connectionState ==
                                                                          ConnectionState
                                                                              .waiting) {
                                                                        return Container(
                                                                          height:
                                                                              80,
                                                                          width:
                                                                              double.infinity,
                                                                          alignment:
                                                                              Alignment.center,
                                                                          child:
                                                                              Center(
                                                                            child:
                                                                                CircularProgressIndicator(),
                                                                          ),
                                                                        );
                                                                      }
                                                                      var imageUrl =
                                                                          snapShot
                                                                              .data['image_url'];
                                                                      return Column(
                                                                        children: <
                                                                            Widget>[
                                                                          if (index ==
                                                                              0)
                                                                            SizedBox(height: 10),
                                                                          ListTile(
                                                                            dense:
                                                                                true,
                                                                            leading:
                                                                                CircleAvatar(
                                                                              radius: 25,
                                                                              backgroundImage: NetworkImage(imageUrl),
                                                                            ),
                                                                            title:
                                                                                Text(
                                                                              snapShot.data['username'],
                                                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                                            ),
                                                                            subtitle:
                                                                                Text(memberDocs[index]['email']),
                                                                          ),
                                                                          const Divider(),
                                                                        ],
                                                                      );
                                                                    },
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ));
                                                  }),
                                            ),
                                            Expanded(
                                              child: IconButton(
                                                icon: Icon(Icons.message),
                                                iconSize: 30,
                                                color: Theme.of(context)
                                                    .accentColor,
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  Navigator.of(context)
                                                      .pushNamed(
                                                    GroupChatScreen.routeName,
                                                    arguments: {
                                                      'chatId':
                                                          groupsDocs[index]
                                                              ['id'],
                                                      'group_name':
                                                          groupsDocs[index]
                                                              ['group_name'],
                                                      'image_url':
                                                          groupsDocs[index]
                                                              ['image_url'],
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          ]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )),
                          child: CircleAvatar(
                            radius: 25,
                            backgroundImage:
                                NetworkImage(groupsDocs[index]['image_url']),
                          ),
                        ),
                        title: Text(
                          groupsDocs[index]['group_name'],
                          style: TextStyle(fontSize: 18),
                        ),
                        subtitle: StreamBuilder(
                            stream: Firestore.instance
                                .collection('groups')
                                .document(groupsDocs[index]['id'])
                                .collection('members')
                                .snapshots(),
                            builder: (ctx, membersSnaps) {
                              try {
                                int membersList =
                                    membersSnaps.data.documents.length;
                                return Text('$membersList members');
                              } catch (err) {
                                return Text('');
                              }
                            }),
                        trailing: Container(
                          alignment: Alignment.topRight,
                          //color: Colors.white10,
                          constraints:
                              BoxConstraints(maxWidth: 70, maxHeight: 60),
                          child: StreamBuilder(
                              stream: Firestore.instance
                                  .collection('groups')
                                  .document(groupsDocs[index]['id'])
                                  .snapshots(),
                              builder: (ctx, groupDataSnapshot) {
                                if (groupDataSnapshot.connectionState ==
                                    ConnectionState.waiting)
                                  return Container(
                                    width: 0,
                                  );
                                if (groupDataSnapshot.error != null)
                                  return null;
                                try {
                                  int countUnSeen =
                                      groupDataSnapshot.data['msg_count'] -
                                          groupsDocs[index]['seen'];

                                  Timestamp datetimeINtimestamp =
                                      groupDataSnapshot.data['last_msg_time'];
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
                                  print(newDateTime);
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
                                                  .backgroundColor,
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
                                  print(err.toString());
                                  return Container(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        CircleAvatar(
                                          radius: 3,
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        CircleAvatar(
                                          radius: 3,
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        CircleAvatar(
                                          radius: 3,
                                        ),
                                      ],
                                    ),
                                  );
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
              childCount: groupsDocs.length + 1,
            ),
          ),
        ],
      ),
    );
  }
}
