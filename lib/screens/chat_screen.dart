import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';

final _firestore = Firestore.instance;
FirebaseUser loggedinUser;

class ChatScreen extends StatefulWidget {
  static String route = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String message;

  @override
  void initState() {
    super.initState();
    this.getCurrentUSer();
  }

  void getCurrentUSer() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedinUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                this._auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        this.message = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageTextController.clear();
                      try {
                        // message + loggedInUser.email
                        _firestore.collection('messages').add({'text': this.message, 'sender': loggedinUser.email});
                      } catch (e) {}
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final messages = snapshot.data.documents.reversed;
          List<MessageBubble> messageWidgets = [];
          for (var message in messages) {
            final messageText = message.data['text'];
            final messageSender = message.data['sender'];
            final messageWidget = MessageBubble(
              sender: messageSender,
              text: messageText,
              isMe: messageSender == loggedinUser.email,
            );
            messageWidgets.add(messageWidget);
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.all(10.0),
              children: messageWidgets,
            ),
          );
        }
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final String sender;
  final bool isMe;
  MessageBubble({this.sender, this.text, this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
          ),
          Material(
              elevation: 5.0,
              borderRadius: BorderRadius.only(
                  topLeft: isMe ? Radius.circular(30.0) : Radius.circular(0),
                  topRight: isMe ? Radius.circular(0) : Radius.circular(30.0),
                  bottomLeft: Radius.circular(30.0),
                  bottomRight: Radius.circular(30.0)),
              color: isMe ? Colors.lightBlueAccent : Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                child: Text(
                  text,
                  style: TextStyle(color: isMe ? Colors.white : Colors.lightBlueAccent),
                ),
              )),
        ],
      ),
    );
  }
}
