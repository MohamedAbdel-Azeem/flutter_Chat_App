import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat_app/widgets/user_image_picker.dart';
import 'package:intl/intl.dart';


final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }

}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  
  var _enteredEmailOrUsername = '';
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredUsermame = '';
  File? _selectedImage;
  String? _fCMToken;

  var _isAuthenticating = false;
  var _isObscured = true;

  Future<String?> _getEmail(String username) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference usersCollection = firestore.collection('users');

    QuerySnapshot querySnapshot = await usersCollection.where('username', isEqualTo: username).get();
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.get('email');
    } else {
      return '';
    }
  }


  Future<bool> _isUniqueUsername(String enteredUsername) async{
      final db = FirebaseFirestore.instance;
      final usersCollection = db.collection('users');
      QuerySnapshot querySnapshot = await usersCollection.where('username', isEqualTo: enteredUsername).get();
      return querySnapshot.docs.isEmpty;
  }


  void _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    if (!_isLogin && _selectedImage == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must add an image!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    _formKey.currentState!.save();

    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        
        if (!_enteredEmailOrUsername.contains('@')){
            _enteredEmailOrUsername = (await _getEmail(_enteredEmailOrUsername))!;
            if (_enteredEmailOrUsername == ''){
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Username not found in the database!'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
              setState(() {
                _isAuthenticating = false;
              });
              return;
            }
        }

        final userCredentials = await _firebase.signInWithEmailAndPassword(
          email: _enteredEmailOrUsername,
          password: _enteredPassword,
        );
      } else {
        // signing up / creating new users
        if (! await _isUniqueUsername(_enteredUsermame)){
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Username is already used!'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          setState(() {
            _isAuthenticating = false;
          });
          return;
        }
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
        await _firebase.signOut();
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');
        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();
        final formatter = DateFormat('yyyy-MM-dd');
        final date = DateTime.now();
        final String creationDate = formatter.format(date);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid).set({
          'username': _enteredUsermame,
          'email': _enteredEmail,
          'image_url': imageUrl,
          'createdAt': creationDate,
          'sentRequests': [],
          'pendingRequests': [],
          'friends': [],
          'FCMToken': await FirebaseMessaging.instance.getToken(),
        });
        FocusScope.of(context).unfocus();
        setState(() {
          _isLogin = true;
          _isAuthenticating = false;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account Created'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Authentication failed'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() {
        _isAuthenticating = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                    top: 30, bottom: 20, left: 20, right: 20),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin)
                            UserImagePicker(
                              onPickImage: (imageFile) {
                                _selectedImage = imageFile;
                              },
                            ),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: (_isLogin)? 'Email Address or Username' :'Email Address',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty || (!_isLogin && !value.contains('@'))) {
                                return 'please enter a valid email address.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              if (_isLogin){
                                _enteredEmailOrUsername = value!;
                              }
                              else {
                                _enteredEmail = value!;
                              }
                            },
                          ),
                        if (!_isLogin)
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Username',
                            ),
                            autocorrect: false,
                            enableSuggestions: false,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty || value.trim().length < 4 || value.contains('@')) {
                                return 'please enter a valid username at least 4 characters excluding @.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredUsermame = value!;
                            },
                          ),
                          TextFormField(
                            decoration: InputDecoration(
                              suffixIcon: IconButton(onPressed: (){
                                setState(() {
                                  _isObscured = !_isObscured;
                                });
                              }, icon: Icon(_isObscured? Icons.visibility_off : Icons.visibility)),
                              labelText: 'Password',
                            ),
                            obscureText: _isObscured,
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return 'Password must be at least 6 characters long.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredPassword = value!;
                            },
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          if (_isAuthenticating)
                            const CircularProgressIndicator(),
                          if (!_isAuthenticating)
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer),
                              child: Text(_isLogin ? 'Login' : 'Sign-Up'),
                            ),
                          if (!_isAuthenticating)
                            TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                                child: Text(_isLogin
                                    ? 'Create an account!'
                                    : 'I already have an account! Login')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
