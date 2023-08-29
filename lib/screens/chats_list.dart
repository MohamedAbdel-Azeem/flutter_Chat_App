import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/screens/add_chatroom.dart';

import 'chat.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() {
    return _ChatsListScreen();
  }
}

class _ChatsListScreen extends State<ChatsListScreen> {

  List<Map<String,dynamic>> userChatRooms = [];

  void _addChatRoom(){
    showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      context: context,
      builder: (ctx) => const AddChatRoomScreen(),
    );
  }

  Future<void> getChatRoom(String Id) async { // give chatRoom id returns a Map
    final chatRoomData = await FirebaseFirestore.instance
        .collection('chatRoom')
        .doc(Id)
        .get()
        .then((snapshot) => snapshot.data());
    userChatRooms.add(chatRoomData!);
  }

  Future<void> _loadChatRooms(User user) async {
    final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((snapshot) => snapshot.data());
    final userChats = userData!['chatRooms'];
    for (final chatRoomId in userChats){
        await getChatRoom(chatRoomId);
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats'),
        actions: [
          IconButton(
            onPressed: _addChatRoom,
            icon: Icon(Icons.add , color: Theme.of(context).colorScheme.primary,),
          ),
          IconButton(
            onPressed: (){
              FirebaseAuth.instance.signOut();
            },
            icon: Icon(Icons.exit_to_app , color: Theme.of(context).colorScheme.primary,),
          ),
        ],
      ),
      body: StreamBuilder(
        stream:
        FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots() ,
         builder: (ctx,snapshot){
            if (snapshot.hasError){
              return const Center(
                child: Text('An error occurred please try again later!'),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(backgroundColor: Colors.blue , color: Colors.white,),
              );
            }

            final userData = snapshot.data!.data()?['chatRooms'];
            if (userData == null || userData.isEmpty){
              return const Center(
                  child: Text(
                    'Add some ChatRooms!',
                  ));
            }

            return FutureBuilder(
              future: _loadChatRooms(user),
              builder: (ctx , futureSnapshot){
                if (futureSnapshot.hasError){
                  return const Center(
                    child: Text('An error occurred please try again later!'),
                  );
                }
                if (futureSnapshot.connectionState == ConnectionState.waiting){
                  return const Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.blue,
                      color: Colors.white,
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: userChatRooms.length,
                  itemBuilder: (ctx,index){
                    final chatRoom = userChatRooms[index];
                    return ListTile(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (ctx) => ChatScreen(
                                chatRoomId: userData[index],
                                chatRoomData: chatRoom)));
                      },
                      leading: CircleAvatar(
                        radius: 20,
                        child: ClipOval(
                          child: Image.network(
                            chatRoom['image_url'],
                            fit: BoxFit.cover,
                            height: double.infinity,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      title: Text(
                        chatRoom['roomName'],
                        style:
                        Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 17),
                      ),
                      subtitle: Text(chatRoom['lastMessage']),
                    );
                  },
                );
              },
            );

        },
      ),
    );
  }
}
