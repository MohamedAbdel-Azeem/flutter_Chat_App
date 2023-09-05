import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/screens/user_profile.dart';
import 'package:flutter_chat_app/screens/splash.dart';
import 'package:flutter_chat_app/widgets/add_person.dart';
import 'package:flutter_chat_app/widgets/side_drawer.dart';

class Friends extends StatefulWidget {
  const Friends({super.key});

  @override
  State<Friends> createState() {
    return _FriendsState();
  }
}

class _FriendsState extends State<Friends> {
  var _profileImageUrl = '';

  final _searchController = TextEditingController();

  Map<String, dynamic>? userData;
  String? userId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get()
        .then((snapshot) => snapshot.data());
    _profileImageUrl = userData!['image_url'];
  }

  void _rejectRequest(String id) async{ // remove from my sent and remove from his pending
    await FirebaseFirestore.instance.collection('users').doc(userId).update(
        {
          'pendingRequests': FieldValue.arrayRemove([id]),
        });
    await FirebaseFirestore.instance.collection('users').doc(id).update(
        {
          'sentRequests': FieldValue.arrayRemove([userId]),
        });
  }

  void _acceptRequest(String id) async{ // I will use rejectRequest to remove it then add it to my friends and the other user
      _rejectRequest(id);
      await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {
            'friends': FieldValue.arrayUnion([{
              'id': id ,
              'lastMessageTime': DateTime.now(),
            }]),
          });
      await FirebaseFirestore.instance.collection('users').doc(id).update(
          {
            'friends': FieldValue.arrayUnion([{
              'id': userId ,
              'lastMessageTime': DateTime.now(),
            }]),
          });
  }

  Widget personTile(String personId , bool _isSent) {
    return FutureBuilder(
      future:
          FirebaseFirestore.instance.collection('users').doc(personId).get(),
      builder: (BuildContext context,
          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Error occurred!'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        final personData = snapshot.data;
        return ListTile(
          onTap: () => _showProfile(personId),
          leading: CircleAvatar(
            backgroundImage: NetworkImage(personData!['image_url']),
          ),
          title: Text(personData['username']),
          trailing: (_isSent)? null : SizedBox(
            width: 96,
            child: Row(
              children: [
                IconButton(onPressed: () => _acceptRequest(personId), icon: Icon(Icons.check , color: Theme.of(context).colorScheme.primary,)),
                IconButton(onPressed: () => _rejectRequest(personId), icon: Icon(Icons.close , color: Theme.of(context).colorScheme.primary ,)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddPersonPage() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: 0.6, // Set this value to the desired height factor
            child: Column(
              children: [
                const ScrollIndicator(),
                AddPerson(
                  userData: userData,
                  userId: userId,
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    userId = user!.uid;

    return FutureBuilder(
      future: _loadProfileImage(),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.hasError ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        var pendingRequests = userData!['pendingRequests'];
        var sentRequests = userData!['sentRequests'];

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Add Friends',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              textAlign: TextAlign.center,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(9.0),
                child: GestureDetector(
                  onTap: () => _showProfile(userId!),
                  child: (_profileImageUrl == '')
                      ? Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : CircleAvatar(
                          backgroundImage: NetworkImage(_profileImageUrl),
                        ),
                ),
              ),
            ],
          ),
          body: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (ctx, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Error Occurred, please try again later!'),
                );
              }
              if (snapshot.hasData) {
                final userData = snapshot.data!.data();
                pendingRequests = userData!['pendingRequests'];
                sentRequests = userData['sentRequests'];
                _profileImageUrl = userData['image_url'];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.75),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: TextButton.icon(
                            icon: Icon(
                              Icons.add,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            label: Text(
                              'Add Friend',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary),
                            ),
                            onPressed: _showAddPersonPage,
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        ExpansionTile(
                          leading: const Icon(Icons.hourglass_bottom_outlined),
                          title: Row(
                            children: [
                              const Text('Pending friend requests'),
                              const SizedBox(
                                width: 12,
                              ),
                              if (!pendingRequests.isEmpty)
                                const Icon(
                                  Icons.add_alert,
                                  color: Colors.deepOrange,
                                )
                            ],
                          ),
                          //trailing: (pendingRequests.isEmpty)? null : const Icon(Icons.add_alert , color: Colors.deepOrange,),
                          children: <Widget>[
                            // Check if there are any pending friend requests
                            pendingRequests.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text('No pending friend requests'),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      height: 260,
                                      child: ListView.builder(
                                        itemCount: pendingRequests.length,
                                        itemBuilder: (ctx, index) {
                                          return personTile(
                                              pendingRequests[index] , false);
                                        },
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                        ExpansionTile(
                          leading: const Icon(Icons.rocket_launch_sharp),
                          title: const Text('Sent friend requests'),
                          children: <Widget>[
                            // Check if there are any sent friend requests
                            sentRequests.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text('No Sent friend requests'),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      height: 260,
                                      child: ListView.builder(
                                        itemCount: sentRequests.length,
                                        itemBuilder: (ctx, index) {
                                          return personTile(
                                              sentRequests[index] , true);
                                        },
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ],
                    )
                  ],
                );
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
          drawer: SideDrawer(),
        );
      },
    );
  }
}
