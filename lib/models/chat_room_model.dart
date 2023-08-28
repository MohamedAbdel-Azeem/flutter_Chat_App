import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom{

  const ChatRoom({required this.id , required this.time});

  final String id;
  final Timestamp time;


}