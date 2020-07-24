import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chatapp2/widgets/chat/message_bubble.dart';

class GroupMessages extends StatelessWidget {
  GroupMessages(this.chatId, this.getMessageId);
  final chatId;
  final Function getMessageId;

  setAsRead() async {
    final user = await FirebaseAuth.instance.currentUser();
    final groupMsg =
        await Firestore.instance.collection('groups').document(chatId).get();
    final seen = groupMsg.data['msg_count'];
    await Firestore.instance
        .collection('users')
        .document(user.email)
        .collection('groups')
        .document(chatId)
        .updateData({'seen': seen});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseAuth.instance.currentUser(),
      builder: (ctx, futureSnapshot) {
        if (futureSnapshot.connectionState == ConnectionState.waiting) {
          return Container(height: 0);
        }
        return StreamBuilder(
          stream: Firestore.instance
              .collection('groups')
              .document(chatId)
              .collection('chat')
              .orderBy(
                'createdAt',
                descending: true,
              )
              .snapshots(),
          builder: (ctx, chatSnapshot) {
            if (chatSnapshot.connectionState == ConnectionState.waiting) {
              setAsRead();
              return Container(height: 0);
            }
            final chatDocs = chatSnapshot.data.documents;
            //Firestore.instance.collection('chats').document(chatId).collection('chat').document('dv').  getDocuments().whenComplete((){});
            return CupertinoScrollbar(
              child: ListView.builder(
                reverse: true,
                itemCount: chatDocs.length,
                itemBuilder: (ctx, index) => MessageBubble(
                  true,
                  chatDocs[index]['text'],
                  chatDocs[index]['isImage'],
                  chatDocs[index]['username'],
                  chatDocs[index]['userImage'],
                  chatDocs[index]['userImage'] == ''
                      ? chatDocs[index]['text'] == futureSnapshot.data.email
                      : chatDocs[index]['userId'] == futureSnapshot.data.uid,
                  chatDocs[index]['time'],
                  chatDocs[index]['id'],
                  getMessageId,
                  
                  key: ValueKey(chatDocs[index].documentID),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
