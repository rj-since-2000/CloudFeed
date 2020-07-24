import 'package:chatapp2/providers/messages_delete.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:chatapp2/screens/auth_screen.dart';
import 'package:chatapp2/screens/chat_screen.dart';
import 'package:chatapp2/screens/contacts_screen.dart';
import 'package:chatapp2/screens/edit_profile_screen.dart';
import 'package:chatapp2/screens/group_chat_screen.dart';
import 'package:chatapp2/screens/image_view.dart';
import 'package:chatapp2/screens/new_group_screen.dart';
import 'package:chatapp2/screens/splash_screen.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return ChangeNotifierProvider(
      create: (context) => MessagesDelete(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FlutterChat',
        theme: ThemeData.dark(),
        /*primarySwatch: Colors.pink,
            backgroundColor: Colors.pink,
            accentColor: Colors.deepPurple,
            accentColorBrightness: Brightness.dark,
            buttonTheme: ButtonTheme.of(context).copyWith(
              buttonColor: Colors.pink,
              textTheme: ButtonTextTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CustomPageTransitionBuilder(),
                TargetPlatform.iOS: CustomPageTransitionBuilder(),
              },
            )),*/
        home: StreamBuilder(
            stream: FirebaseAuth.instance.onAuthStateChanged,
            builder: (ctx, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting)
                return SplashScreen();
              if (userSnapshot.hasData) {
                return ContactsScreen();
              }
              return AuthScreen();
            }),
        routes: {
          '/main': (ctx) => ContactsScreen(),
          ChatScreen.routeName: (ctx) => ChatScreen(),
          ImageView.routeName: (ctx) => ImageView(),
          EditProfileScreen.routeName: (ctx) => EditProfileScreen(),
          NewGroupScreen.routeName: (ctx) => NewGroupScreen(),
          GroupChatScreen.routeName: (ctx) => GroupChatScreen(),
        },
      ),
    );
  }
}
