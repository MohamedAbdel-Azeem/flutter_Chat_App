import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class MyProfile extends StatelessWidget {
  MyProfile({super.key});

  var _profileImageUrl = '';
  var _createdAt = '';
  var _username = '';
  var _emailAddress = '';

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get()
        .then((snapshot) => snapshot.data());
    _username = userData!['username'];
    _emailAddress = userData['email'];
    _profileImageUrl = userData['image_url'];
    _createdAt = userData['createdAt'];
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
              const SizedBox(
                height: 16,
              ),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    FirebaseAuth.instance.signOut();
                  },
                  child: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.red),
                  )),
            ],
          ),
        );
      },
    );
  }
}
