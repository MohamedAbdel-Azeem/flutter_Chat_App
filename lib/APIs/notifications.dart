import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../screens/chat.dart';

class NotificationApi {


  static void setupFirebaseMessaging(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle the message when the app is in the foreground
      _handleMessage(message, context);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle the message when the app is in the background or terminated
      _handleMessage(message, context);
    });
  }

  static void _handleMessage(RemoteMessage message, BuildContext context) async {
    final String chatID = message.data['chatId']; //format username1:username2
    final user = FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get().then((value) => value.data());

    final usernames = chatID.split(':');
    String otherUsername;
    if (usernames[0] == userData!['username']){
      otherUsername = usernames[1];
    } else {
      otherUsername = usernames[0];
    }

    final otherUser = await FirebaseFirestore.instance.collection('users').where('username' , isEqualTo: otherUsername).limit(1).get();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(deviceUser: userData, otherUser: otherUser.docs.first.data(), otherUserId: otherUser.docs.first.id,),
      ),
    );
  }



  static Future<void> sendPushNotification(String token,String body,String title , String chatId) async {
    try{
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=AAAA8GfPVRQ:APA91bGEnvIFEfAx9ihra6GVQfchU-I8S1hdE6oiDMs6TayLxDGlME2p2M8-3-CqFX3Kn970DDp_4hnSOLcJYtt4NGkeZWiUR4jGjAP9teyY4w2HhfE0Mnu8AC4tQx_HRpe5ZFywZmMw'
        },
        body: jsonEncode(
            <String,dynamic>{
              'priority': 'high',
              'data': <String,dynamic>{
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'status': 'done',
                'body': body,
                'title': title,
                'chatId': chatId,
              },
              "notification": <String,dynamic>{
                "title": title,
                "body": body,
              },
              "to": token,
            }
        ),
      );
      print('Notification sent');
    } catch (error){
      print("Error pushing notification");
    }
  }


}