import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/screens/chat.dart';

class SideDrawer extends StatelessWidget {
  SideDrawer({super.key});

  User? user;

  List<Map<String, dynamic>> userFriends = [];

  void sortListByTimestamp(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final timestampA = a['lastMessageTime'] as Timestamp; // Replace 'Timestamp' with the actual type of your timestamp field
      final timestampB = b['lastMessageTime'] as Timestamp; // Replace 'Timestamp' with the actual type of your timestamp field

      // Compare the timestamps by converting them to DateTime objects
      final dateTimeA = timestampA.toDate();
      final dateTimeB = timestampB.toDate();

      return dateTimeB.compareTo(dateTimeA); // Sort in descending order
    });
  }


  Future<void> _getFriendsDetails() async {
    userFriends = [];
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get()
        .then((snapshot) => snapshot.data());
    final userFriendsDetails = userData!['friends']; // returns a Map with 2 keys : friendID and the lastMessageTime
    for (final f in userFriendsDetails) {
      final friend = await FirebaseFirestore.instance
          .collection('users')
          .doc(f['id'])
          .get()
          .then((snapshot) => snapshot.data());
      friend!['lastMessageTime'] = f['lastMessageTime'];
      userFriends.add(friend);
    }
    sortListByTimestamp(userFriends);
    print(userFriends[0]['lastMessageTime']);
  }

  Widget _getChats() {
    return FutureBuilder(
      future: _getFriendsDetails(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (userFriends.isEmpty){
          return  Center(child: Text('Add some new friends', style: Theme.of(context).textTheme.titleMedium,),);
        }
        return MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: ListView.separated(
            separatorBuilder: (context, index){
              return const Divider();
            },
            itemCount: userFriends.length,
            itemBuilder: (ctx, index) {
              return ListTile(
                onTap: () async {
                  final userData = await FirebaseFirestore.instance.collection(
                      'users').doc(user!.uid).get().then((snapshot) =>
                      snapshot.data());

                  final otherUserQuerySnapshot = await FirebaseFirestore.instance.collection(
                      'users')
                      .where(
                      'username', isEqualTo: userFriends[index]['username'])
                      .limit(1)
                      .get();

                  final otherUserId = otherUserQuerySnapshot.docs[0].id;

                  Navigator.of(context).push(MaterialPageRoute(builder: (ctx) =>
                      ChatScreen(deviceUser: userData!,
                        otherUser: userFriends[index],
                        otherUserId:otherUserId,)));
                },
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(userFriends[index]['image_url']),
                ),
                title: Text(
                  userFriends[index]['username'],
                  textAlign: TextAlign.justify,
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleLarge,
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    user = FirebaseAuth.instance.currentUser;

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
      builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting){
            return const Center(child: Text(''),);
          }
          if (snapshot.hasError){
            return const Center(child: Text('Error building Stream'),);
          }
        return Drawer(
          width: 250,
          child: Column(
            children: [
              SizedBox(
                height: 170,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 0),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 70),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Theme
                            .of(context)
                            .colorScheme
                            .primary,
                        Theme
                            .of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.8)
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_sharp,
                        size: 52,
                        color: Theme
                            .of(context)
                            .colorScheme
                            .onPrimary,
                      ),
                      const SizedBox(
                        width: 18,
                      ),
                      Text(
                        'Friends',
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleLarge!
                            .copyWith(
                            color: Theme
                                .of(context)
                                .colorScheme
                                .onPrimary,
                            fontSize: 30),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12,),
              Expanded(child: _getChats()),
              // ListView.builder(
              //   itemCount:,
              //   itemBuilder: (ctx, index) {
              //
              //   },
              // ),
            ],
          ),
        );
      }
    );
  }
}
