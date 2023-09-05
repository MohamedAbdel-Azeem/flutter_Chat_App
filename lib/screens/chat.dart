import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/screens/user_profile.dart';
import 'package:flutter_chat_app/widgets/new_messages.dart';
import 'package:flutter_chat_app/widgets/chat_messages.dart';

import '../widgets/add_person.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.deviceUser, required this.otherUser, required this.otherUserId});

  final Map<String,dynamic> deviceUser;
  final Map<String,dynamic> otherUser;
  final String otherUserId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {


  // void setUpPushNotifications() async{
  //   final fcm =  FirebaseMessaging.instance;
  //   await fcm.requestPermission();
  //   fcm.subscribeToTopic('chat');
  // }

  @override
  void initState() {
    super.initState();
    //setUpPushNotifications();
  }

  void _showProfile(String id) {
    showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      context: context,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.8,
        child: Column(
          children: [
            const ScrollIndicator(),
            UserProfile(userId: id),
          ],
        ),
      ),
    );
  }

  String _generateChatId(){
      String username1 = widget.deviceUser['username'];
      String username2 = widget.otherUser['username'];
      if (username1.compareTo(username2) < 0){
            return '$username1:$username2';
      } else {
        return '$username2:$username1';
      }
  }

  @override
  Widget build(BuildContext context) {

    final chatId = _generateChatId();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUser['username']),
        actions: [
          Padding(
            padding: const EdgeInsets.all(9.0),
            child: GestureDetector(
              onTap: () => _showProfile(widget.otherUserId),
              child: CircleAvatar(
                backgroundImage: NetworkImage(widget.otherUser['image_url']),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatMessages(chatID: chatId,),
          ),
           NewMessage(chatId: chatId,),
        ],
      ),
    );
  }
}
