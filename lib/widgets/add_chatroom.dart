import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/widgets/user_image_picker.dart';
import 'package:uuid/uuid.dart';


final uuid = Uuid();

class AddChatRoom extends StatefulWidget {
  const AddChatRoom({super.key});

  @override
  State<AddChatRoom> createState() {
    return _AddChatRoomState();
  }
}

class _AddChatRoomState extends State<AddChatRoom> {
  final _nameOrIdController = TextEditingController();
  var _isCreating = false;
  File? _selectedImage;

  var _isConnecting = false;

  @override
  void dispose() {
    _nameOrIdController.dispose();
    super.dispose();
  }

  void _closeBottomSheet(){
    Navigator.pop(context);
  }

  void _submitButton() async{
    var chatRoomId;

    final enteredNameorId = _nameOrIdController.text;
    if (enteredNameorId.trim().length < 3) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter valid data at least 3 characters length'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ));
      return;
    }
    if (_isCreating && _selectedImage == null){
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter ChatRoom Image'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ));
      return;
    }

    try{
      setState(() {
        _isConnecting = true;
      });
      final user = FirebaseAuth.instance.currentUser!;
      final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (_isCreating){ // Creating a Room name and generating its ID

        chatRoomId = uuid.v4();
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('chatroom_images')
            .child('$chatRoomId.jpg');
        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        final creator = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .then((snapshot) => snapshot.data());

        final newChatRoom = await FirebaseFirestore.instance.collection('chatRoom').add({
          'createdAt': Timestamp.now(),
          'roomName': enteredNameorId,
          'image_url': imageUrl,
          'currentUsers': [user.uid],
          'lastMessage': '$enteredNameorId was Created by ${creator!['username']}',
          'lastMessageTime' : DateTime.now(),
        });
        chatRoomId = newChatRoom.id;
      } else {
        chatRoomId = enteredNameorId;
        FirebaseFirestore.instance.collection('chatRoom').doc(chatRoomId).update({
          'currentUsers': FieldValue.arrayUnion([user.uid]),
        });
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'chatRooms': FieldValue.arrayUnion([chatRoomId]),
      });
      _closeBottomSheet();
      _nameOrIdController.clear();
      print(chatRoomId);
    } catch (error){
      setState(() {
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
        child: Column(
          children: [
            if (_isCreating)
              UserImagePicker(onPickImage: (ImageFile){
                _selectedImage = ImageFile;
              }),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCreating = true;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 45),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: (_isCreating)
                              ? [
                                  Theme.of(context).colorScheme.primary,
                                  Colors.blueAccent
                                ]
                              : [Colors.white, Colors.white]),
                    ),
                    child: const Text('Create a Room'),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCreating = false;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: (!_isCreating)
                                ? [
                                    Theme.of(context).colorScheme.primary,
                                    Colors.blueAccent
                                  ]
                                : [Colors.white, Colors.white])),
                    child: const Text('Join a Room'),
                  ),
                ),
              ],
            ),
            if (_isCreating)
              TextField(
                controller: _nameOrIdController,
                decoration: const InputDecoration(labelText: 'ChatRoom name: '),
              ),
            if (!_isCreating)
              TextField(
                controller: _nameOrIdController,
                decoration: const InputDecoration(labelText: 'ChatRoom ID: '),
              ),
            const SizedBox(
              height: 16,
            ),
            (_isConnecting)? const CircularProgressIndicator() :
            ElevatedButton(
              onPressed: _submitButton,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary),
              child: Text(
                (_isCreating) ? 'Create' : 'Join',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      );
  }
}
