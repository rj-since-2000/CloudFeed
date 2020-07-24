import 'package:flutter/material.dart';
import 'package:chatapp2/screens/image_view.dart';

class MessageBubble extends StatefulWidget {
  MessageBubble(
    this.isGroup,
    this.message,
    this.isImage,
    this.userName,
    this.userImage,
    this.isMe,
    this.time,
    this.id,
    this.getMessageId, {
    this.key,
  });

  final Key key;
  final String message;
  final bool isGroup;
  final bool isImage;
  final String userName;
  final String userImage;
  final bool isMe;
  final String time;
  final String id;
  final Function getMessageId;

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  var selected = false;
  int messageLen;

  @override
  Widget build(BuildContext context) {
    messageLen = widget.message.length;
    return widget.userImage == ''
        ? Container(
            alignment: Alignment.center,
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: EdgeInsets.all(5),
            width: double.infinity,
            child: widget.isMe
                ? RichText(
                    text: TextSpan(
                        text: 'You',
                        style: TextStyle(
                            color: Theme.of(context).accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                        children: <TextSpan>[
                        TextSpan(
                            text: ' were added in the group',
                            style: TextStyle(color: Colors.white, fontSize: 14))
                      ]))
                : RichText(
                    text: TextSpan(
                        text: widget.message,
                        style: TextStyle(
                            color: Theme.of(context).accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                        children: <TextSpan>[
                        TextSpan(
                            text: ' joined the group',
                            style: TextStyle(color: Colors.white, fontSize: 14))
                      ])),
          )
        : InkWell(
            onTap: selected
                ? () {
                    setState(() {
                      if (widget.isMe &&
                          widget.message != 'This message was deleted')
                        widget.getMessageId(widget.id, false);
                      selected = false;
                    });
                  }
                : () {
                    FocusScopeNode currentFocus = FocusScope.of(context);

                    if (!currentFocus.hasPrimaryFocus) {
                      currentFocus.unfocus();
                    }
                  },
            onLongPress: () {
              setState(() {
                if (widget.isMe && widget.message != 'This message was deleted')
                  widget.getMessageId(widget.id, true);
                selected = true;
              });
            },
            child: Container(
              foregroundDecoration:
                  selected ? BoxDecoration(color: Colors.black45) : null,
              width: double.infinity,
              child: widget.isMe
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${widget.time.substring(0, 10)}\n          ${widget.time.substring(10, 15)}',
                            style: TextStyle(fontSize: 8),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                              bottomLeft: Radius.circular(6),
                              bottomRight: Radius.circular(0),
                            ),
                          ),

                          //width: message.length*8.toDouble()+32,
                          padding: EdgeInsets.all(5),
                          margin: EdgeInsets.only(
                              top: 4, bottom: 4, right: 10, left: 4),
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            child: widget.isImage
                                ? InkWell(
                                    onTap: () => Navigator.of(context)
                                        .pushNamed(ImageView.routeName,
                                            arguments: widget.message),
                                    child: Container(
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.6,
                                      width: MediaQuery.of(context).size.width *
                                          0.6,
                                      padding: EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(width: 1)),
                                      child: Hero(
                                        tag: widget.message,
                                        child: Image.network(
                                          widget.message,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  )
                                : widget.message == 'This message was deleted'
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                            Icon(
                                              Icons.not_interested,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              'This message was deleted',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 17,
                                                color: Colors.black,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ])
                                    : Text(
                                        widget.message,
                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.start,
                                      ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          // constraints: BoxConstraints(
                          //   minWidth: userName.length * 8.toDouble() + 32,
                          // ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).accentColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                              bottomLeft: Radius.circular(0),
                              bottomRight: Radius.circular(6),
                            ),
                          ),

                          //width: message.length*8.toDouble()+32,
                          padding: EdgeInsets.all(5),
                          margin: EdgeInsets.only(
                              top: 4, left: 10, right: 4, bottom: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (widget.isGroup)
                                Container(
                                  alignment: Alignment.topLeft,
                                  padding: EdgeInsets.only(bottom: 1),
                                  child: Text(
                                    widget.userName,
                                    style: TextStyle(
                                        color:
                                            Theme.of(context).backgroundColor,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ),
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                child: widget.isImage
                                    ? InkWell(
                                        onTap: () => Navigator.of(context)
                                            .pushNamed(ImageView.routeName,
                                                arguments: widget.message),
                                        child: Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.6,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.6,
                                          padding: EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(width: 1)),
                                          child: Hero(
                                            tag: widget.message,
                                            child: Image.network(
                                              widget.message,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      )
                                    : widget.message == 'This message was deleted'
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                            Icon(
                                              Icons.not_interested,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              'This message was deleted',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 17,
                                                color: Colors.black,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ])
                                    : Text(
                                        widget.message,
                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.start,
                                      ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${widget.time.substring(0, 10)}\n${widget.time.substring(10, 15)}',
                            style: TextStyle(fontSize: 8),
                          ),
                        ),
                      ],
                    ),
            ),
          );
  }
}
