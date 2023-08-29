import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/widgets/new_messages.dart';
import 'package:flutter_chat_app/widgets/chat_messages.dart';

import 'chats_list.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen(
      {super.key, required this.chatRoomId, required this.chatRoomData});

  final String chatRoomId;
  final Map<String, dynamic> chatRoomData;


  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  late final Map<String, dynamic> chatRoomData;


  // void setUpPushNotifications() async{
  //   final fcm =  FirebaseMessaging.instance;
  //   await fcm.requestPermission();
  //   fcm.subscribeToTopic('chat');
  // }

  @override
  void initState() {
    chatRoomData = widget.chatRoomData;
    super.initState();
    //setUpPushNotifications()
  }

  @override
  Widget build(BuildContext context) {
    print(FirebaseAuth.instance.currentUser);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 20,
        title: ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(chatRoomData['image_url']),
            radius: 20,
          ),
          title: Text(chatRoomData['roomName']),
        ),
        actions: [
          IconButton(
              onPressed: (){}, //_showRoomDetails,
              icon: Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatMessages(
              chatRoomId: widget.chatRoomId,
            ),
          ),
          NewMessage(
            chatRoomId: widget.chatRoomId,
          ),
        ],
      ),
    );
  }
}