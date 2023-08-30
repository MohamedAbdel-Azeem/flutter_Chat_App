import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/screens/chat.dart';

class SideDrawer extends StatelessWidget {
  SideDrawer({super.key});

  User? user;

  List<Map<String, dynamic>> userFriends = [];

  Future<void> _getFriendsDetails() async {
    userFriends = [];
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get()
        .then((snapshot) => snapshot.data());
    final userFriendsIds = userData!['friends'];
    for (final id in userFriendsIds) {
      final friend = await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .get()
          .then((snapshot) => snapshot.data());
      userFriends.add(friend!);
    }
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
        if (userFriends.length == 0){
          return const Center(child: Text('Add some new friends'),);
        }
        return ListView.builder(
          itemCount: userFriends.length,
          itemBuilder: (ctx, index) {
            return ListTile(
              contentPadding: const EdgeInsets.fromLTRB(25, -20, 20, 10),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    user = FirebaseAuth.instance.currentUser;

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
          Expanded(child: _getChats(),),
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
}
