import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class RoomDetails extends StatefulWidget {
  const RoomDetails(
      {super.key, required this.chatRoomDetails, required this.chatRoomId});

  final Map<String, dynamic> chatRoomDetails;
  final String chatRoomId;

  @override
  State<RoomDetails> createState() => _RoomDetailsState();
}

class _RoomDetailsState extends State<RoomDetails> {
  Future<Map<String, dynamic>> _getMemberById(String userId) async {
    final member = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get()
        .then((snapshot) => snapshot.data());
    return member!;
  }

  @override
  Widget build(BuildContext context) {
    final Timestamp timeStamp = widget.chatRoomDetails['createdAt'];
    final formattedDate = DateFormat('EEE, MMM d, yyyy – h:mm a').format(timeStamp.toDate());
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 45,
              child: ClipOval(
                child: Image.network(
                  widget.chatRoomDetails['image_url'],
                  fit: BoxFit.cover,
                  height: double.infinity,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              widget.chatRoomDetails['roomName'],
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(
              height: 12,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.chatRoomId));
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Copied to clipboard'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ));
                  print(widget.chatRoomId);
                },
                child: Row(
                  children: [
                    Text('Room invitation link: ${widget.chatRoomId}',
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(width: 8,),
                    Icon(
                      Icons.copy,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),

              ),
            ),
            const SizedBox(
              height: 12,
            ),
            Text('Created At: $formattedDate'),
            const SizedBox(
              height: 12,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Room Members',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.chatRoomDetails['currentUsers'].length,
                itemBuilder: (ctx, index) {
                  return FutureBuilder<Map<String, dynamic>>(
                    future: _getMemberById(
                        widget.chatRoomDetails['currentUsers'][index]),
                    builder: (ctx, snapshot) {
                      if (snapshot.hasData) {
                        final member = snapshot.data!;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(member['image_url']),
                          ),
                          title: Text(member['username']),
                        );
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
