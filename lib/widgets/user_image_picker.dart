import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserImagePicker extends StatefulWidget {
  const UserImagePicker({super.key, required this.onPickImage});

  final void Function(File pickedImage) onPickImage;

  @override
  State<UserImagePicker> createState() {
    return _UserImagePickerState();
  }
}

class _UserImagePickerState extends State<UserImagePicker> {

  File? _pickedImageFile;

  void _takeImage() async{
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.camera, imageQuality: 50, maxWidth: 150,
    );
    if (pickedImage == null){
      return;
    }
    setState(() {
      _pickedImageFile = File(pickedImage.path);
    });
    widget.onPickImage(_pickedImageFile!);
  }

  void _pickImage() async{
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery, imageQuality: 50, maxWidth: 150,
    );
    if (pickedImage == null){
      return;
    }
    setState(() {
      _pickedImageFile = File(pickedImage.path);
    });
    widget.onPickImage(_pickedImageFile!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey,
          foregroundImage: _pickedImageFile != null ? FileImage(_pickedImageFile!) : null,
        ),
        const SizedBox(height: 8,),
        TextButton.icon(
          onPressed: _takeImage,
          icon: const Icon(Icons.camera_alt_sharp),
          label: Text('take image', style: TextStyle(
              color: Theme
                  .of(context)
                  .colorScheme.primary
          ),),
        ),
        TextButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image),
          label: Text('Add image', style: TextStyle(
              color: Theme
                  .of(context)
                  .colorScheme.primary
          ),),
        ),
      ],
    );
  }
}
