import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/models/chat_room_model.dart';
import 'package:flutter_chat_app/screens/auth.dart';
import 'package:flutter_chat_app/screens/chat.dart';
import 'package:flutter_chat_app/widgets/add_chatroom.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() {
    return _ChatsListScreenState();
  }
}

class _ChatsListScreenState extends State<ChatsListScreen> {

  void _addChatRoom() {
    showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      context: context,
      builder: (ctx) => const AddChatRoom(),
    );
  }

  Future<List<ChatRoom>> _loadChatRooms(List oldList) async {
    List<ChatRoom> result = [];
    for (final id in oldList) {
      final chatRoomData = await FirebaseFirestore.instance
          .collection('chatRoom')
          .doc(id)
          .get()
          .then((snapshot) => snapshot.data());
      final ChatRoom chatRoom = ChatRoom(
          id: id, time: chatRoomData!['lastMessageTime']);
      result.add(chatRoom);
    }
    result.sort((a, b) => b.time.compareTo(a.time));
    return result;
  }

  Future<Map<String, dynamic>> getChatRoom(String Id) async {
    final chatRoomData = await FirebaseFirestore.instance
        .collection('chatRoom')
        .doc(Id)
        .get()
        .then((snapshot) => snapshot.data());
    return chatRoomData!;
  }

  Future<Map<String, dynamic>> _loadChatRoomsAndChatRoomData(
      List oldList) async {
    List<ChatRoom> chatRooms = await _loadChatRooms(oldList);
    Map<String, dynamic> chatRoomData = {};

    for (final chatRoom in chatRooms) {
      final roomData = await getChatRoom(chatRoom.id);
      chatRoomData[chatRoom.id] = roomData;
    }

    return {'chatRooms': chatRooms, 'chatRoomData': chatRoomData};
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    print('USER:  $user');
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _addChatRoom,
            icon: const Icon(Icons.add),
            color: Theme
                .of(context)
                .colorScheme
                .primary,
          ),
          IconButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                },
              icon: Icon(
                Icons.exit_to_app,
                color: Theme
                    .of(context)
                    .colorScheme
                    .primary,
              )),
        ],
      ),
      body:
      StreamBuilder(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(user!.uid)
      .snapshots(),
  builder: (ctx, snapshot) {
    if (snapshot.hasError) {
      if (FirebaseAuth.instance.currentUser == null){
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => const AuthScreen()));

      }
      return const Center(
        child: Text('An error has Occured please try again later!'),
      );
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final userData = snapshot.data!.data();
    final userChatRoomsRaw = userData?['chatRooms'];

    if (userChatRoomsRaw == null || userChatRoomsRaw.isEmpty){
      return const Center(
          child: Text(
            'Add some ChatRooms!',
          ));
    }

    return FutureBuilder<List<ChatRoom>>(
      future: _loadChatRooms(userChatRoomsRaw),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          final chatRooms = snapshot.data!;
          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (ctx, index) {
              return FutureBuilder<Map<String, dynamic>>(
                future: getChatRoom(chatRooms[index].id),
                builder: (ctx, snapshot) {
                  if (snapshot.hasData) {
                    final chatRoom = snapshot.data!;
                    return ListTile(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (ctx) => ChatScreen(
                                chatRoomId: chatRooms[index].id,
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
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              );
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );

  },
),
    );
  }
}

// my version:
// StreamBuilder(
//   stream: FirebaseFirestore.instance
//       .collection('users')
//       .doc(user!.uid)
//       .snapshots(),
//   builder: (ctx, snapshot) {
//     if (snapshot.hasError) {
//       if (FirebaseAuth.instance.currentUser == null){
//         Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => const AuthScreen()));
//
//       }
//       return const Center(
//         child: Text('An error has Occured please try again later!'),
//       );
//     }
//     if (snapshot.connectionState == ConnectionState.waiting) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }
//
//     final userData = snapshot.data!.data();
//     final userChatRoomsRaw = userData?['chatRooms'];
//
//     if (userChatRoomsRaw == null || userChatRoomsRaw.isEmpty){
//       return const Center(
//           child: Text(
//             'Add some ChatRooms!',
//           ));
//     }
//
//     return FutureBuilder<List<ChatRoom>>(
//       future: _loadChatRooms(userChatRoomsRaw),
//       builder: (ctx, snapshot) {
//         if (snapshot.hasData) {
//           final chatRooms = snapshot.data!;
//           return ListView.builder(
//             itemCount: chatRooms.length,
//             itemBuilder: (ctx, index) {
//               return FutureBuilder<Map<String, dynamic>>(
//                 future: getChatRoom(chatRooms[index].id),
//                 builder: (ctx, snapshot) {
//                   if (snapshot.hasData) {
//                     final chatRoom = snapshot.data!;
//                     return ListTile(
//                       onTap: () {
//                         Navigator.of(context).push(MaterialPageRoute(
//                             builder: (ctx) => ChatScreen(
//                                 chatRoomId: chatRooms[index].id,
//                                 chatRoomData: chatRoom)));
//                       },
//                       leading: CircleAvatar(
//                         radius: 20,
//                         child: ClipOval(
//                           child: Image.network(
//                             chatRoom['image_url'],
//                             fit: BoxFit.cover,
//                             height: double.infinity,
//                             width: double.infinity,
//                           ),
//                         ),
//                       ),
//                       title: Text(
//                         chatRoom['roomName'],
//                         style:
//                         Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 17),
//                       ),
//                       subtitle: Text(chatRoom['lastMessage']),
//                     );
//                   } else {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//                 },
//               );
//             },
//           );
//         } else {
//           return const Center(child: CircularProgressIndicator());
//         }
//       },
//     );
//
//   },
// ),

// StreamBuilder(
//   stream: FirebaseFirestore.instance
//       .collection('users')
//       .doc(user!.uid)
//       .snapshots(),
//   builder: (ctx, snapshot) {
//     if (snapshot.hasError) {
//       if (FirebaseAuth.instance.currentUser == null){
//         Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => const AuthScreen()));
//
//       }
//       return const Center(
//         child: Text('An error has Occured please try again later!'),
//       );
//     }
//     if (snapshot.connectionState == ConnectionState.waiting) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }
//
//     final userData = snapshot.data!.data();
//     final userChatRoomsRaw = userData?['chatRooms'];
//
//     if (userChatRoomsRaw == null || userChatRoomsRaw.isEmpty){
//       return const Center(
//           child: Text(
//             'Add some ChatRooms!',
//           ));
//     }
//
//     return FutureBuilder<List<ChatRoom>>(
//       future: _loadChatRooms(userChatRoomsRaw),
//       builder: (ctx, snapshot) {
//         if (snapshot.hasData) {
//           final chatRooms = snapshot.data!;
//           return ListView.builder(
//             itemCount: chatRooms.length,
//             itemBuilder: (ctx, index) {
//               return FutureBuilder<Map<String, dynamic>>(
//                 future: getChatRoom(chatRooms[index].id),
//                 builder: (ctx, snapshot) {
//                   if (snapshot.hasData) {
//                     final chatRoom = snapshot.data!;
//                     return ListTile(
//                       onTap: () {
//                         Navigator.of(context).push(MaterialPageRoute(
//                             builder: (ctx) => ChatScreen(
//                                 chatRoomId: chatRooms[index].id,
//                                 chatRoomData: chatRoom)));
//                       },
//                       leading: CircleAvatar(
//                         radius: 20,
//                         child: ClipOval(
//                           child: Image.network(
//                             chatRoom['image_url'],
//                             fit: BoxFit.cover,
//                             height: double.infinity,
//                             width: double.infinity,
//                           ),
//                         ),
//                       ),
//                       title: Text(
//                         chatRoom['roomName'],
//                         style:
//                         Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 17),
//                       ),
//                       subtitle: Text(chatRoom['lastMessage']),
//                     );
//                   } else {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//                 },
//               );
//             },
//           );
//         } else {
//           return const Center(child: CircularProgressIndicator());
//         }
//       },
//     );
//
//   },
// ),


// ChatGPt Version:
// StreamBuilder(
// stream: FirebaseFirestore.instance
//     .collection('users')
//     .doc(user!.uid)
//     .snapshots(),
// builder: (ctx, snapshot) {
// if (snapshot.hasError) {
// // Handle error case
// }
// if (snapshot.connectionState == ConnectionState.waiting) {
// return const Center(child: CircularProgressIndicator());
// }
//
// final userData = snapshot.data!.data();
// final userChatRoomsRaw = userData?['chatRooms'];
//
// if (userChatRoomsRaw == null || userChatRoomsRaw.isEmpty) {
// return const Center(
// child: Text('Add some ChatRooms!'),
// );
// }
//
// return FutureBuilder<Map<String, dynamic>>(
// future: _loadChatRoomsAndChatRoomData(userChatRoomsRaw),
// builder: (ctx, snapshot) {
// if (snapshot.connectionState == ConnectionState.waiting) {
// return const Center(child: CircularProgressIndicator());
// }
// if (snapshot.hasError) {
// // Handle error case
// }
//
// final chatRoomDataMap = snapshot.data;
// final chatRooms = chatRoomDataMap!['chatRooms'];
// final chatRoomData = chatRoomDataMap['chatRoomData'];
//
// return ListView.builder(
// itemCount: chatRooms.length,
// itemBuilder: (ctx, index) {
// final chatRoom = chatRoomData[chatRooms[index].id];
// return ListTile(
// onTap: () {
// Navigator.of(context).push(MaterialPageRoute(
// builder: (ctx) =>
// ChatScreen(
// chatRoomId: chatRooms[index].id,
// chatRoomData: chatRoom,
// ),
// ));
// },
// leading: CircleAvatar(
// radius: 20,
// child: ClipOval(
// child: Image.network(
// chatRoom['image_url'],
// fit: BoxFit.cover,
// height: double.infinity,
// width: double.infinity,
// ),
// ),
// ),
// title: Text(
// chatRoom['roomName'],
// style: Theme
//     .of(context)
//     .textTheme
//     .bodyLarge!
//     .copyWith(fontSize: 17),
// ),
// subtitle: Text(chatRoom['lastMessage']),
// );
// },
// );
// },
// );
// },
// )