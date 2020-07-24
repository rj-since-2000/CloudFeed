import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chatapp2/widgets/chat/message_bubble.dart';

class Messages extends StatelessWidget {
  Messages(this.chatId, this.email, this.getMessageId);
  final chatId;
  final email;
  final Function getMessageId;

  setAsRead() async {
    final userEmail = await FirebaseAuth.instance.currentUser();
    final email = userEmail.email.toString();
    final emailLength = email.length;
    final modifiedEmail = email.substring(0, emailLength - 4);
    Firestore.instance.collection('chats').document(chatId).updateData({
      '$modifiedEmail': 0,
    });
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
              .collection('chats')
              .document(chatId)
              .collection('chat')
              .orderBy(
                'createdAt',
                descending: true,
              )
              .snapshots(),
          builder: (ctx, chatSnapshot) {
            if (chatSnapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 0,
              );
            }
            setAsRead();
            final chatDocs = chatSnapshot.data.documents;
            //Firestore.instance.collection('chats').document(chatId).collection('chat').document('dv').  getDocuments().whenComplete((){});
            return CupertinoScrollbar(
              child: ListView.builder(
                  reverse: true,
                  itemCount: chatDocs.length,
                  itemBuilder: (ctx, index) {
                    return MessageBubble(
                      false,
                      chatDocs[index]['text'],
                      chatDocs[index]['isImage'],
                      chatDocs[index]['username'],
                      chatDocs[index]['userImage'],
                      chatDocs[index]['userId'] == futureSnapshot.data.uid,
                      chatDocs[index]['time'],
                      chatDocs[index]['id'],
                      getMessageId,
            
                      key: ValueKey(chatDocs[index].documentID),
                    );
                  }),
            );
          },
        );
      },
    );
  }
}
