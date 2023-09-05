import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/APIs/notifications.dart';


class NewMessage extends StatefulWidget {
  const NewMessage({super.key, required this.chatId});

  final String chatId;

  @override
  State<NewMessage> createState() {
    return _NewMessageState();
  }
}

class _NewMessageState extends State<NewMessage> {

  final _messageController = TextEditingController();





  Future<String> _getID(String username) async{
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: username).get();
    final DocumentSnapshot document = querySnapshot.docs.first;
    return document.id;
  }


  Future<void> _updateFriends(String username , String otherUsername , Timestamp now) async{
      String myId = await _getID(username);
      String otherId = await _getID(otherUsername);

      final myData = await FirebaseFirestore.instance.collection('users').doc(myId).get().then((value) => value.data());
      final myFriends = myData!['friends'];
      final myUpdatedFriends = [];
      for (final friend in myFriends){
          if (friend['id'] == otherId){
            myUpdatedFriends.add({
              'id': otherId,
              'lastMessageTime': now,
            });
          }
          else{
            myUpdatedFriends.add(friend);
          }
      }

      final otherData = await FirebaseFirestore.instance.collection('users').doc(otherId).get().then((value) => value.data());
      final otherFriends = otherData!['friends'];
      final otherUpdatedFriends = [];
      for (final friend in otherFriends){
        if (friend['id'] == myId){
          otherUpdatedFriends.add({
            'id': myId,
            'lastMessageTime': now,
          });
        }
        else{
          otherUpdatedFriends.add(friend);
        }
      }


      FirebaseFirestore.instance.collection('users').doc(myId).update(
          {
            'friends': myUpdatedFriends,
          }
      );
      FirebaseFirestore.instance.collection('users').doc(otherId).update(
          {
            'friends' : otherUpdatedFriends,
          }
      );

  }

  void _submitMessage() async{
    final enteredMessage = _messageController.text;

    if (enteredMessage.trim().isEmpty){
      return;
    }

    FocusScope.of(context).unfocus();
    _messageController.clear();
    final user = FirebaseAuth.instance.currentUser!;
    final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    final messageTime = Timestamp.now();

    FirebaseFirestore.instance.collection('chat+${widget.chatId}').add({
      'text': enteredMessage,
      'createdAt': messageTime,
      'userId': user.uid,
      'username': userData.data()!['username'],
      'userImage': userData.data()!['image_url'],
    });

    final chatIds = widget.chatId.split(':');
    final receiverUsername = (chatIds[0] == user.uid)? chatIds[0] : chatIds[1];
    _updateFriends(chatIds[0],chatIds[1], messageTime);
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: receiverUsername).get();
    final receiverData = await FirebaseFirestore.instance.collection('users').doc(querySnapshot.docs.first.id).get().then((snapshot) => snapshot.data());
    final receiverToken = receiverData!['FCMToken'];
    NotificationApi.sendPushNotification(receiverToken, enteredMessage, userData.data()!['username'],widget.chatId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 1, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController ,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: false,
              enableSuggestions: true,
              decoration: const InputDecoration(labelText: 'Send a message...'),
            ),
          ),
          IconButton(onPressed: _submitMessage, icon: const Icon(Icons.send) , color: Theme.of(context).colorScheme.primary,)
        ],
      ),
    );
  }
}
