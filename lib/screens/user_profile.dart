import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class UserProfile extends StatelessWidget {
  UserProfile({super.key, required this.userId});

  var _profileImageUrl = '';
  var _createdAt = '';
  var _username = '';
  var _emailAddress = '';
  Map<String,dynamic>? _myData;
  String userId;
  List? _friends;

  Future<void> _loadProfile() async {
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get()
        .then((snapshot) => snapshot.data());
    _username = userData!['username'];
    _emailAddress = userData['email'];
    _profileImageUrl = userData['image_url'];
    _createdAt = userData['createdAt'];

     _myData = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get().then((value) => value.data());
  }

  bool _isFriend(){
    _friends = _myData!['friends'];
    for (final friend in _friends!){
      if (friend['id'] == userId){
        return true;
      }
    }
    return false;
  }


  void _removeFriend() async{ // In the Case I removed a friend , the userId is the friend not me always!!
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get()
        .then((snapshot) => snapshot.data());
    final allOtherfriends = userData!['friends'];
    final otherFriends = [];
    final myId = FirebaseAuth.instance.currentUser!.uid;
    for (final friend in allOtherfriends!){
        if (friend['id'] != myId){
          otherFriends.add(friend);
        }
    }

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'friends': otherFriends,
    });

    final myFriends = [];
    final allMyFriends = _myData!['friends'];

    for (final friend in allMyFriends){
      if (friend['id'] != userId){
        myFriends.add(friend);
      }
    }

    await FirebaseFirestore.instance.collection('users').doc(myId).update({
      'friends': myFriends,
    });

  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadProfile(),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 75,
                backgroundImage: NetworkImage(_profileImageUrl),
              ),
              const SizedBox(
                height: 16,
              ),
              SizedBox(
                height: 175,
                child: Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'username: $_username',
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w500),
                            )),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Email: $_emailAddress',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Spacer(),
                        Text('This Profile was created on $_createdAt'),
                      ],
                    ),
                  ),
                ),
              ),
              if (userId == FirebaseAuth.instance.currentUser!.uid)
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    FirebaseAuth.instance.signOut();
                  },
                  child: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.red),
                  )),
              if (_isFriend())
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _removeFriend();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Remove Friend',
                      style: TextStyle(color: Colors.red),
                    )),
            ],
          ),
        );
      },
    );
  }
}
