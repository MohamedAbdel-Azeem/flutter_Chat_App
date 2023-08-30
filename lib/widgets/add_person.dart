import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddPerson extends StatefulWidget{
   const AddPerson({super.key, required this.userData, required this.userId});

   final userData;
   final userId;

  @override
  State<AddPerson> createState() => _AddPersonState();
}

class _AddPersonState extends State<AddPerson> {
  final _searchController = TextEditingController();

   void _showToast(String message) {
     FocusScope.of(context).unfocus();
     Fluttertoast.showToast(
       msg: message,
       toastLength: Toast.LENGTH_SHORT,
       gravity: ToastGravity.BOTTOM,
       timeInSecForIosWeb: 2,
       backgroundColor: Colors.grey,
       textColor: Colors.white,
       fontSize: 16.0,
     );
   }

   void _sendFriendRequest(Map<String,dynamic> userData ,  String userId ) async {
     final username = _searchController.text;
     final db = FirebaseFirestore.instance;
     final usersCollection = db.collection('users');
     QuerySnapshot querySnapshot =
     await usersCollection.where('username', isEqualTo: username).get();
     if (querySnapshot.docs.isEmpty) {
       _showToast("Check the entered username again!");
       return;
     } else {
       final targetUser = querySnapshot.docs.first;
       final targetUserData = targetUser.data() as Map<String, dynamic>;
       if (targetUserData['username'] == userData['username']) {
         _showToast("That's you :)");
         return;
       } if (userData['pendingRequests'].contains(targetUser.id)){
         _showToast('Just accept the friend request he sent!');
         return;
       } if (userData['friends'].contains(targetUser.id)){
         _showToast('He is already your friend!');
         return;
       } if (userData['sentRequests'].contains(targetUser.id)){
         _showToast('You already sent him a friend request');
         return;
       }
       else {
         final doc = querySnapshot.docs.first;
         final docRef = doc.reference;

         await docRef.update({
           'pendingRequests': FieldValue.arrayUnion([userId]),
         });

         await FirebaseFirestore.instance
             .collection('users')
             .doc(userId)
             .update({
           'sentRequests': FieldValue.arrayUnion([doc.id]),
         });
         _showToast("Friend request sent!");
         FocusScope.of(context).unfocus();
         _searchController.clear();
       }
     }
     Navigator.pop(context);
   }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(38.0),
          child: TextField(
            enableSuggestions: false,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Add friends by username',
            ),
          ),
        ),
        const SizedBox(height: 8,),
        TextButton.icon(onPressed: (){
          _sendFriendRequest(widget.userData,widget.userId);
        }, icon: const Icon(Icons.search), label: const Text('Add')),
      ],
    );
  }
}

class ScrollIndicator extends StatelessWidget {
  const ScrollIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[500],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}