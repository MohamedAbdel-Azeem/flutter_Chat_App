import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/screens/my_profile.dart';
import 'package:flutter_chat_app/screens/splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddFriends extends ConsumerStatefulWidget {
  const AddFriends({super.key});

  @override
  ConsumerState<AddFriends> createState() {
    return _AddFriendsState();
  }
}

class _AddFriendsState extends ConsumerState<AddFriends> {
  var _profileImageUrl = '';
  


  void _showProfile(){
    showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      context: context,
      builder: (ctx) => MyProfile() ,
    );
  }

  Future<void> _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get()
        .then((snapshot) => snapshot.data());
    _profileImageUrl = userData!['image_url'];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return FutureBuilder(
      future: _loadProfileImage(),
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.hasError || snapshot.connectionState == ConnectionState.waiting){
            return const SplashScreen();
        }
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
                  onTap: () => _showProfile(),
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
                .doc(user!.uid)
                .snapshots(),
            builder: (ctx,snapshot){
                if (snapshot.hasError){
                  return const Center(
                    child: Text('Error Occurred, please try again later!'),
                  );
                }
                if (snapshot.hasData) {
                  final userData = snapshot.data!.data();
                  _profileImageUrl = userData!['image_url'];
                  if (snapshot.connectionState == ConnectionState.waiting){
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return const Center(
                    child: Text('data loaded successfully!'),
                  );
                }
                return const Center(child: CircularProgressIndicator(),);
            },
          ),
        );
      },
    );
  }
}
